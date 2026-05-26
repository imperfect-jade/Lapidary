import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/task_priority.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/utils/formatters.dart';

void showTaskDetailDialog(TaskModel task) {
  final priority = taskPriorityOf(task.priority);
  Get.dialog(
    AlertDialog(
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
              '完成状态',
              task.isCompleted ? '已完成' : '待完成',
              valueColor: task.isCompleted ? Colors.green : Colors.orange,
            ),
            _detailRow('任务类型', TaskType.labelOf(task.taskType)),
            _detailRow('截止时间', formatTaskDateTime(task.deadline)),
            _detailRow('创建时间', formatTaskDateTime(task.createdAt)),
            _detailRow('优先级', priority.label, valueColor: priority.color),
            if (task.hasFocusTarget)
              _detailRow('专注目标', formatTaskFocusTarget(task)),
            const SizedBox(height: 12),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const Text('任务描述', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(task.description!),
            ] else ...[
              const Text('暂无描述', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
      ],
    ),
  );
}

Widget _detailRow(String label, String value, {Color? valueColor}) {
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
