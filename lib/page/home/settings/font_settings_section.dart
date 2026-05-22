part of '../home.dart';

class _FontSettingsSection extends StatelessWidget {
  const _FontSettingsSection();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '字体设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - 40;
            final columns = maxWidth < 320 ? 1 : 2;
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

            return Obx(
              () => Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: ThemeController.fontOptions.map((option) {
                  final selected =
                      themeController.currentFontKey.value == option.key;
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
