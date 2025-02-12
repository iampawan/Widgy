import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration, InstanceCreationExpression;
import 'package:analyzer/dart/ast/visitor.dart' show RecursiveAstVisitor;
import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart';
import 'package:widgy/src/widget_metadata/widget_metadata_import.dart';

const String _widgetRegistryFile = "lib/widgy_registry.dart";
void main(List<String> arguments) async {
  stdout.writeln("🚀 Welcome to Widgy CLI Tool\n");
  final parser = ArgParser()
    ..addFlag('discover',
        abbr: 'd',
        help: 'Auto-detect widgets and register them',
        negatable: false)
    ..addOption('exclude',
        abbr: 'e',
        help: 'Comma-separated list of directories to exclude from discovery')
    ..addOption('log', abbr: 'l', help: 'File path to log discovered widgets')
    ..addFlag('generate-preview',
        abbr: 'g',
        help: 'Automatically generate previews for discovered widgets',
        negatable: false)
    ..addFlag('graph',
        abbr: 'G', help: 'Generate widget dependency graph', negatable: false)
    ..addFlag('help',
        abbr: 'h', help: 'Display this help message', negatable: false)
    ..addFlag('version',
        abbr: 'v', help: 'Display the version', negatable: false);

  ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    stdout.writeln('Error parsing arguments: $e');
    stdout.writeln(parser.usage);
    exit(64);
  }
  // Help command.
  if (argResults['help'] as bool) {
    stdout.writeln('Widgy CLI Tool');
    stdout.writeln('Usage: dart run widgy [options]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  // Version command.
  if (argResults['version'] as bool) {
    stdout.writeln('Widgy version 0.0.2');
    exit(0);
  }

  // Dependency graph generation.
  if (argResults['graph'] as bool) {
    stdout.writeln('Inside graph generation');
    // Optionally, you could add an extra flag to include Flutter widgets.
    final includeFlutter = arguments.contains('--include-flutter');
    stdout.writeln('Generating widget dependency graph...');
    await generateDependencyGraph(includeFlutter: includeFlutter);
    stdout.writeln('Dependency graph generated.');
    exit(0);
  }

  if (argResults.wasParsed('discover')) {
    final excludeDirs = (argResults['exclude'] as String?)?.split(',') ?? [];
    final logFilePath = argResults['log'] as String?;
    final generatePreview = argResults.wasParsed('generate-preview');

    stdout.writeln("🔍 Discovering widgets in project...");
    final discoveredWidgets = await discoverWidgets(excludeDirs: excludeDirs);
    stdout.writeln("✅ Widget discovery complete.");

    _loadRegistry();

    if (logFilePath != null) {
      final logFile = File(logFilePath);
      logFile.writeAsStringSync(discoveredWidgets.join('\n'));
      stdout.writeln("📄 Widget discovery log saved to $logFilePath");
    }

    if (generatePreview) {
      stdout.writeln("🖼 Generating previews for discovered widgets...");
      await generatePreviews(
          widgets: discoveredWidgets.map((w) => w.name).toList());
      stdout.writeln("✅ Widget preview generation complete.");
    }
  } else {
    stdout.writeln(
        "Usage: widgy [--discover] [--exclude=dir1,dir2] [--log=logfile.txt] [--generate-preview]");
  }
}

Future<List<WidgetMetaDataBase>> discoverWidgets(
    {List<String> excludeDirs = const []}) async {
  final List<WidgetMetaData> discoveredWidgets = [];

  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
    stdout.writeln(
        "⚠️ Widget discovery is only supported on desktop environments.");
    return [];
  }

  final projectRoot = Directory.current.path;
  final libDirectory = Directory("$projectRoot/lib");

  if (!libDirectory.existsSync()) {
    stdout.writeln(
        "❌ Error: The `lib/` directory does not exist in this project.");
    return [];
  }

  final dartFiles =
      libDirectory.listSync(recursive: true).whereType<File>().where((file) {
    return file.path.endsWith(".dart");
  }).toList();

  for (var file in dartFiles) {
    final filePath = file.absolute.path;

    if (!filePath.startsWith(libDirectory.absolute.path)) continue;
    if (filePath
        .contains(Platform.environment['FLUTTER_ROOT'] ?? "/flutter/")) {
      continue;
    }

    try {
      final content = file.readAsStringSync();
      final matches =
          RegExp(r'class (\w+) extends (StatelessWidget|StatefulWidget)')
              .allMatches(content);

      for (var match in matches) {
        final widgetName = match.group(1);
        if (widgetName != null) {
          discoveredWidgets
              .add(WidgetMetaData(name: widgetName, properties: []));
        }
      }
    } catch (e) {
      stdout.writeln("⚠️ Error reading file: $filePath, skipping. Error: $e");
    }
  }

  if (discoveredWidgets.isEmpty) {
    stdout.writeln("✅ No new widgets detected.");
    return [];
  }

  // Assume we now have a list of widget names:
  final widgetNames = discoveredWidgets.map((w) => w.name).toList();

  // Add a "Select All" option at the top.
  widgetNames.insert(0, "[Select All]");

  // Invoke the custom multi-select.
  final selectedIndices = await customMultiSelect(
    prompt: "Select widgets to register:",
    options: widgetNames,
  );

  List<WidgetMetaDataBase> selectedWidgets = [];
  if (selectedIndices.contains(0)) {
    // If "[Select All]" is selected, then select all discovered widgets.
    selectedWidgets = discoveredWidgets;
  } else {
    // Otherwise, subtract 1 from each index because of the inserted "[Select All]" option.
    for (final index in selectedIndices) {
      // Guard against any index issues.
      if (index > 0 && index - 1 < discoveredWidgets.length) {
        selectedWidgets.add(discoveredWidgets[index - 1]);
      }
    }
  }

  // Print a summary.
  console.resetColorAttributes();
  print("\nSelected Widgets:");
  for (var widget in selectedWidgets) {
    print("✔ ${widget.name}");
  }
  await _saveRegistry(selectedWidgets);

  return selectedWidgets;
}

