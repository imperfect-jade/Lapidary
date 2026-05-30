import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet_diary/pet_diary.dart';
import 'package:todolist/page/pet/widgets/pet_diary_card.dart';
import 'package:todolist/page/pet_diary/pet_diary_controller.dart';

/// 宠物日记历史页。
///
/// 页面进入时刷新控制器缓存，按日期倒序展示已生成日记，并通过底部弹窗查看完整内容。
class PetDiaryPage extends StatefulWidget {
  const PetDiaryPage({super.key});

  @override
  State<PetDiaryPage> createState() => _PetDiaryPageState();
}

class _PetDiaryPageState extends State<PetDiaryPage> {
  final PetDiaryController controller = Get.find<PetDiaryController>();

  @override
  void initState() {
    super.initState();
    controller.loadDiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        title: const Text('宠物来信'),
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Obx(() {
        final diaries = controller.diaries;
        final todayDiary = controller.todayDiary.value;
        final showTodayEntry =
            todayDiary != null ||
            controller.isGenerating.value ||
            controller.hasDiarySourceDataForDate(DateTime.now());
        final historyDiaries = todayDiary == null
            ? diaries.toList()
            : diaries.where((diary) => diary.id != todayDiary.id).toList();

        if (!showTodayEntry && diaries.isEmpty) {
          return const _EmptyDiaryState();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (showTodayEntry) ...[
              PetDiaryCard(controller: controller),
              if (historyDiaries.isNotEmpty) const SizedBox(height: 18),
            ],
            if (historyDiaries.isNotEmpty) ...[
              const _SectionTitle(title: '往日来信'),
              const SizedBox(height: 10),
              for (final diary in historyDiaries) ...[
                _DiaryHistoryTile(
                  diary: diary,
                  onTap: () => _showDiaryDetail(context, diary),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        );
      }),
    );
  }

  void _showDiaryDetail(BuildContext context, PetDiaryModel diary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: TaskTheme.selectedColor.withValues(alpha: 0.18),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        color: TaskTheme.selectedColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '一封往日来信 · ${_formatDate(diary.date)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F3A31),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: Get.back,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    diary.diaryText,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF384238),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DiaryStatsWrap(diary: diary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF2F3A31),
      ),
    );
  }
}

class _DiaryHistoryTile extends StatelessWidget {
  final PetDiaryModel diary;
  final VoidCallback onTap;

  const _DiaryHistoryTile({required this.diary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: CustomPaint(
            painter: _HistoryEnvelopePainter(accent: TaskTheme.selectedColor),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HistoryPostage(color: TaskTheme.selectedColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(diary.date),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2F3A31),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.mark_email_read_outlined,
                              size: 19,
                              color: TaskTheme.selectedColor.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          diary.diaryText.replaceAll('\n', ' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF5C665A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _DiaryStatsWrap(diary: diary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryPostage extends StatelessWidget {
  final Color color;

  const _HistoryPostage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(Icons.favorite_border, size: 22, color: color),
    );
  }
}

class _HistoryEnvelopePainter extends CustomPainter {
  final Color accent;

  const _HistoryEnvelopePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.clipRRect(rrect);

    final basePaint = Paint()..color = const Color(0xFFFFFCF2);
    final flapPaint = Paint()..color = const Color(0xFFFFEFD5);
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, basePaint);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.42, size.height * 0.52)
        ..lineTo(0, size.height)
        ..close(),
      flapPaint,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(size.width * 0.42, size.height * 0.52),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width * 0.42, size.height * 0.52),
      linePaint,
    );
    canvas.drawRRect(rrect.deflate(0.6), linePaint);
  }

  @override
  bool shouldRepaint(covariant _HistoryEnvelopePainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _EmptyDiaryState extends StatelessWidget {
  const _EmptyDiaryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 42,
              color: TaskTheme.selectedColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              '还没有宠物来信，先去完成一个小任务吧。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF5C665A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

class _DiaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DiaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
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
