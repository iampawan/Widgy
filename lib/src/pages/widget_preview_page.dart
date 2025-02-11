import 'package:auto_route/auto_route.dart';
import 'package:dataflow/dataflow.dart';
import 'package:flutter/material.dart';
import 'package:widgy/src/actions.dart';
import 'package:widgy/src/data_store.dart';
import 'package:widgy/src/widgets/knobs_panel.dart';

import '../widget_metadata/widget_metadata.dart';

@RoutePage()
class WidgetPreviewPage extends StatelessWidget {
  final String name;

  const WidgetPreviewPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(name)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataSync<WidgetCatalogDataStore>(
                actions: const {UpdatePropertyAction},
                builder: (context, store, hasData) {
                  final widgetMetaData = store.registeredWidgets.firstWhere(
                    (entry) => entry.name == name,
                  ) as WidgetMetaData;
                  return Column(children: [
                    Expanded(
                      child: Center(
                        child: widgetMetaData.widgetBuilder(widgetMetaData),
                      ),
                    ),
                    KnobsPanel(
                      properties: widgetMetaData.properties,
                      widgetName: widgetMetaData.name,
                    )
                  ]);
                }),
          ),
        ));
  }
}
