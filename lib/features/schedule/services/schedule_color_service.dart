import 'package:flutter/material.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/schedule/schedule.dart';

class ScheduleColorService {
  static Color colorForSession(
    ScheduleSessionModel session,
    AppThemePalette palette,
  ) {
    final hash = (session.id ?? session.name).hashCode.abs();
    final selected = HSLColor.fromColor(palette.selectedColor);
    final appBar = HSLColor.fromColor(palette.appBarColor);
    final lowSaturationTheme =
        selected.saturation < 0.22 && appBar.saturation < 0.22;
    final isDarkTheme =
        palette.key == 'dark' ||
        ThemeData.estimateBrightnessForColor(palette.primaryColor) ==
            Brightness.dark;
    final seed = HSLColor.fromColor(_themeSeedColor(palette));
    const hueOffsets = [-28.0, -16.0, -6.0, 6.0, 16.0, 28.0, 40.0];
    final variant = (hash ~/ hueOffsets.length) % 3;
    final hue = _wrapHue(seed.hue + hueOffsets[hash % hueOffsets.length]);
    final saturationBase = lowSaturationTheme
        ? (isDarkTheme ? 0.28 : 0.32)
        : (selected.saturation * 0.46 + appBar.saturation * 0.18 + 0.22);
    final saturation = (saturationBase + variant * 0.025)
        .clamp(0.28, 0.48)
        .toDouble();
    final lightness = _lightnessForPalette(palette, variant);
    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
  }

  static Color _themeSeedColor(AppThemePalette palette) {
    final selected = HSLColor.fromColor(palette.selectedColor);
    final appBar = HSLColor.fromColor(palette.appBarColor);
    if (selected.saturation >= 0.22) {
      return palette.selectedColor;
    }
    if (appBar.saturation >= 0.22) {
      return palette.appBarColor;
    }

    return switch (palette.key) {
      'light' => const Color(0xFF6F96A6),
      'dark' => const Color(0xFF626FA8),
      _ => palette.selectedColor,
    };
  }

  static double _lightnessForPalette(AppThemePalette palette, int variant) {
    if (palette.key == 'dark') {
      return (0.42 + variant * 0.035).clamp(0.42, 0.50).toDouble();
    }
    if (palette.key == 'light') {
      return (0.66 + variant * 0.025).clamp(0.66, 0.72).toDouble();
    }
    final isDarkTheme =
        ThemeData.estimateBrightnessForColor(palette.primaryColor) ==
        Brightness.dark;
    if (isDarkTheme) {
      return (0.44 + variant * 0.035).clamp(0.44, 0.52).toDouble();
    }
    return (0.60 + variant * 0.03).clamp(0.60, 0.68).toDouble();
  }

  static double _wrapHue(double hue) {
    return (hue % 360 + 360) % 360;
  }
}
