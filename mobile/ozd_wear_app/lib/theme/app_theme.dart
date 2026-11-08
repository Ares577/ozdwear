import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData data([Map<String, dynamic>? config]) {
    Color parse(String key, Color fallback) {
      final value = '${config?[key] ?? ''}'.replaceFirst('#', '');
      final parsed = int.tryParse(value.length == 6 ? 'ff$value' : value, radix: 16);
      return parsed == null ? fallback : Color(parsed);
    }
    final background = parse('background', const Color(0xfff7f7f5));
    final ink = parse('ink', Colors.black);
    final accent = parse('accent', Colors.black);
    return ThemeData(useMaterial3: true, scaffoldBackgroundColor: background, colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light), fontFamily: 'Arial', appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: ink, elevation: 0), textTheme: ThemeData.light().textTheme.apply(bodyColor: ink, displayColor: ink));
  }
}
