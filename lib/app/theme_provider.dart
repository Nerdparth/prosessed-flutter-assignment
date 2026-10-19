import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'dark_mode';
  @override
  ThemeMode build() {
    _restoreTheme();
    return ThemeMode.light;
  }

  Future<void> _restoreTheme() async {
    final value = await _storage.read(key: _themeKey);
    if (!ref.mounted) return;

    state = value == 'true' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(key: _themeKey, value: isDark.toString());
  }
}