Future<void> _saveRegistry(List<WidgetMetaDataBase> selectedWidgets) async {
  final file = File(_widgetRegistryFile);
  // Use a LinkedHashMap to preserve insertion order (or sort later).
  final Map<String, String> existingWidgets = {};

  if (await file.exists()) {
    final content = await file.readAsString();
    int index = 0;
    // Loop to scan the content for each occurrence of "WidgetMetaData("
    while (true) {
      final startIndex = content.indexOf('WidgetMetaData(', index);
      if (startIndex == -1) break; // No more registrations found.

      int parenCount = 0;
      int currentIndex = startIndex;
      // Flag to note if we've started counting (in case there is extra noise)
      bool started = false;
      // Walk character by character to balance parentheses.
      while (currentIndex < content.length) {
        final char = content[currentIndex];
        if (char == '(') {
          parenCount++;
          started = true;
        } else if (char == ')') {
          parenCount--;
          // Once we've balanced out the opening parentheses, break.
          if (parenCount == 0 && started) {
            break;
          }
        }
        currentIndex++;
      }
      // Extract the registration block (include the closing parenthesis).
      final registrationBlock = content.substring(startIndex, currentIndex + 1);
      // Use regex to extract the widget name (assumes it appears as: name: "SomeName")
      final nameMatch =
          RegExp(r'name\s*:\s*"([^"]+)"').firstMatch(registrationBlock);
      if (nameMatch != null) {
        final widgetName = nameMatch.group(1)!;
        existingWidgets[widgetName] = registrationBlock;
      }
      // Move index past this registration.
      index = currentIndex + 1;
    }
  }

  // For each widget discovered externally, add it if not already registered.
  for (final widget in selectedWidgets) {
    if (!existingWidgets.containsKey(widget.name)) {
      final widgetRegistration = 'WidgetMetaData(name: "${widget.name}", '
          'widgetBuilder: (context) => ${widget.name}(), properties: [])';
      existingWidgets[widget.name] = widgetRegistration;
    }
  }

  // Optionally sort the registrations by widget name.
  final sortedKeys = existingWidgets.keys.toList()..sort();
  final formattedRegistrations =
      sortedKeys.map((key) => existingWidgets[key]!).join(',\n    ');

  final updatedContent = '''
// GENERATED FILE: Modify manually as per your need and import required files. Run `dart run widgy --discover` to update.

import 'package:widgy/widgy.dart';

void registerWidgets() {
  Widgy.registerMultipleWidgets([
    $formattedRegistrations
  ]);
}
''';

  await file.writeAsString(updatedContent, flush: true);
  stdout.writeln(
      "✅ Selected widgets registered and updated in $_widgetRegistryFile.");
}

