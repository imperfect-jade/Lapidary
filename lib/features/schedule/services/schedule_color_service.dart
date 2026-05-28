import 'package:flutter/material.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/schedule/schedule.dart';

/// 课表课程颜色服务。
///
/// 颜色由课程 id/name 的 hash 和当前主题共同决定，同一课程在同一主题下保持稳定；
/// 低饱和或深色主题会使用保守的 seed/lightness，避免课程卡片不可读。
class ScheduleColorService {
  /// 为课程生成稳定可用的卡片背景色。
  ///
  /// UI 层只传入课程和主题调色板，不在组件中复制颜色算法。
  static Color colorForSession(
    ScheduleSessionModel session,
    AppThemePalette palette,
  ) {
    // hash 决定 hue 偏移和亮度变体，保证同一课程颜色稳定但不同课程有差异。
    final hash = (session.id ?? session.name).hashCode.abs();
    final selected = HSLColor.fromColor(palette.selectedColor);
    final appBar = HSLColor.fromColor(palette.appBarColor);
    final lowSaturationTheme =
        selected.saturation < 0.22 && appBar.saturation < 0.22;
    // 深色主题需要更低亮度，防止课程卡片在暗色背景中过亮刺眼。
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

  /// 选择颜色种子。
  ///
  /// 主题主色或 appBar 色饱和度足够时直接使用；低饱和主题使用预设色避免全灰。
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

  /// 根据主题和变体计算亮度。
  ///
  /// 浅色主题偏亮，深色主题偏暗，自定义主题根据背景亮度自动选择区间。
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

  /// 将 hue 规范到 0-360，避免偏移后出现负值或超过色相范围。
  static double _wrapHue(double hue) {
    return (hue % 360 + 360) % 360;
  }
}
