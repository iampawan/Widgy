import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart';
import 'package:widgy/src/widget_metadata/widget_metadata_import.dart';

const String _widgetRegistryFile = "lib/widgy_registry.dart";
void main(List<String> arguments) async {
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
        negatable: false);

  final argResults = parser.parse(arguments);

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
      '(Mouse scroll is not supported)';
  final headerContent = [...headerLines, instructions];
  final headerRowCount = headerContent.length;

  // Determine how many rows are available for displaying options.
  int availableRows = console.windowHeight - headerRowCount;
  if (availableRows < 1) availableRows = 1;
  int windowOffset = 0; // The index of the first option in the visible region

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
        console.setForegroundColor(ConsoleColor.white);
        console.setBackgroundColor(ConsoleColor.brightBlack);
      }
      console.write(text);
      console.resetColorAttributes();
    }
    // Clear any remaining lines if the visible region is not completely filled.
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

    if (key.controlChar == ControlCharacter.arrowUp) {
      // Wrap-around if necessary.
      currentIndex = currentIndex - 1;
      if (currentIndex < 0) currentIndex = options.length - 1;
    } else if (key.controlChar == ControlCharacter.arrowDown) {
      currentIndex = (currentIndex + 1) % options.length;
    } else if (key.char == ' ') {
      // Toggle selection for the current option.
      selected[currentIndex] = !selected[currentIndex];
    } else if (key.controlChar == ControlCharacter.enter) {
      break;
    }

    // Adjust windowOffset so that currentIndex is always visible.
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
