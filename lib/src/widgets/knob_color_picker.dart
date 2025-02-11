import 'package:flutter/material.dart';
import 'package:widgy/src/actions.dart';

class KnobColorPicker extends StatelessWidget {
  final String name;
  final String label;
  final String propertyKey;
  final Color defaultValue;

  const KnobColorPicker({
    super.key,
    required this.name,
    required this.label,
    required this.propertyKey,
    required this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        GestureDetector(
          onTap: () {
            final newColor =
                defaultValue == Colors.blue ? Colors.red : Colors.blue;
            UpdatePropertyAction(
                name: name, propertyKey: propertyKey, value: newColor);
          },
          child: Container(width: 24, height: 24, color: defaultValue),
        ),
      ],
    );
  }
}
