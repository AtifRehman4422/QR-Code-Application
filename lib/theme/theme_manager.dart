import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum ThemeModeOption { system, light, dark }

class ThemeManager extends GetxController {
  static const _keyThemeMode = 'theme_mode';
  static const _keyUseSystem = 'use_system_theme';

  final Rx<ThemeModeOption> themeMode = ThemeModeOption.system.obs;
  final RxBool useSystemTheme = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadThemePreference().then((_) => _applyTheme());
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyThemeMode) ?? 0;
    themeMode.value = ThemeModeOption.values[index];
    useSystemTheme.value = prefs.getBool(_keyUseSystem) ?? true;
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    themeMode.value = mode;
    useSystemTheme.value = (mode == ThemeModeOption.system);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    await prefs.setBool(_keyUseSystem, useSystemTheme.value);
    _applyTheme();
  }

  void applyTheme() => _applyTheme();

  void _applyTheme() {
    switch (themeMode.value) {
      case ThemeModeOption.light:
        Get.changeThemeMode(ThemeMode.light);
        Get.changeTheme(AppTheme.lightTheme);
        break;
      case ThemeModeOption.dark:
        Get.changeThemeMode(ThemeMode.dark);
        Get.changeTheme(AppTheme.darkTheme);
        break;
      case ThemeModeOption.system:
        Get.changeThemeMode(ThemeMode.system);
        Get.changeTheme(
          Get.isPlatformDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        );
        break;
    }
  }

  bool get isDark => themeMode.value == ThemeModeOption.dark ||
      (themeMode.value == ThemeModeOption.system && Get.isPlatformDarkMode);
}
