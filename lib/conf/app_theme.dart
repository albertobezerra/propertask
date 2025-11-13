import 'package:flutter/material.dart';

final ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF2396EF),
  onPrimary: Colors.white,
  primaryContainer: const Color(0xFFE8F3FC),
  onPrimaryContainer: const Color(0xFF1969A3),

  secondary: const Color(0xFF38D9A9),
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFDFFEF2),
  onSecondaryContainer: const Color(0xFF156A5A),

  surface: const Color(0xFFF7F9FA),
  onSurface: const Color(0xFF22223B),

  error: const Color(0xFFEE5F5B),
  onError: Colors.white,

  outline: const Color(0xFFBFC9D0),
);

final ThemeData appTheme = ThemeData(
  colorScheme: appColorScheme,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: appColorScheme.surface,
  cardTheme: const CardThemeData(
    color: Color(0xFFF7F9FA), // Use surface aqui
    elevation: 2,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: appColorScheme.primaryContainer,
    // Use scrimColor: Color(0x11000000) para evitar warning com .withOpacity (RGBA semi-transparente)
    scrimColor: Color(0x11000000),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: appColorScheme.surface,
    foregroundColor: appColorScheme.primary,
    elevation: 0,
    titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: appColorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    indicator: BoxDecoration(
      color: Color(0xFFE8F3FC), // primaryContainer
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    labelColor: Color(0xFF2396EF), // primary
    unselectedLabelColor: Color(0xFFBFC9D0), // outline
  ),
);
