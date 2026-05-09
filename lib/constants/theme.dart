// 主题颜色配置 - 预留设置主题颜色功能
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class AppThemePalette {
  final String key;
  final String label;
  final Color primaryColor;
  final Color appBarColor;
  final Color cardColor;
  final Color selectedColor;

  const AppThemePalette({
    required this.key,
    required this.label,
    required this.primaryColor,
    required this.appBarColor,
    required this.cardColor,
    required this.selectedColor,
  });
}

class ThemeController extends GetxController {
  static const String settingsBoxName = 'settings';
  static const String themeKey = 'theme_key';

  static const List<AppThemePalette> palettes = [
    AppThemePalette(
      key: 'light',
      label: '浅色系',
      primaryColor: Color.fromARGB(255, 246, 248, 250),
      appBarColor: Color.fromARGB(255, 219, 228, 236),
      cardColor: Colors.white,
      selectedColor: Color.fromARGB(255, 77, 92, 107),
    ),
    AppThemePalette(
      key: 'dark',
      label: '深色系',
      primaryColor: Color.fromARGB(255, 43, 52, 62),
      appBarColor: Color.fromARGB(255, 68, 82, 96),
      cardColor: Color.fromARGB(255, 247, 249, 250),
      selectedColor: Color.fromARGB(255, 68, 82, 96),
    ),
    AppThemePalette(
      key: 'blue',
      label: '浅蓝色系',
      primaryColor: Color.fromARGB(255, 225, 238, 247),
      appBarColor: Color.fromARGB(255, 146, 199, 243),
      cardColor: Colors.white,
      selectedColor: Color.fromARGB(255, 69, 132, 184),
    ),
    AppThemePalette(
      key: 'green',
      label: '绿色系',
      primaryColor: Color.fromARGB(255, 230, 246, 234),
      appBarColor: Color.fromARGB(255, 142, 210, 162),
      cardColor: Colors.white,
      selectedColor: Color.fromARGB(255, 75, 151, 94),
    ),
  ];

  final currentThemeKey = 'blue'.obs;

  late Box settingsBox;

  @override
  void onInit() {
    super.onInit();
    settingsBox = Hive.box(settingsBoxName);
    final savedThemeKey = settingsBox.get(themeKey) as String?;
    if (savedThemeKey != null &&
        palettes.any((palette) => palette.key == savedThemeKey)) {
      currentThemeKey.value = savedThemeKey;
    }
    applySystemUiOverlayStyle();
  }

  AppThemePalette get currentPalette {
    return palettes.firstWhere(
      (palette) => palette.key == currentThemeKey.value,
      orElse: () => palettes[2],
    );
  }

  Future<void> changeTheme(String key) async {
    if (!palettes.any((palette) => palette.key == key)) {
      return;
    }
    currentThemeKey.value = key;
    applySystemUiOverlayStyle();
    await settingsBox.put(themeKey, key);
  }

  SystemUiOverlayStyle get systemUiOverlayStyle {
    final palette = currentPalette;
    final appBarBrightness = ThemeData.estimateBrightnessForColor(
      palette.appBarColor,
    );
    final useLightIcons = appBarBrightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: palette.appBarColor,
      statusBarIconBrightness: useLightIcons
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: useLightIcons ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: palette.primaryColor,
      systemNavigationBarIconBrightness: ThemeData.estimateBrightnessForColor(
        palette.primaryColor,
      ) == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  void applySystemUiOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
}

class TaskTheme {
  static AppThemePalette get palette {
    if (Get.isRegistered<ThemeController>()) {
      return Get.find<ThemeController>().currentPalette;
    }
    return ThemeController.palettes[2];
  }

  static Color get primaryColor => palette.primaryColor;
  static Color get appBarColor => palette.appBarColor;
  static Color get cardColor => palette.cardColor;
  static Color get selectedColor => palette.selectedColor;
}