Future<void> _loadRegistry() async {
  final file = File(_widgetRegistryFile);
  if (!file.existsSync()) return;
  stdout.writeln("📂 Loading registered widgets from $_widgetRegistryFile");
  Process.runSync("dart", ["run", _widgetRegistryFile]);
}

Future<void> generatePreviews({required List<String> widgets}) async {
  final previewDir = Directory("widgy_previews");
  if (!previewDir.existsSync()) {
    previewDir.createSync(recursive: true);
  }

  for (var widget in widgets) {
    final file = File("${previewDir.path}/$widget.txt");
    file.writeAsStringSync("Preview generated for: $widget");
  }
  stdout.writeln("✅ Previews generated in widgy_previews/");
}

/// Generates a dependency graph for widget classes found in `lib/`
/// using robust AST parsing. Writes both a DOT file and an HTML file for visualization.
Future<void> generateDependencyGraph({bool includeFlutter = false}) async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: lib directory not found.');
    return;
  }

  stdout.writeln('Generating widget dependency graph...');

  // Map of widget class name -> set of widget names instantiated in its build method.
  final Map<String, Set<String>> dependencyGraph = {};

  // Map of widget class name -> usage count.
  final Map<String, int> usageCounts = {};

  // List all Dart files under lib/
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
  stdout.writeln('Processing ${dartFiles.length} Dart files...');
  // Process each Dart file.
  for (final file in dartFiles) {
    try {
      final content = await file.readAsString();
      final parseResult =
          parseString(content: content, throwIfDiagnostics: false);
      final unit = parseResult.unit;

      // Iterate through declarations in the compilation unit.
      for (final declaration in unit.declarations) {
        if (declaration is ClassDeclaration) {
          final className = declaration.name.lexeme;
          bool isWidget = false;

          // Check if the class extends StatelessWidget or StatefulWidget.
          if (declaration.extendsClause != null) {
            final superFull = declaration.extendsClause!.superclass.toSource();
            // Extract the simple name by splitting on dot.
            final superclassName = superFull.split('.').last;
            if (superclassName == 'StatelessWidget' ||
                superclassName == 'StatefulWidget') {
              isWidget = true;
            }
          }
          if (!isWidget) continue;

          dependencyGraph.putIfAbsent(className, () => <String>{});

          // Look for the build method in the class members.
          for (final member in declaration.members) {
            if (member is MethodDeclaration && member.name.lexeme == 'build') {
              // Use our visitor to collect instantiated widget names.
              final visitor = _WidgetInstantiationVisitor();
              member.visitChildren(visitor);

              // Process found widget instantiations.
              for (final instantiatedWidget in visitor.instantiatedWidgets) {
                // Optionally filter out common Flutter widgets.
                if (!includeFlutter) {
                  const flutterWidgets = {
                    'Scaffold',
                    'AppBar',
                    'Text',
                    'Column',
                    'Row',
                    'Container',
                    'Padding',
                    'ListView',
                  };
                  if (flutterWidgets.contains(instantiatedWidget)) continue;
                }
                // Avoid self-references.
                if (instantiatedWidget == className) continue;
                dependencyGraph[className]!.add(instantiatedWidget);
                // Increment usage count for this widget.
                usageCounts[instantiatedWidget] =
                    (usageCounts[instantiatedWidget] ?? 0) + 1;
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      // Log the error and skip this file.
      print('Error processing file ${file.path}: $e');
      continue;
    }
  }
  // Define a set of node names to ignore (these represent tokens, layout keywords, etc.)
  const ignoreNodes = {
    // 'all',
    // 'only',
    // 'shrink',
    // 'symmetric',
    'lg',
    'md',
    'xl4',
    'xl3',
    'xl2',
    'xl5',
    // 'Size',
    // 'ValueKey',
    // 'Key'
  };

  // Print usage stats.
  stdout.writeln('Widget Usage Counts:');
  usageCounts.forEach((widget, count) {
    stdout.writeln('  $widget: $count');
  });

  final dotBuffer = StringBuffer();

// Add some graph attributes for a cleaner look.
  dotBuffer.writeln('digraph WidgetGraph {');
  dotBuffer.writeln(
      '  graph [fontsize=10, rankdir=LR, splines=true, nodesep=0.8, ranksep=0.6];');
// Style nodes with a box shape, light fill color, and a common font.
  dotBuffer.writeln(
      '  node [shape=box, style=filled, color="#CCCCFF", fontname="Helvetica"];');
// Style edges with a dark gray color.
  dotBuffer.writeln('  edge [color="#333333", arrowhead=normal];');

  // Create nodes with usage count labels.
  // We’ll include nodes that are either parents or children.
  final allNodes = <String>{};
  dependencyGraph.forEach((widget, children) {
    allNodes.add(widget);
    allNodes.addAll(children);
  });
  for (final node in allNodes) {
    // Get usage count if available.
    final count = usageCounts[node] ?? 0;
    // Set label to include usage count.
    dotBuffer.writeln('  "$node" [label="$node\\n(count: $count)"];');
  }

// Build the graph edges, filtering out nodes that are in the ignore list.
  dependencyGraph.forEach((widget, children) {
    // If the parent widget is in the ignore list, skip it entirely.
    if (ignoreNodes.contains(widget)) return;

    for (final child in children) {
      // Skip child nodes that are in the ignore list.
      if (ignoreNodes.contains(child)) continue;
      dotBuffer.writeln('  "$widget" -> "$child";');
    }
  });

  dotBuffer.writeln('}');

  final dotFile = File('widget_dependency_graph.dot');
  await dotFile.writeAsString(dotBuffer.toString());
  print('DOT file generated: ${dotFile.path}');

  // Generate an HTML file using Viz.js for interactive visualization.
  final htmlContent = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Widget Dependency Graph</title>
    <script src="https://unpkg.com/viz.js@2.1.2/viz.js"></script>
    <script src="https://unpkg.com/viz.js@2.1.2/full.render.js"></script>
    <style>
      body { font-family: sans-serif; text-align: center; }
      #graph { margin: 20px auto; }
    </style>
  </head>
  <body>
    <h1>Widget Dependency Graph</h1>
    <div id="graph"></div>
    <script>
      var dot = \`${dotBuffer.toString()}\`;
      var viz = new Viz();
      viz.renderSVGElement(dot)
         .then(function(element) {
           document.getElementById('graph').appendChild(element);
         })
         .catch(error => {
           console.error(error);
         });
    </script>
  </body>
</html>
''';

  final htmlFile = File('widget_dependency_graph.html');
  await htmlFile.writeAsString(htmlContent);
  print('HTML visualization generated: ${htmlFile.path}');
}

/// A recursive AST visitor that collects the names of instantiated widgets.
class _WidgetInstantiationVisitor extends RecursiveAstVisitor<void> {
  final Set<String> instantiatedWidgets = {};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Use toSource() on the type node and extract the simple name.
    final fullTypeName = node.constructorName.type.toSource();
    final simpleTypeName = fullTypeName.split('.').last;
    instantiatedWidgets.add(simpleTypeName);
    super.visitInstanceCreationExpression(node);
  }
}

final console = Console();

/// Displays an interactive multi-select list with checkboxes in the terminal.
/// [prompt] is displayed at the top, and [options] is the list of choices.
/// Returns a list of indices corresponding to the selected options.
Future<List<int>> customMultiSelect({
  required String prompt,
  required List<String> options,
}) async {
  // Track the selection state.
  final selected = List<bool>.filled(options.length, false);
  int currentIndex = 0;

  // Prepare header content.
  final headerLines = prompt.split('\n');
  const instructions =
      'Use ↑/↓ to move, space to toggle selection, and Enter to finish.\n'
      'Press "q" or Ctrl+C to exit.';
  final headerContent = [...headerLines, instructions];
  final headerRowCount = headerContent.length;

  // Determine how many rows are available for displaying options.
  int availableRows = console.windowHeight - headerRowCount;
  if (availableRows < 1) availableRows = 1;
  int windowOffset = 0; // Index of the first option in the visible region

  // Draw the header (prompt and instructions) at the top.
  void drawHeader() {
    for (int i = 0; i < headerRowCount; i++) {
      console.cursorPosition = Coordinate(i, 0);
      console.eraseLine();
      console.write(headerContent[i]);
    }
  }

  // Draw only the visible portion of the options.
  void drawOptions() {
    int endIndex = windowOffset + availableRows;
    if (endIndex > options.length) endIndex = options.length;

    // Redraw the options region.
    for (int i = windowOffset; i < endIndex; i++) {
      final row = headerRowCount + (i - windowOffset);
      console.cursorPosition = Coordinate(row, 0);
      console.eraseLine();

      // Build the checkbox and option text.
      final checkbox = selected[i] ? '[x] ' : '[ ] ';
      final text = '$checkbox${options[i]}';

      // Highlight the currently focused option.
      if (i == currentIndex) {
        console.setForegroundColor(ConsoleColor.black);
        console.setBackgroundColor(ConsoleColor.white);
      } else {
        console.setForegroundColor(ConsoleColor.green);
        console.setBackgroundColor(ConsoleColor.black);
      }
      console.write(text);
      console.resetColorAttributes();
    }

    // Clear any remaining lines if the visible region isn't completely filled.
    for (int i = endIndex - windowOffset; i < availableRows; i++) {
      final row = headerRowCount + i;
      console.cursorPosition = Coordinate(row, 0);
      console.eraseLine();
    }
  }

  // Initial drawing.
  console.clearScreen();
  drawHeader();
  drawOptions();

  // Main input loop.
  while (true) {
    final key = console.readKey();

    // Check for exit conditions: Ctrl+C or 'q' key.
    if (key.controlChar == ControlCharacter.ctrlC ||
        key.char.toLowerCase() == 'q') {
      console.clearScreen();
      console.resetColorAttributes();
      print('Exiting...');
      exit(0);
    }

    if (key.controlChar == ControlCharacter.arrowUp) {
      currentIndex = currentIndex - 1;
      if (currentIndex < 0) currentIndex = options.length - 1;
    } else if (key.controlChar == ControlCharacter.arrowDown) {
      currentIndex = (currentIndex + 1) % options.length;
    } else if (key.char == ' ') {
      // Toggle the selection for the current option.
      selected[currentIndex] = !selected[currentIndex];
    } else if (key.controlChar == ControlCharacter.enter) {
      break;
    }

    // Adjust the window so that currentIndex is always visible.
    if (currentIndex < windowOffset) {
      windowOffset = currentIndex;
    } else if (currentIndex >= windowOffset + availableRows) {
      windowOffset = currentIndex - availableRows + 1;
    }
    drawOptions();
  }

  // Build and return the list of selected indices.
  final selectedIndices = <int>[];
  for (int i = 0; i < selected.length; i++) {
    if (selected[i]) selectedIndices.add(i);
  }
  return selectedIndices;
}
