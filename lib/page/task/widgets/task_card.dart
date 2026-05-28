import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/task_priority.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/task_controller.dart';
import 'package:todolist/page/task/utils/formatters.dart';
import 'package:todolist/page/task/widgets/task_chips.dart';

/// 任务列表中的单个任务卡片。
///
/// 卡片负责展示、完成状态切换和删除确认；持久化操作统一委托给 [TaskController]。
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskController controller;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priority = taskPriorityOf(task.priority);
    return Card(
      // 卡片主体：左侧完成勾选，中间摘要信息，右侧删除入口。
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: onTap,
        leading: Checkbox(
          // 完成状态切换：只调用 Controller，由 Controller 决定是否触发奖励和刷新。
          value: task.isCompleted,
          onChanged: (value) {
            controller.updateTaskStatus(task);
          },
        ),
        title: Row(
          children: [
            // 标题区：完成后使用删除线和灰色弱化展示。
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.isCompleted ? Colors.grey : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 任务类型徽标：帮助用户快速识别日/周/月任务。
            TaskBadge(label: TaskType.labelOf(task.taskType)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    task.description!,
                    style: const TextStyle(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Wrap(
                // 摘要信息区：展示截止时间、优先级和可选专注目标。
                spacing: 8,
                runSpacing: 4,
                children: [
                  TaskInfoChip(
                    icon: Icons.schedule,
                    label: '截止 ${formatTaskDateTime(task.deadline)}',
                  ),
                  TaskInfoChip(
                    icon: Icons.flag,
                    label: priority.label,
                    color: priority.color,
                  ),
                  if (task.hasFocusTarget)
                    TaskInfoChip(
                      icon: Icons.timer_outlined,
                      label: formatTaskFocusTarget(task),
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            // 删除前二次确认，确认后只调用 Controller，不在组件内直接处理 Hive。
            Get.dialog(
              AlertDialog(
                title: const Text('删除任务'),
                content: const Text('确定要删除这个任务吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.deleteTask(task);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('删除'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
