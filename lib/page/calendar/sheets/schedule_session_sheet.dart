import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/page/calendar/dialogs/schedule_session_dialog.dart';
import 'package:todolist/page/calendar/utils/formatters.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';

/// 显示课程详情弹窗。
///
/// 单课程时展示完整字段并提供编辑/删除入口；多课程时视为冲突课程，
/// 展示每门课的摘要和独立编辑/删除按钮。
void showScheduleSessionDetailDialog(
  BuildContext context,
  ScheduleController controller,
  List<ScheduleSessionModel> sessions,
) {
  // 课程 block 可能包含多个重叠课程，标题和内容根据数量切换。
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
          // 单课程展示字段详情，冲突课程展示可分别处理的课程列表。
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
              // 删除先关闭详情弹窗，再打开二次确认，避免弹窗层叠过深。
              Get.back();
              _confirmDeleteScheduleSession(controller, singleSession);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除'),
          ),
          TextButton.icon(
            onPressed: () {
              // 编辑复用课程表单，传入当前 session 即进入编辑模式。
              Get.back();
              showScheduleSessionDialog(
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

/// 单课程详情内容，展示时间、教师、地点、重复规则、半学期和可选字段。
Widget _buildScheduleSessionDetailContent(ScheduleSessionModel session) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _scheduleDetailRow('上课时间', session.chineseTime),
      _scheduleDetailRow('教师', scheduleValueOrFallback(session.teacher)),
      _scheduleDetailRow('地点', scheduleValueOrFallback(session.location)),
      _scheduleDetailRow('重复', formatScheduleRepeat(session)),
      _scheduleDetailRow('学期范围', formatScheduleHalfRange(session)),
      _scheduleDetailRow('上课方式', session.online == true ? '线上' : '线下'),
      _scheduleDetailRow('课程类型', scheduleValueOrFallback(session.type)),
      if (session.credit != null)
        _scheduleDetailRow('学分', formatScheduleCredit(session.credit!)),
    ],
  );
}

/// 冲突课程详情内容。
///
/// 每一项都可单独编辑或删除，避免用户需要回到课表网格猜测是哪门课冲突。
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
                        // 关闭冲突详情后打开对应课程编辑弹窗。
                        Get.back();
                        showScheduleSessionDialog(
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
                        // 删除仍走二次确认，防止误删冲突列表中的课程。
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
                    scheduleValueOrFallback(session.location),
                    formatScheduleRepeat(session),
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

/// 课程详情中的一行标签和值。
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

/// 删除课程前的二次确认弹窗。
///
/// 确认后调用 `ScheduleController.deleteSession()`，由 Controller 保存当前学期。
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
