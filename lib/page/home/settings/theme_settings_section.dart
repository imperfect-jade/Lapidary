import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';

/// 主题设置区，展示所有预设主题并响应当前主题变化。
class HomeThemeSettingsSection extends StatelessWidget {
  const HomeThemeSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区块标题：提示用户当前区域用于切换应用主题色。
        const Text(
          '主题色设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            // 设置 Sheet 宽度有限，窄屏降为单列，避免主题卡片内容拥挤。
            const spacing = 10.0;
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - 40;
            final columns = maxWidth < 320 ? 1 : 2;
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

            return Obx(
              // 主题切换后只刷新卡片选中态和颜色，不重建整个首页。
              () => Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: ThemeController.palettes.map((palette) {
                  final selected =
                      themeController.currentThemeKey.value == palette.key;
                  // 单个主题卡片：展示该主题的主要颜色，并在点击后持久化主题 key。
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => themeController.changeTheme(palette.key),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? palette.selectedColor
                              : Colors.white,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ColorDot(color: palette.appBarColor),
                              const SizedBox(width: 5),
                              _ColorDot(color: palette.primaryColor),
                              const SizedBox(width: 5),
                              _ColorDot(color: palette.selectedColor),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            palette.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (selected) ...[
                            const SizedBox(height: 6),
                            const Text(
                              '当前使用',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
