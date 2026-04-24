import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema claro/escuro persistido; padrão [ThemeMode.light].
class ThemeController extends ChangeNotifier {
  static const _k = 'sf.theme_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_k);
    if (s == 'dark') {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    if (_mode == m) return;
    _mode = m;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _k,
      m == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }
}
