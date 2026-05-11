part of '../task.dart';

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskController controller;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priority = taskPriorityOf(task.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: onTap,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            controller.updateTaskStatus(task);
          },
        ),
        title: Row(
          children: [
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
            _TaskBadge(label: TaskType.labelOf(task.taskType)),
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
                spacing: 8,
                runSpacing: 4,
                children: [
                  _InfoChip(
                    icon: Icons.schedule,
                    label: '截止 ${_formatDateTime(task.deadline)}',
                  ),
                  _InfoChip(
                    icon: Icons.flag,
                    label: priority.label,
                    color: priority.color,
                  ),
                  if (task.hasFocusTarget)
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: _formatFocusTarget(task),
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
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
