import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';

/// 字体设置区，展示字体预览并响应当前正文字体变化。
class HomeFontSettingsSection extends StatelessWidget {
  const HomeFontSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区块标题：提示用户当前区域用于切换应用正文字体。
        const Text(
          '字体设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            // 与主题卡片保持相同的响应式列数，保证设置 Sheet 视觉一致。
            const spacing = 10.0;
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - 40;
            final columns = maxWidth < 320 ? 1 : 2;
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

            return Obx(
              // 字体切换会影响全局主题，这里只负责展示当前选中态。
              () => Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: ThemeController.fontOptions.map((option) {
                  final selected =
                      themeController.currentFontKey.value == option.key;
                  // 单个字体卡片：展示字体预览、说明和当前选中态，点击后持久化字体 key。
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => themeController.changeBodyFont(option.key),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? TaskTheme.selectedColor
                              : Colors.grey.withValues(alpha: 0.18),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '琢玉',
                            style: TextStyle(
                              fontFamily: option.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: TaskTheme.selectedColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            option.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              height: 1.25,
                            ),
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
