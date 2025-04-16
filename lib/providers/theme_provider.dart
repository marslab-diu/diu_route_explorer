import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _darkModeKey = 'dark_mode';

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  /// Load the saved theme preference from shared preferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  /// Toggle between light and dark theme modes
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  /// Get the appropriate theme mode based on the current state
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Light theme data
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color.fromARGB(255, 88, 13, 218),
      primarySwatch: Colors.indigo,
      colorScheme: ColorScheme.light(
        primary: const Color.fromARGB(255, 88, 13, 218),
        secondary: const Color.fromARGB(255, 117, 58, 218),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 88, 13, 218),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 88, 13, 218),
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
        bodyLarge: TextStyle(color: Colors.black87),
        displayMedium: TextStyle(color: Colors.black),
        displaySmall: TextStyle(color: Colors.black),
      ),
      dividerColor: Colors.grey[300],
      cardColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  /// Dark theme data
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color.fromARGB(255, 126, 52, 255),
      primarySwatch: Colors.indigo,
      colorScheme: ColorScheme.dark(
        primary: const Color.fromARGB(255, 126, 52, 255),
        secondary: const Color.fromARGB(255, 126, 52, 255),
        surface: const Color.fromARGB(255, 0, 0, 0),
        background: const Color.fromARGB(255, 0, 0, 0),
      ),
      scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 126, 52, 255),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 126, 52, 255),
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
      ),
      dividerColor: Colors.grey[800],
      cardColor: const Color(0xFF1F1F1F),
      iconTheme: const IconThemeData(color: Colors.white),
      dialogBackgroundColor: const Color(0xFF1F1F1F),
    );
  }
}
