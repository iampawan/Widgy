import 'package:dataflow/dataflow.dart' show DataAction;
import 'package:widgy/src/widget_metadata/widget_metadata_import.dart';

import 'data_store.dart';

class RegisterWidgetAction extends DataAction<WidgetCatalogDataStore> {
  final WidgetMetaDataBase metadata;

  RegisterWidgetAction({required this.metadata});

  @override
  execute() async {
    store.registeredWidgets.add(metadata);
  }
}

class UpdatePropertyAction extends DataAction<WidgetCatalogDataStore> {
  final String name;
  final String propertyKey;
  final dynamic value;

  UpdatePropertyAction({
    required this.name,
    required this.propertyKey,
    required this.value,
  });

  @override
  execute() async {
    final widgetMetaData = store.registeredWidgets.firstWhere(
      (entry) => entry.name == name,
    );

    final property = widgetMetaData.properties.firstWhere(
      (prop) => prop.name == propertyKey,
    );

    property.value = value;
  }
}
