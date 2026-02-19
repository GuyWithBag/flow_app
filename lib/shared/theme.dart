import 'package:flutter/material.dart';

final iconButtonTheme = IconButtonThemeData(
  style: IconButton.styleFrom(elevation: 1, shadowColor: Colors.black),
);

final lightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  iconButtonTheme: iconButtonTheme,
);

final darkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color(0xFF1A1A1A),
  iconButtonTheme: iconButtonTheme,
);
