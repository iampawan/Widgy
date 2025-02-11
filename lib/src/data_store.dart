import 'package:dataflow/dataflow.dart';
import 'package:widgy/src/widget_metadata/widget_metadata_import.dart';

class WidgetCatalogDataStore extends DataStore {
  // Define your state variables here
  // For example, a list to hold registered widgets:
  final List<WidgetMetaDataBase> registeredWidgets = [];
}
