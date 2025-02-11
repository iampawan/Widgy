import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WidgetStateManager {
  static const String _storageKey = "widget_states";

  static Future<void> saveWidgetState(
      String widgetName, Map<String, dynamic> properties) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_storageKey);
    final Map<String, dynamic> stateMap =
        existingData != null ? jsonDecode(existingData) : {};

    stateMap[widgetName] = properties;
    await prefs.setString(_storageKey, jsonEncode(stateMap));
  }

  static Future<Map<String, dynamic>> loadWidgetState(String widgetName) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_storageKey);

    if (existingData != null) {
      final stateMap = jsonDecode(existingData) as Map<String, dynamic>;
      return stateMap[widgetName] ?? {};
    }

    return {};
  }
}
