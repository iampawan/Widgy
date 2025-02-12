import 'package:widgy/src/widget_property.dart';

export 'widget_metadata_stub.dart' if (dart.library.ui) 'widget_metadata.dart';

abstract class WidgetMetaDataBase {
  String get name;
  List<WidgetProperty> get properties;

  Map<String, dynamic> toJson();
  String toDartCode();

  // Add a generic get<T> method to retrieve properties safely
  T get<T>(String propertyName);
}
