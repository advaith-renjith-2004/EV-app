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
    final background = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
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
        elevation: isDarkMode ? 0 : 1,
        titleTextStyle: TextStyle(
          color: textThemeColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textThemeColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          elevation: isDarkMode ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background.withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textMuted),
        prefixIconColor: textMuted,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black45,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }
}
