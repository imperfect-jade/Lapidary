import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/features/schedule/services/schedule_color_service.dart';
import 'package:todolist/features/schedule/services/schedule_layout_service.dart';
import 'package:todolist/features/schedule/services/schedule_time_service.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/page/calendar/dialogs/schedule_semester_dialog.dart';
import 'package:todolist/page/calendar/dialogs/schedule_session_dialog.dart';
import 'package:todolist/page/calendar/sheets/schedule_session_sheet.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';

Widget buildScheduleView(
  BuildContext context,
  ScheduleController scheduleController,
) {
  return Obx(() {
    if (scheduleController.semesters.isEmpty) {
      return _buildScheduleEmptyState(context, scheduleController);
    }
    final semester = scheduleController.selectedSemester;
    if (semester == null) {
      return _buildScheduleEmptyState(context, scheduleController);
    }
    final palette = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>().currentPalette
        : TaskTheme.palette;
    final hideInformation = scheduleController.hideCourseInformation.value;
    return Column(
      children: [
        _buildScheduleToolbar(
          context,
          scheduleController,
          semester,
          hideInformation,
        ),
        _buildScheduleGrid(
          context,
          scheduleController,
          semester,
          palette,
          hideInformation,
        ),
      ],
    );
  });
}

Widget _buildScheduleEmptyState(
  BuildContext context,
  ScheduleController scheduleController,
) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.table_chart_outlined, size: 52, color: Colors.grey[300]),
        const SizedBox(height: 10),
        Text('还没有课表', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () =>
              showScheduleSemesterDialog(context, scheduleController),
          icon: const Icon(Icons.add),
          label: const Text('创建学期'),
        ),
      ],
    ),
  );
}

Widget buildScheduleFloatingActionButton(
  BuildContext context,
  ScheduleController controller,
) {
  return Obx(() {
    if (controller.viewMode.value != CalendarContentView.schedule) {
      return const SizedBox.shrink();
    }

    final hasSemester =
        controller.semesters.isNotEmpty && controller.selectedSemester != null;
    return FloatingActionButton(
      heroTag: 'schedule_fab',
      tooltip: hasSemester ? '添加课程' : '创建学期',
      backgroundColor: TaskTheme.selectedColor,
      foregroundColor: Colors.white,
      onPressed: () {
        if (hasSemester) {
          showScheduleSessionDialog(context, controller);
        } else {
          showScheduleSemesterDialog(context, controller);
        }
      },
      child: Icon(hasSemester ? Icons.add : Icons.add_chart),
    );
  });
}

Widget _buildScheduleToolbar(
  BuildContext context,
  ScheduleController controller,
  ScheduleSemesterModel semester,
  bool hideInformation,
) {
  final selectedId = controller.selectedSemesterId.value;
  final sessionCount = controller.sessionsByDayOfWeek.fold<int>(
    0,
    (total, day) => total + day.length,
  );
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: TaskTheme.cardColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: TaskTheme.selectedColor.withValues(alpha: 0.12),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final halfSwitch = _buildHalfSwitch(controller, semester);
        final infoActions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: hideInformation ? '显示课程信息' : '隐藏课程信息',
              child: IconButton.filledTonal(
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: controller.toggleHiddenInformation,
                icon: Icon(
                  hideInformation ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: PopupMenuButton<_ScheduleToolbarAction>(
                tooltip: '课表操作',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case _ScheduleToolbarAction.addSession:
                      showScheduleSessionDialog(context, controller);
                      break;
                    case _ScheduleToolbarAction.createSemester:
                      showScheduleSemesterDialog(context, controller);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ScheduleToolbarAction.addSession,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add),
                      title: Text('添加课程'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ScheduleToolbarAction.createSemester,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add_chart),
                      title: Text('创建学期'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Row(
          children: [
            Expanded(child: _buildSemesterSelector(controller, selectedId)),
            SizedBox(width: compact ? 4 : 8),
            halfSwitch,
            SizedBox(width: compact ? 4 : 8),
            _buildSessionCountBadge(sessionCount),
            const SizedBox(width: 4),
            infoActions,
          ],
        );
      },
    ),
  );
}

Widget _buildSemesterSelector(
  ScheduleController controller,
  String? selectedId,
) {
  final semester = controller.selectedSemester;
  return PopupMenuButton<String>(
    initialValue: selectedId,
    tooltip: '选择学期',
    onSelected: controller.selectSemester,
    itemBuilder: (context) => controller.semesters
        .map(
          (item) => PopupMenuItem(
            value: item.id,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: TaskTheme.primaryColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TaskTheme.selectedColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, size: 18, color: TaskTheme.selectedColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              semester?.name ?? '选择学期',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    ),
  );
}

Widget _buildSessionCountBadge(int sessionCount) {
  return Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: TaskTheme.primaryColor.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$sessionCount条',
      maxLines: 1,
      style: TextStyle(color: Colors.grey[600], fontSize: 10),
    ),
  );
}

