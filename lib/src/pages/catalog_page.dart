import 'package:auto_route/auto_route.dart';
import 'package:dataflow/dataflow.dart';
import 'package:flutter/material.dart';
import 'package:widgy/src/routes.gr.dart';

import '../actions.dart';
import '../data_store.dart';

@RoutePage()
class WidgetCatalogPage extends StatelessWidget {
  const WidgetCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widgy Catalog')),
      body: DataSync<WidgetCatalogDataStore>(
        builder: (context, store, hasData) {
          return ListView.builder(
            itemCount: store.registeredWidgets.length,
            itemBuilder: (context, index) {
              final entry = store.registeredWidgets[index];
              final name = entry.name;
              return ListTile(
                title: Text(name),
                onTap: () {
                  context.router.push(
                    WidgetPreviewRoute(name: name),
                  );
                },
              );
            },
          );
        },
        actions: const {RegisterWidgetAction},
      ),
    );
  }
}
