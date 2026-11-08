import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData data([Map<String, dynamic>? config]) {
    Color parse(String key, Color fallback) {
      final value = '${config?[key] ?? ''}'.replaceFirst('#', '');
      final parsed = int.tryParse(value.length == 6 ? 'ff$value' : value, radix: 16);
      return parsed == null ? fallback : Color(parsed);
    }
    // The mobile UI follows the supplied marketplace reference: charcoal ink,
    // soft gray surfaces, warm product accents, and restrained borders.
    final background = parse('background', const Color(0xfff1f1f1));
    final ink = parse('ink', const Color(0xff050505));
    final accent = parse('accent', const Color(0xff3f4041));
    final surface = parse('surface', Colors.white);
    final border = parse('border', const Color(0xffd9dada));
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light).copyWith(surface: surface, outline: border);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      fontFamily: 'Arial',
      appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: ink, elevation: 0, surfaceTintColor: Colors.transparent),
      cardTheme: CardTheme(color: surface, surfaceTintColor: Colors.transparent, elevation: 0, margin: EdgeInsets.zero),
      chipTheme: ChipThemeData(backgroundColor: surface, selectedColor: ink, labelStyle: TextStyle(color: ink), secondaryLabelStyle: const TextStyle(color: Colors.white), side: BorderSide(color: border)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: surface, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: accent, width: 2))),
      textTheme: ThemeData.light().textTheme.apply(bodyColor: ink, displayColor: ink),
    );
  }
}
