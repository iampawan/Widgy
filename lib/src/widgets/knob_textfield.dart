import 'package:flutter/material.dart';
import 'package:widgy/src/actions.dart';

class KnobTextField extends StatelessWidget {
  final String name;
  final String label;
  final String propertyKey;
  final String defaultValue;

  const KnobTextField({
    required this.name,
    required this.label,
    required this.propertyKey,
    required this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      onChanged: (value) {
        UpdatePropertyAction(
            name: name, propertyKey: propertyKey, value: value);
      },
    );
  }
}
