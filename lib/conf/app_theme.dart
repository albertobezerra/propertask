import 'package:flutter/material.dart';

// PALETA CLEAN/FUTURISTA
final ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF6AB090), // Verde principal
  onPrimary: Colors.white,
  primaryContainer: const Color(
    0xFFD6EFE6,
  ), // Verde pastel (cards, caixas ativas)
  onPrimaryContainer: const Color(0xFF255948),
  secondary: const Color(0xFF47C9E5), // Azul/verde (FAB, ações flutuantes)
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFD8F6FB),
  onSecondaryContainer: const Color(0xFF196A80),
  surface: const Color(0xFFF7F9FA), // Fundo de tela
  onSurface: const Color(0xFF22223B),
  error: const Color(0xFFEE5F5B),
  onError: Colors.white,
  outline: const Color(0xFFBFC9D0), // Linhas, ícones inativos, divisores
);

// THEME DATA
final ThemeData appTheme = ThemeData(
  colorScheme: appColorScheme,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: appColorScheme.surface,
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 1,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    shadowColor: Colors.black12,
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: appColorScheme.primary, // Fundo drawer verde
    scrimColor: const Color(0x11000000),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: appColorScheme.surface,
    foregroundColor: appColorScheme.primary,
    elevation: 0,
    titleTextStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Color(0xFF22223B),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: appColorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  tabBarTheme: TabBarThemeData(
    indicator: BoxDecoration(
      color: appColorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    labelColor: appColorScheme.primary,
    unselectedLabelColor: appColorScheme.outline,
  ),
  dividerTheme: DividerThemeData(
    color: appColorScheme.outline.withValues(alpha: 0.20),
    thickness: 1.0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: appColorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: appColorScheme.primary),
    ),
    fillColor: Colors.white,
    filled: true,
  ),
  iconTheme: IconThemeData(color: appColorScheme.primary, size: 24),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: appColorScheme.secondary,
    linearTrackColor: appColorScheme.outline.withValues(alpha: 0.20),
    circularTrackColor: appColorScheme.outline.withValues(alpha: 0.14),
    linearMinHeight: 4,
  ),
);
