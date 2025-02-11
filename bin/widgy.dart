import 'dart:io';

import 'package:args/args.dart';
import 'package:interact/interact.dart';
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

    print("🔍 Discovering widgets in project...");
    final discoveredWidgets = await discoverWidgets(excludeDirs: excludeDirs);
    print("✅ Widget discovery complete.");

    _loadRegistry();

    if (logFilePath != null) {
      final logFile = File(logFilePath);
      logFile.writeAsStringSync(discoveredWidgets.join('\n'));
      print("📄 Widget discovery log saved to $logFilePath");
    }

    if (generatePreview) {
      print("🖼 Generating previews for discovered widgets...");
      await generatePreviews(
          widgets: discoveredWidgets.map((w) => w.name).toList());
      print("✅ Widget preview generation complete.");
    }
  } else {
    print(
        "Usage: widgy [--discover] [--exclude=dir1,dir2] [--log=logfile.txt] [--generate-preview]");
  }
}

Future<List<WidgetMetaDataBase>> discoverWidgets(
    {List<String> excludeDirs = const []}) async {
  final List<WidgetMetaData> discoveredWidgets = [];

  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
    print("⚠️ Widget discovery is only supported on desktop environments.");
    return [];
  }

  final projectRoot = Directory.current.path;
  final libDirectory = Directory("$projectRoot/lib");

  if (!libDirectory.existsSync()) {
    print("❌ Error: The `lib/` directory does not exist in this project.");
    return [];
  }

  final dartFiles =
      libDirectory.listSync(recursive: true).whereType<File>().where((file) {
    return file.path.endsWith(".dart");
  }).toList();

  for (var file in dartFiles) {
    final filePath = file.absolute.path;

    if (!filePath.startsWith(libDirectory.absolute.path)) continue;
    if (filePath.contains(Platform.environment['FLUTTER_ROOT'] ?? "/flutter/"))
      continue;

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
      print("⚠️ Error reading file: $filePath, skipping. Error: $e");
    }
  }

  if (discoveredWidgets.isEmpty) {
    print("✅ No new widgets detected.");
    return [];
  }

  // Generate checkbox selection using interact package
  List<String> widgetNames = discoveredWidgets.map((w) => w.name).toList();
  widgetNames.insert(0, "[Select All]");

  // Ensure `defaults` has the correct length
  final defaultSelection = List.generate(widgetNames.length, (index) => false);

  final selected = MultiSelect(
    prompt: "Select widgets to register:",
    options: widgetNames,
    defaults: defaultSelection,
  ).interact();

  List<WidgetMetaDataBase> selectedWidgets = [];

  if (selected.isEmpty) {
    print("⚠️ No widgets selected. Operation cancelled.");
    return [];
  }

  if (selected.contains(0)) {
    // Select All option
    selectedWidgets = discoveredWidgets;
  } else {
    selectedWidgets = selected.map((i) => discoveredWidgets[i - 1]).toList();
  }

  print("\n📝 Summary of Widget Selection:");
  for (var widget in selectedWidgets) {
    print("✔ Registered: ${widget.name}");
  }
  _saveRegistry(selectedWidgets);
  final skippedWidgets =
      discoveredWidgets.where((w) => !selectedWidgets.contains(w)).toList();
  for (var widget in skippedWidgets) {
    print("❌ Skipped: ${widget.name}");
  }

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
  print("✅ Selected widgets registered and updated in $_widgetRegistryFile.");
}

Future<void> _loadRegistry() async {
  final file = File(_widgetRegistryFile);
  if (!file.existsSync()) return;
  print("📂 Loading registered widgets from $_widgetRegistryFile");
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
  print("✅ Previews generated in widgy_previews/");
}
