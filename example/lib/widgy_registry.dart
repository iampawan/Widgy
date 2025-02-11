// GENERATED FILE: Modify manually as per your need and import required files. Run `dart run widgy --discover` to update.

import 'package:widgy/widgy.dart';

void registerWidgets() {
  Widgy.registerMultipleWidgets([
    WidgetMetaData(name: "Dummy", widgetBuilder: (context) => Dummy(), properties: []),
    WidgetMetaData(
        name: "MyApp",
        widgetBuilder: (context) => MyApp("Hahhaha"),
        properties: []),
    WidgetMetaData(
        name: "MyHomePage",
        widgetBuilder: (context) => MyHomePage(),
        properties: [])
  ]);
}
