import 'package:flutter/material.dart';
import 'package:widgy/src/actions.dart';

class KnobSlider extends StatelessWidget {
  final String name;
  final String label;
  final String propertyKey;
  final double defaultValue;
  final double min;
  final double max;

  const KnobSlider({
    required this.name,
    required this.label,
    required this.propertyKey,
    required this.defaultValue,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label),
        Slider(
          value: defaultValue,
          min: min,
          max: max,
          onChanged: (value) {
            UpdatePropertyAction(
                name: name, propertyKey: propertyKey, value: value);
          },
        ),
      ],
    );
  }
}
