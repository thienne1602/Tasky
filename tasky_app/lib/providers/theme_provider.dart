import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/palette.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({required SharedPreferences prefs}) : _prefs = prefs {
    _loadSettings();
  }

  static const _themeModeKey = 'theme_mode';
  static const _accentColorKey = 'accent_color';
  static const _fontScaleKey = 'font_scale';

  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = TaskyPalette.mint;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  double get fontScale => _fontScale;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadSettings() async {
    // Load theme mode
    final themeModeIndex = _prefs.getInt(_themeModeKey);
    if (themeModeIndex != null) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    // Load accent color
    final colorValue = _prefs.getInt(_accentColorKey);
    if (colorValue != null) {
      _accentColor = Color(colorValue);
    }

    // Load font scale
    final scale = _prefs.getDouble(_fontScaleKey);
    if (scale != null) {
      _fontScale = scale;
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setInt(_themeModeKey, _themeMode.index);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _prefs.setInt(_accentColorKey, color.value);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    await _prefs.setDouble(_fontScaleKey, scale);
    notifyListeners();
  }

  // Predefined accent colors
  static const List<AccentColorOption> accentColors = [
    AccentColorOption(color: TaskyPalette.mint, name: 'Mint', emoji: '🌿'),
    AccentColorOption(
        color: TaskyPalette.lavender, name: 'Lavender', emoji: '💜'),
    AccentColorOption(color: TaskyPalette.coral, name: 'Coral', emoji: '🪸'),
    AccentColorOption(color: TaskyPalette.aqua, name: 'Aqua', emoji: '💧'),
    AccentColorOption(color: TaskyPalette.blush, name: 'Blush', emoji: '🌸'),
  ];

  // Font scale options
  static const List<FontScaleOption> fontScales = [
    FontScaleOption(scale: 0.9, name: 'Nhỏ'),
    FontScaleOption(scale: 1.0, name: 'Vừa'),
    FontScaleOption(scale: 1.1, name: 'Lớn'),
  ];

  AccentColorOption get currentAccentColorOption {
    return accentColors.firstWhere(
      (option) => option.color.value == _accentColor.value,
      orElse: () => accentColors[0],
    );
  }

  FontScaleOption get currentFontScaleOption {
    return fontScales.firstWhere(
      (option) => option.scale == _fontScale,
      orElse: () => fontScales[1],
    );
  }
}

class AccentColorOption {
  const AccentColorOption({
    required this.color,
    required this.name,
    required this.emoji,
  });

  final Color color;
  final String name;
  final String emoji;
}

class FontScaleOption {
  const FontScaleOption({
    required this.scale,
    required this.name,
  });

  final double scale;
  final String name;
}