Widget _buildHalfSwitch(
  ScheduleController controller,
  ScheduleSemesterModel semester,
) {
  final useFirstHalf = controller.useFirstHalf.value;
  final currentName = _shortHalfName(semester, useFirstHalf);
  final nextName = _shortHalfName(semester, !useFirstHalf);
  return Tooltip(
    message: '切换到$nextName',
    child: SizedBox(
      height: 36,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(48, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: TaskTheme.selectedColor,
          side: BorderSide(
            color: TaskTheme.selectedColor.withValues(alpha: 0.28),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => controller.selectHalf(!useFirstHalf),
        child: Text(
          currentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

Widget _buildScheduleGrid(
  BuildContext context,
  ScheduleController controller,
  ScheduleSemesterModel semester,
  AppThemePalette palette,
  bool hideInformation,
) {
  return Expanded(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final timeColumnWidth = compact ? 44.0 : 52.0;
        final rowHeight = compact ? 50.0 : 54.0;
        final gridHeight = rowHeight * 13;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 6 : 10,
            0,
            compact ? 6 : 10,
            12,
          ),
          child: Column(
            children: [
              _buildWeekHeader(timeColumnWidth, compact),
              SizedBox(
                height: gridHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: timeColumnWidth,
                      child: _buildSectionTimeColumn(semester, compact),
                    ),
                    for (var day = 1; day <= 7; day++)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, dayConstraints) {
                            return Stack(
                              children: [
                                _buildGridBackground(),
                                ..._buildScheduleCardsByDay(
                                  context,
                                  controller,
                                  controller.sessionsByDayOfWeek[day],
                                  dayConstraints.maxHeight,
                                  compact,
                                  palette,
                                  hideInformation,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildWeekHeader(double timeColumnWidth, bool compact) {
  const days = ['一', '二', '三', '四', '五', '六', '日'];
  return SizedBox(
    height: compact ? 30 : 34,
    child: Row(
      children: [
        SizedBox(width: timeColumnWidth),
        for (final day in days)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildSectionTimeColumn(ScheduleSemesterModel semester, bool compact) {
  return Column(
    children: [
      for (var section = 1; section <= 13; section++)
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ScheduleTimeService.sectionStartTime(semester, section),
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$section',
                  style: TextStyle(
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

Widget _buildGridBackground() {
  return Column(
    children: [
      for (var index = 0; index < 13; index++)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.withValues(alpha: 0.14)),
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.14)),
              ),
            ),
          ),
        ),
    ],
  );
}

List<Widget> _buildScheduleCardsByDay(
  BuildContext context,
  ScheduleController controller,
  List<ScheduleSessionModel> sessions,
  double maxHeight,
  bool compact,
  AppThemePalette palette,
  bool hideInformation,
) {
  final blocks = ScheduleLayoutService.buildBlocks(sessions);
  return blocks
      .map(
        (block) => Positioned(
          top: (block.start - 1) * maxHeight / 13,
          bottom: (13 - block.end) * maxHeight / 13,
          left: compact ? 1 : 2,
          right: compact ? 1 : 2,
          child: _ScheduleCourseCard(
            sessions: block.sessions,
            hideInformation: hideInformation,
            compact: compact,
            palette: palette,
            onTap: () => showScheduleSessionDetailDialog(
              context,
              controller,
              block.sessions,
            ),
          ),
        ),
      )
      .toList();
}

String _shortHalfName(ScheduleSemesterModel semester, bool firstHalf) {
  final halfName = firstHalf ? semester.firstHalfName : semester.secondHalfName;
  if (halfName.isEmpty) {
    return firstHalf ? '上半' : '下半';
  }
  return halfName;
}

enum _ScheduleToolbarAction { addSession, createSemester }

class _ScheduleCourseCard extends StatelessWidget {
  final List<ScheduleSessionModel> sessions;
  final bool hideInformation;
  final bool compact;
  final AppThemePalette palette;
  final VoidCallback onTap;

  const _ScheduleCourseCard({
    required this.sessions,
    required this.hideInformation,
    required this.compact,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstSession = sessions.first;
    final color = ScheduleColorService.colorForSession(firstSession, palette);
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final title = hideInformation
        ? '课程'
        : sessions.length == 1
        ? firstSession.name
        : '冲突课程';
    final subtitle = hideInformation
        ? ''
        : sessions.length == 1
        ? firstSession.location ?? '未知地点'
        : sessions.map((session) => session.name).join('\n');

    return Padding(
      padding: EdgeInsets.all(compact ? 1 : 2),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showSubtitle =
                  subtitle.isNotEmpty &&
                  !compact &&
                  constraints.maxHeight >= 68;
              final showSmallSubtitle =
                  subtitle.isNotEmpty && compact && constraints.maxHeight >= 92;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 6 : 8),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.16),
                      blurRadius: compact ? 2 : 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 3 : 7,
                  vertical: compact ? 4 : 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: compact
                          ? (constraints.maxHeight >= 72 ? 3 : 2)
                          : (sessions.length == 1 ? 2 : 1),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9.5 : 12,
                        height: compact ? 1.08 : 1.15,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    if (showSubtitle || showSmallSubtitle) ...[
                      SizedBox(height: compact ? 2 : 3),
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: compact ? 2 : 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 8 : 10,
                            height: 1.1,
                            color: foreground.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
