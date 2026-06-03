import 'package:flutter/material.dart';

enum CustomAccentColor {
  cyan(Color(0xFF00FFCC), 'Neon Cyan'),
  blue(Color(0xFF3B82F6), 'Electric Blue'),
  orange(Color(0xFFFF6B6B), 'Sunset Orange'),
  green(Color(0xFF10B981), 'Emerald Green'),
  violet(Color(0xFF8B5CF6), 'Violet Pulse');

  final Color color;
  final String label;
  const CustomAccentColor(this.color, this.label);
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default mode is dark
  CustomAccentColor _accentColor = CustomAccentColor.cyan; // Default color is cyan

  ThemeMode get themeMode => _themeMode;
  CustomAccentColor get accentColor => _accentColor;
  Color get primaryColor => _accentColor.color;

  void toggleThemeMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setAccentColor(CustomAccentColor customColor) {
    _accentColor = customColor;
    notifyListeners();
  }

  /// Helper to build the custom ThemeData based on theme status and accent color
  ThemeData buildThemeData(bool isDarkMode) {
    final baseTheme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    final background = isDarkMode ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9);
    final surface = isDarkMode ? const Color(0xFF131B2E) : const Color(0xFFFFFFFF);
    final textThemeColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDarkMode ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600;

    return baseTheme.copyWith(
      scaffoldBackgroundColor: background,
      cardColor: surface,
      primaryColor: primaryColor,
      colorScheme: (isDarkMode ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textThemeColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textThemeColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12, width: 1.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black12, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDarkMode ? const Color(0xFF0A0F1D) : Colors.white,
          elevation: isDarkMode ? 6 : 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF070B14).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black12, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        labelStyle: TextStyle(color: textMuted, fontSize: 13),
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 13),
        prefixIconColor: textMuted,
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black45,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }
}
