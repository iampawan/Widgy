import 'package:flutter/material.dart';
import 'package:widgy/src/actions.dart';
import 'package:widgy/src/widget_property.dart';

class KnobsPanel extends StatelessWidget {
  final String widgetName;
  final List<WidgetProperty> properties;

  const KnobsPanel(
      {super.key, required this.widgetName, required this.properties});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: properties.map((property) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildControl(property),
        );
      }).toList(),
    );
  }

  Widget _buildControl(WidgetProperty property) {
    switch (property.type) {
      case WidgetPropertyType.string:
        return TextField(
          decoration: InputDecoration(labelText: property.name),
          onChanged: (value) {
            UpdatePropertyAction(
              name: widgetName,
              propertyKey: property.name,
              value: value,
            );
          },
        );
      case WidgetPropertyType.color:
        return ElevatedButton(
          child: const Text("Pick Color"),
          onPressed: () {
            UpdatePropertyAction(
              name: widgetName,
              propertyKey: property.name,
              value: Colors.red,
            );
          },
        );
      case WidgetPropertyType.double:
      case WidgetPropertyType.int:
        return Slider(
          value: (property.value as num).toDouble(),
          min: 0,
          max: 100,
          onChanged: (value) {
            UpdatePropertyAction(
              name: widgetName,
              propertyKey: property.name,
              value: property.type == WidgetPropertyType.int
                  ? value.toInt()
                  : value,
            );
          },
        );
      case WidgetPropertyType.bool:
        return Switch(
          value: property.value as bool,
          onChanged: (value) {
            UpdatePropertyAction(
              name: widgetName,
              propertyKey: property.name,
              value: value,
            );
          },
        );
    }
  }
}
