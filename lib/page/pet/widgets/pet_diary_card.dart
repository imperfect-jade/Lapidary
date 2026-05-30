import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet_diary/pet_diary.dart';
import 'package:todolist/page/pet_diary/pet_diary_controller.dart';

/// 宠物日记页中的今日日记小纸条。
///
/// 组件只消费 `PetDiaryController` 的响应式状态：展示今日日记、触发刷新、
/// 跳转历史页，不修改日记统计口径或模板生成规则。
class PetDiaryCard extends StatelessWidget {
  final PetDiaryController controller;

  const PetDiaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final diary = controller.todayDiary.value;
      final isGenerating = controller.isGenerating.value;
      final canGenerate =
          diary != null || controller.hasDiarySourceDataForDate(DateTime.now());

      if (!canGenerate && !isGenerating) {
        return const SizedBox.shrink();
      }

      return RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: diary == null && isGenerating
              ? _DiaryPaper(
                  key: const ValueKey('pet-diary-loading'),
                  child: _LoadingContent(message: '正在写今天的小纸条...'),
                )
              : _DiaryPaper(
                  key: ValueKey(diary?.id ?? 'pet-diary-empty'),
                  child: diary == null
                      ? _EmptyDiaryContent(controller: controller)
                      : _DiaryContent(
                          diary: diary,
                          controller: controller,
                          isGenerating: isGenerating,
                        ),
                ),
        ),
      );
    });
  }
}

class _DiaryPaper extends StatelessWidget {
  final Widget child;

  const _DiaryPaper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TaskTheme.selectedColor.withValues(alpha: 0.18),
        ),
      ),
      child: child,
    );
  }
}

class _DiaryContent extends StatelessWidget {
  final PetDiaryModel diary;
  final PetDiaryController controller;
  final bool isGenerating;

  const _DiaryContent({
    required this.diary,
    required this.controller,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiaryHeader(date: _formatDate(diary.date)),
        const SizedBox(height: 10),
        Text(
          diary.diaryText,
          softWrap: true,
          style: const TextStyle(
            fontSize: 14,
            height: 1.55,
            color: Color(0xFF384238),
          ),
        ),
        const SizedBox(height: 12),
        _DiaryStatsWrap(diary: diary),
        const SizedBox(height: 10),
        _DiaryActions(
          controller: controller,
          isGenerating: isGenerating,
          hasDiary: true,
        ),
      ],
    );
  }
}

class _EmptyDiaryContent extends StatelessWidget {
  final PetDiaryController controller;

  const _EmptyDiaryContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DiaryHeader(date: '今天'),
        const SizedBox(height: 10),
        const Text(
          '今天有新的记录，可以生成一张宠物日记小纸条。',
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF5C665A)),
        ),
        const SizedBox(height: 10),
        _DiaryActions(
          controller: controller,
          isGenerating: false,
          hasDiary: false,
        ),
      ],
    );
  }
}

class _LoadingContent extends StatelessWidget {
  final String message;

  const _LoadingContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(TaskTheme.selectedColor),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5C665A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiaryHeader extends StatelessWidget {
  final String date;

  const _DiaryHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.sticky_note_2_outlined,
          size: 20,
          color: TaskTheme.selectedColor,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '今日宠物日记',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F3A31),
            ),
          ),
        ),
        Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7A8478),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DiaryStatsWrap extends StatelessWidget {
  final PetDiaryModel diary;

  const _DiaryStatsWrap({required this.diary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DiaryChip(
          icon: Icons.check_circle_outline,
          label: '任务 ${diary.completedTaskCount}',
        ),
        _DiaryChip(
          icon: Icons.timer_outlined,
          label: '专注 ${diary.focusMinutes} 分钟',
        ),
        _DiaryChip(
          icon: Icons.nightlight_round,
          label: '晚间完成 ${diary.lateNightTaskCount}',
        ),
      ],
    );
  }
}

class _DiaryActions extends StatelessWidget {
  final PetDiaryController controller;
  final bool isGenerating;
  final bool hasDiary;

  const _DiaryActions({
    required this.controller,
    required this.isGenerating,
    required this.hasDiary,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 4,
        runSpacing: 4,
        children: [
          TextButton.icon(
            onPressed: isGenerating
                ? null
                : () {
                    controller.regenerateTodayDiary();
                  },
            icon: isGenerating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        TaskTheme.selectedColor,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(isGenerating ? '刷新中' : (hasDiary ? '刷新今日' : '生成今日')),
            style: TextButton.styleFrom(
              foregroundColor: TaskTheme.selectedColor,
              disabledForegroundColor: TaskTheme.selectedColor.withValues(
                alpha: 0.45,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DiaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: TaskTheme.appBarColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TaskTheme.selectedColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF556052),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
