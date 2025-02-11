import 'package:dataflow/dataflow.dart';
import 'package:flutter/cupertino.dart';
import 'package:widgy/src/actions.dart';
import 'package:widgy/src/data_store.dart';
import 'package:widgy/src/widget_metadata/widget_metadata.dart';
import 'package:widgy/src/widget_property.dart';

class Widgy {
  /// Initialize the data flow for the Widgy library.
  static init() {
    DataFlow.init(WidgetCatalogDataStore());
  }

  /// Register a widget with the Widgy library.
  static registerWidget({
    required String name,
    required Widget Function(WidgetMetaData) builder,
    List<WidgetProperty> properties = const [],
  }) {
    RegisterWidgetAction(
      metadata: WidgetMetaData(
        name: name,
        widgetBuilder: builder,
        properties: properties,
      ),
    );
  }

  /// Register multiple widgets with the Widgy library.
  static void registerMultipleWidgets(List<WidgetMetaData> widgets) {
    for (var widget in widgets) {
      RegisterWidgetAction(metadata: widget);
    }
  }
}
