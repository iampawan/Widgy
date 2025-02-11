import 'package:flutter/widgets.dart';
import 'package:widgy/src/widget_metadata/widget_metadata_import.dart';
import 'package:widgy/src/widget_property.dart';

typedef WidgetBuilderWithProps = Widget Function(WidgetMetaData meta);

class WidgetMetaData implements WidgetMetaDataBase {
  @override
  final String name;
  final WidgetBuilderWithProps widgetBuilder;
  @override
  final List<WidgetProperty> properties;

  WidgetMetaData({
    required this.name,
    required this.widgetBuilder,
    this.properties = const [],
  });

  @override
  String toDartCode() {
    return "WidgetMetaData(name: \"$name\", widgetBuilder: (meta) => $name(), properties: [])";
  }

  factory WidgetMetaData.fromJson(Map<String, dynamic> json) {
    return WidgetMetaData(
      name: json['name'],
      widgetBuilder: (meta) =>
          throw UnimplementedError("Cannot instantiate widget from JSON."),
      properties: [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  // Helper method to get a property value safely with an optional default fallback
  @override
  T get<T>(String propertyName, {required T defaultValue}) {
    final property = properties.firstWhere(
      (prop) => prop.name == propertyName,
      orElse: () => WidgetProperty(
        name: propertyName,
        type: _inferPropertyType(defaultValue),
        value: defaultValue,
      ),
    );
    if (property.value is T) {
      return property.value as T;
    } else {
      throw ArgumentError("Incorrect type for property '$propertyName'");
    }
  }

  // Infers the WidgetPropertyType based on the default value type
  static WidgetPropertyType _inferPropertyType(dynamic value) {
    if (value is String) return WidgetPropertyType.string;
    if (value is int) return WidgetPropertyType.int;
    if (value is double) return WidgetPropertyType.double;
    if (value is bool) return WidgetPropertyType.bool;
    if (value is Color) return WidgetPropertyType.color;
    return WidgetPropertyType.string;
  }
}
