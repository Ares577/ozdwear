import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData data() => ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xfff7f7f5), colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: Brightness.light), fontFamily: 'Arial', appBarTheme: const AppBarTheme(backgroundColor: Color(0xfff7f7f5), foregroundColor: Colors.black, elevation: 0));
}
