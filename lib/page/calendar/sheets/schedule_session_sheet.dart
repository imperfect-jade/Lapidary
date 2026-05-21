part of '../calendar.dart';

void _showScheduleSessionDetailDialog(
  BuildContext context,
  ScheduleController controller,
  List<ScheduleSessionModel> sessions,
) {
  final title = sessions.length == 1 ? sessions.first.name : '冲突课程';
  final singleSession = sessions.length == 1 ? sessions.first : null;

  Get.dialog(
    AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: Get.height * 0.7),
        child: SingleChildScrollView(
          child: singleSession == null
              ? _buildScheduleConflictContent(context, controller, sessions)
              : _buildScheduleSessionDetailContent(singleSession),
        ),
      ),
      actions: [
        if (singleSession != null) ...[
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _confirmDeleteScheduleSession(controller, singleSession);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除'),
          ),
          TextButton.icon(
            onPressed: () {
              Get.back();
              _showScheduleSessionDialog(
                context,
                controller,
                session: singleSession,
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('编辑'),
          ),
        ],
        TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
      ],
    ),
  );
}

Widget _buildScheduleSessionDetailContent(ScheduleSessionModel session) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _scheduleDetailRow('上课时间', session.chineseTime),
      _scheduleDetailRow('教师', _scheduleValueOrFallback(session.teacher)),
      _scheduleDetailRow('地点', _scheduleValueOrFallback(session.location)),
      _scheduleDetailRow('重复', _formatScheduleRepeat(session)),
      _scheduleDetailRow('学期范围', _formatScheduleHalfRange(session)),
      _scheduleDetailRow('上课方式', session.online == true ? '线上' : '线下'),
      _scheduleDetailRow('课程类型', _scheduleValueOrFallback(session.type)),
      if (session.credit != null)
        _scheduleDetailRow('学分', _formatScheduleCredit(session.credit!)),
    ],
  );
}

Widget _buildScheduleConflictContent(
  BuildContext context,
  ScheduleController controller,
  List<ScheduleSessionModel> sessions,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: sessions
        .map(
          (session) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: TaskTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: TaskTheme.selectedColor.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '编辑',
                      onPressed: () {
                        Get.back();
                        _showScheduleSessionDialog(
                          context,
                          controller,
                          session: session,
                        );
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: '删除',
                      onPressed: () {
                        Get.back();
                        _confirmDeleteScheduleSession(controller, session);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    session.chineseTime,
                    _scheduleValueOrFallback(session.location),
                    _formatScheduleRepeat(session),
                  ].join(' · '),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

Widget _scheduleDetailRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            '$label：',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

String _scheduleValueOrFallback(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return '未填写';
  }
  return text;
}

String _formatScheduleRepeat(ScheduleSessionModel session) {
  if (session.customRepeat) {
    if (session.customRepeatWeeks.isEmpty) {
      return '自定义周';
    }
    return '第${session.customRepeatWeeks.join('、')}周';
  }
  if (session.oddWeek && session.evenWeek) {
    return '每周';
  }
  if (session.oddWeek) {
    return '单周';
  }
  if (session.evenWeek) {
    return '双周';
  }
  return '未设置';
}

String _formatScheduleHalfRange(ScheduleSessionModel session) {
  if (session.firstHalf && session.secondHalf) {
    return '上半学期、下半学期';
  }
  if (session.firstHalf) {
    return '上半学期';
  }
  if (session.secondHalf) {
    return '下半学期';
  }
  return '未设置';
}

String _formatScheduleCredit(double credit) {
  if (credit == credit.roundToDouble()) {
    return credit.toInt().toString();
  }
  return credit.toStringAsFixed(1);
}

void _confirmDeleteScheduleSession(
  ScheduleController controller,
  ScheduleSessionModel session,
) {
  Get.dialog(
    AlertDialog(
      title: const Text('删除课程'),
      content: Text('确定要删除「${session.name}」这条课程安排吗？'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await controller.deleteSession(session);
            Get.back();
            Get.snackbar('已删除', '课程安排已删除');
          },
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
