enum WidgetPropertyType { string, color, double, int, bool }

class WidgetProperty<T> {
  final String name;
  final WidgetPropertyType type;
  T value;
  final String description;

  WidgetProperty({
    required this.name,
    required this.type,
    required this.value,
    this.description = "",
  });
}
