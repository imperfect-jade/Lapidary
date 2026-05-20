part of '../calendar.dart';

Widget _buildCalendarModeSwitch(ScheduleController scheduleController) {
  return Obx(
    () => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<CalendarContentView>(
          segments: const [
            ButtonSegment(
              value: CalendarContentView.month,
              icon: Icon(Icons.calendar_month),
              label: Text('月历'),
            ),
            ButtonSegment(
              value: CalendarContentView.schedule,
              icon: Icon(Icons.view_week),
              label: Text('课表'),
            ),
          ],
          selected: {scheduleController.viewMode.value},
          onSelectionChanged: (selection) {
            scheduleController.changeViewMode(selection.first);
          },
        ),
      ),
    ),
  );
}

Widget _buildScheduleView(
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
    return Column(
      children: [
        _buildScheduleToolbar(context, scheduleController, semester),
        _buildScheduleGrid(context, scheduleController, semester),
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
              _showScheduleSemesterDialog(context, scheduleController),
          icon: const Icon(Icons.add),
          label: const Text('创建学期'),
        ),
      ],
    ),
  );
}

Widget _buildScheduleToolbar(
  BuildContext context,
  ScheduleController controller,
  ScheduleSemesterModel semester,
) {
  final selectedId = controller.selectedSemesterId.value;
  final halfLabel = controller.useFirstHalf.value
      ? _halfName(semester, true)
      : _halfName(semester, false);
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: TaskTheme.cardColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: TaskTheme.selectedColor.withValues(alpha: 0.12),
      ),
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 168,
          child: DropdownButtonFormField<String>(
            key: ValueKey(selectedId),
            initialValue: selectedId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '学期',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: controller.semesters
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectSemester(value);
              }
            },
          ),
        ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(_halfName(semester, true))),
            ButtonSegment(
              value: false,
              label: Text(_halfName(semester, false)),
            ),
          ],
          selected: {controller.useFirstHalf.value},
          onSelectionChanged: (selection) =>
              controller.selectHalf(selection.first),
        ),
        Tooltip(
          message: controller.hideCourseInformation.value ? '显示课程信息' : '隐藏课程信息',
          child: IconButton.filledTonal(
            onPressed: controller.toggleHiddenInformation,
            icon: Icon(
              controller.hideCourseInformation.value
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showScheduleSessionDialog(context, controller),
          icon: const Icon(Icons.add),
          label: const Text('添加课程'),
        ),
        Text(
          '$halfLabel · ${controller.sessionsByDayOfWeek.fold<int>(0, (total, day) => total + day.length)} 条',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    ),
  );
}

Widget _buildScheduleGrid(
  BuildContext context,
  ScheduleController controller,
  ScheduleSemesterModel semester,
) {
  return Expanded(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth < 720
            ? 720.0
            : constraints.maxWidth;
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: gridWidth,
              child: Column(
                children: [
                  _buildWeekHeader(context),
                  SizedBox(
                    height: 650,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: _buildSectionTimeColumn(semester),
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
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildWeekHeader(BuildContext context) {
  const days = ['一', '二', '三', '四', '五', '六', '日'];
  return Container(
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        const SizedBox(width: 56, child: Center(child: Text('节'))),
        for (final day in days)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildSectionTimeColumn(ScheduleSemesterModel semester) {
  return Column(
    children: [
      for (var section = 1; section <= 13; section++)
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sectionStartTime(semester, section),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  '$section',
                  style: const TextStyle(
                    fontSize: 14,
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
) {
  final blocks = _buildScheduleBlocks(sessions);
  return blocks
      .map(
        (block) => Positioned(
          top: (block.start - 1) * maxHeight / 13,
          bottom: (13 - block.end) * maxHeight / 13,
          left: 0,
          right: 0,
          child: _ScheduleCourseCard(
            sessions: block.sessions,
            hideInformation: controller.hideCourseInformation.value,
            onTap: () =>
                _showScheduleSessionDetailSheet(controller, block.sessions),
          ),
        ),
      )
      .toList();
}

List<_ScheduleBlock> _buildScheduleBlocks(List<ScheduleSessionModel> sessions) {
  final validSessions = sessions.where((session) => session.time.isNotEmpty);
  final blocks = <_ScheduleBlock>[];
  for (final session in validSessions) {
    var start = session.time.first;
    var end = session.time.last;
    final overlapping = blocks
        .where((block) => !(block.end < start || end < block.start))
        .toList();
    for (final block in overlapping) {
      if (block.start < start) {
        start = block.start;
      }
      if (block.end > end) {
        end = block.end;
      }
    }
    blocks.removeWhere((block) => overlapping.contains(block));
    blocks.add(_ScheduleBlock(start, end));
  }
  blocks.sort((a, b) => a.start.compareTo(b.start));
  for (final block in blocks) {
    final byId = <String, ScheduleSessionModel>{};
    for (final session in validSessions) {
      final start = session.time.first;
      final end = session.time.last;
      if (block.end < start || end < block.start) {
        continue;
      }
      final key = session.id ?? '${session.name}_${session.dayOfWeek}_$start';
      final existing = byId[key];
      if (existing == null) {
        byId[key] = session.copyWith(time: List<int>.from(session.time));
      } else {
        final timeSet = <int>{...existing.time, ...session.time}.toList()
          ..sort();
        byId[key] = existing.copyWith(time: timeSet);
      }
    }
    block.sessions.addAll(byId.values);
  }
  return blocks;
}

String _halfName(ScheduleSemesterModel semester, bool firstHalf) {
  final halfName = firstHalf ? semester.firstHalfName : semester.secondHalfName;
  if (halfName.isEmpty) {
    return firstHalf ? '上半学期' : '下半学期';
  }
  return '$halfName学期';
}

String _sectionStartTime(ScheduleSemesterModel semester, int section) {
  if (section >= semester.sessionToTimeMinutes.length ||
      semester.sessionToTimeMinutes[section].isEmpty) {
    return '--:--';
  }
  return _formatMinutes(semester.sessionToTimeMinutes[section].first);
}

String _formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

Color _scheduleColorForSession(ScheduleSessionModel session) {
  const colors = [
    Color(0xFF4D84B8),
    Color(0xFF4B975E),
    Color(0xFFE38B43),
    Color(0xFF8A6FC5),
    Color(0xFFC75D6B),
    Color(0xFF2F9D9A),
  ];
  final hash = (session.id ?? session.name).hashCode.abs();
  return colors[hash % colors.length];
}

class _ScheduleBlock {
  final int start;
  final int end;
  final List<ScheduleSessionModel> sessions = [];

  _ScheduleBlock(this.start, this.end);
}

class _ScheduleCourseCard extends StatelessWidget {
  final List<ScheduleSessionModel> sessions;
  final bool hideInformation;
  final VoidCallback onTap;

  const _ScheduleCourseCard({
    required this.sessions,
    required this.hideInformation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstSession = sessions.first;
    final color = _scheduleColorForSession(firstSession);
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
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.55)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(7),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 5, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: sessions.length == 1 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: sessions.length == 1 ? 2 : 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
