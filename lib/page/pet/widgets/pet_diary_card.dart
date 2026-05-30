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
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: diary == null
              ? _EmptyDiaryContent(
                  key: ValueKey(
                    'pet-letter-${isGenerating ? 'writing' : 'closed'}',
                  ),
                  controller: controller,
                  isGenerating: isGenerating,
                )
              : _DiaryPaper(
                  key: ValueKey('pet-letter-open-${diary.id}'),
                  child: _DiaryContent(
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TaskTheme.selectedColor.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.only(right: 42), child: child),
          Positioned(
            right: 0,
            top: 0,
            child: _LetterStamp(color: TaskTheme.selectedColor),
          ),
        ],
      ),
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
  final bool isGenerating;

  const _EmptyDiaryContent({
    super.key,
    required this.controller,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    final accent = TaskTheme.selectedColor;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 188),
      child: CustomPaint(
        painter: _EnvelopePainter(accent: accent),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _EnvelopePostage(color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isGenerating ? '正在写信...' : '小云给你准备了一封今日来信',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F3A31),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isGenerating ? '小云正在把今天的努力整理成一句温柔的话。' : '今天的努力已经装进信封里，拆开看看吧。',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF5C665A),
                ),
              ),
              const SizedBox(height: 18),
              _DiaryActions(
                controller: controller,
                isGenerating: isGenerating,
                hasDiary: false,
              ),
            ],
          ),
        ),
      ),
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
          Icons.mark_email_read_outlined,
          size: 20,
          color: TaskTheme.selectedColor,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '今日来信',
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
                : Icon(
                    hasDiary
                        ? Icons.edit_note_outlined
                        : Icons.mark_email_unread_outlined,
                    size: 18,
                  ),
            label: Text(
              isGenerating ? '正在写信...' : (hasDiary ? '重新写一封' : '拆开今日来信'),
            ),
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

class _EnvelopePostage extends StatelessWidget {
  final Color color;

  const _EnvelopePostage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(Icons.pets_outlined, size: 22, color: color),
    );
  }
}

class _LetterStamp extends StatelessWidget {
  final Color color;

  const _LetterStamp({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(Icons.favorite_border, size: 19, color: color),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  final Color accent;

  const _EnvelopePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.clipRRect(rrect);

    final basePaint = Paint()..color = const Color(0xFFFFF3DD);
    final flapPaint = Paint()..color = const Color(0xFFFFE8C2);
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rrect, basePaint);

    final topFlap = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height * 0.48)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topFlap, flapPaint);

    final bottomFlap = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height * 0.50)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(bottomFlap, Paint()..color = const Color(0xFFFFF7E8));

    canvas.drawLine(
      Offset.zero,
      Offset(size.width / 2, size.height * 0.48),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, size.height * 0.48),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width / 2, size.height * 0.50),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width / 2, size.height * 0.50),
      linePaint,
    );
    canvas.drawRRect(rrect.deflate(0.6), linePaint);

    final sealCenter = Offset(size.width / 2, size.height * 0.50);
    canvas.drawCircle(
      sealCenter,
      20,
      Paint()..color = accent.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      sealCenter,
      13,
      Paint()..color = accent.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
