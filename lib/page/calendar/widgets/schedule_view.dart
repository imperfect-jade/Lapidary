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

/// 课表主视图，展示工具栏和按星期/节次排列的课程网格。
///
/// 视图读取 `ScheduleController` 的当前学期、半学期和隐藏信息状态；
/// 冲突合并、时间格式化和颜色计算分别委托给 feature 层服务。
Widget buildScheduleView(
  BuildContext context,
  ScheduleController scheduleController,
) {
  return Obx(() {
    // 没有任何学期时显示创建学期入口，避免空网格误导用户。
    if (scheduleController.semesters.isEmpty) {
      return _buildScheduleEmptyState(context, scheduleController);
    }
    final semester = scheduleController.selectedSemester;
    if (semester == null) {
      return _buildScheduleEmptyState(context, scheduleController);
    }
    // 课程颜色跟随当前主题；ThemeController 不存在时退回默认主题。
    final palette = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>().currentPalette
        : TaskTheme.palette;
    final hideInformation = scheduleController.hideCourseInformation.value;
    return Column(
      children: [
        // 顶部工具栏负责学期、半学期、课程数量和显示/隐藏信息切换。
        _buildScheduleToolbar(
          context,
          scheduleController,
          semester,
          hideInformation,
        ),
        // 下方网格按星期列和 13 节课行绘制课程卡片。
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

/// 课表空状态，提示用户先创建学期。
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

/// 课表模式下的浮动按钮。
///
/// 已有学期时用于添加课程，没有学期时用于创建学期；月历模式下隐藏。
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
        // 根据是否已有选中学期决定进入课程表单还是学期创建表单。
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

/// 课表顶部工具栏。
///
/// 工具栏集中承载学期选择、半学期切换、课程数量、隐藏课程信息和更多操作。
Widget _buildScheduleToolbar(
  BuildContext context,
  ScheduleController controller,
  ScheduleSemesterModel semester,
  bool hideInformation,
) {
  final selectedId = controller.selectedSemesterId.value;
  // 课程数量按当前半学期课表中的可展示课程统计，不直接读取所有 sessions。
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
        // 窄屏下压缩间距，保证工具栏按钮仍在一行内可用。
        final compact = constraints.maxWidth < 390;
        final halfSwitch = _buildHalfSwitch(controller, semester);
        final infoActions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              // 隐藏信息只影响课程卡片文字，不改变课程模型。
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
                // 更多菜单提供添加课程/创建学期入口，避免工具栏塞太多文字按钮。
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

/// 学期选择器，展示当前学期名称并通过弹出菜单切换。
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

/// 当前半学期课程数量徽标。
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

/// 上半/下半学期切换按钮。
///
/// 只切换 `useFirstHalf`，课程是否显示仍由模型中的 firstHalf/secondHalf 决定。
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

/// 课表网格区域，包含星期表头、节次时间列和每日课程卡片。
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
        // 根据屏幕宽度调整节次列和行高，避免移动端课程卡文字过度拥挤。
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
              // 顶部星期标题与下方七列课程网格对齐。
              _buildWeekHeader(timeColumnWidth, compact),
              SizedBox(
                height: gridHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: timeColumnWidth,
                      // 左侧节次时间列展示每节课开始时间和节次编号。
                      child: _buildSectionTimeColumn(semester, compact),
                    ),
                    for (var day = 1; day <= 7; day++)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, dayConstraints) {
                            return Stack(
                              children: [
                                // 背景线条提供 13 节课的网格参考。
                                _buildGridBackground(),
                                // 当天课程按重叠关系合并成可点击的课程 block。
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

/// 星期标题行。
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

/// 左侧节次时间列。
///
/// 开始时间由 `ScheduleTimeService` 从学期节次配置中读取，越界时显示 fallback。
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

/// 课程网格背景线，每一行对应一个节次。
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

/// 构建某一天的课程卡片。
///
/// 课程先由 `ScheduleLayoutService` 合并重叠区间，再按 block 定位到网格高度中。
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
              // 单课程和冲突课程都进入同一个详情弹窗，由 sessions 数量决定展示内容。
              context,
              controller,
              block.sessions,
            ),
          ),
        ),
      )
      .toList();
}

/// 获取半学期短名称，空名称时使用默认“上半/下半”。
String _shortHalfName(ScheduleSemesterModel semester, bool firstHalf) {
  final halfName = firstHalf ? semester.firstHalfName : semester.secondHalfName;
  if (halfName.isEmpty) {
    return firstHalf ? '上半' : '下半';
  }
  return halfName;
}

enum _ScheduleToolbarAction { addSession, createSemester }

/// 网格中的课程卡片。
///
/// 单课程展示课程名和地点；重叠课程展示“冲突课程”和课程名列表；
/// 隐藏信息模式下只显示通用文案，方便在公共场景查看课表。
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
    // block 内第一门课作为颜色种子，保证同一课程在不同位置颜色稳定。
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
              // 根据卡片高度决定是否展示副标题，避免小节次课程文字溢出。
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
