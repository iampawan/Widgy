import 'package:widgy/src/widget_metadata/widget_metadata_import.dart';
import 'package:widgy/src/widget_property.dart';

class WidgetMetaData extends WidgetMetaDataBase {
  @override
  final String name;
  @override
  final List<WidgetProperty> properties;

  WidgetMetaData({
    required this.name,
    required this.properties,
  });

  @override
  String toDartCode() {
    return "WidgetMetaData(name: \"$name\", properties: [])";
  }

  factory WidgetMetaData.fromJson(Map<String, dynamic> json) {
    return WidgetMetaData(
      name: json['name'],
      properties: [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  @override
  T get<T>(String propertyName) {
    return properties
        .firstWhere(
          (prop) => prop.name == propertyName,
        )
        .value as T;
  }
}
