import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/task_priority.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/task_controller.dart';

class TaskPage extends StatelessWidget {
  TaskPage({super.key});

  final TaskController controller = Get.find<TaskController>();
  final RxnString selectedTaskType = RxnString();

  void _showTaskDetailDialog(TaskModel task) {
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
              _detailRow('截止时间', _formatDateTime(task.deadline)),
              _detailRow('创建时间', _formatDateTime(task.createdAt)),
              _detailRow('优先级', priority.label, valueColor: priority.color),
              if (task.hasFocusTarget)
                _detailRow('专注目标', _formatFocusTarget(task)),
              const SizedBox(height: 12),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const Text(
                  '任务描述',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final focusTargetController = TextEditingController();
    final selectedPriority = 3.obs;
    final selectedType = TaskType.day.obs;
    final selectedFocusPeriod = FocusTargetPeriod.daily.obs;
    final now = DateTime.now();
    final selectedDeadline = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(hours: 1)).obs;

    Get.dialog(
      AlertDialog(
        title: const Text('添加任务'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '任务标题',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '任务描述',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                _PrioritySelector(selectedPriority: selectedPriority),
                const SizedBox(height: 14),
                _TaskTypeSelector(selectedType: selectedType),
                const SizedBox(height: 14),
                _DeadlineSelector(selectedDeadline: selectedDeadline),
                Obx(() {
                  if (selectedType.value == TaskType.day) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _FocusTargetSelector(
                      selectedPeriod: selectedFocusPeriod,
                      minutesController: focusTargetController,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                Get.snackbar(
                  '请填写标题',
                  '任务标题不能为空',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              final isLongTermTask = selectedType.value != TaskType.day;
              final focusMinutes = isLongTermTask
                  ? int.tryParse(focusTargetController.text.trim()) ?? 0
                  : 0;

              controller.addTask(
                title,
                selectedDeadline.value,
                priority: selectedPriority.value,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                taskType: selectedType.value,
                focusTargetPeriod: isLongTermTask
                    ? selectedFocusPeriod.value
                    : FocusTargetPeriod.daily,
                focusTargetMinutes: focusMinutes < 0 ? 0 : focusMinutes,
              );
              Get.back();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
      focusTargetController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        title: const Text('我的任务'),
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Obx(
            () => _TaskTypeFilter(
              selectedType: selectedTaskType.value,
              onSelected: (value) => selectedTaskType.value = value,
            ),
          ),
          Expanded(
            child: GetBuilder<TaskController>(
              id: 'task_list',
              builder: (controller) {
                return Obx(() {
                  final tasks = controller.tasksForType(selectedTaskType.value);
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        selectedTaskType.value == null
                            ? '暂无任务'
                            : '暂无${TaskType.labelOf(selectedTaskType.value!)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return GetBuilder<TaskController>(
                        id: 'task_${task.id}',
                        builder: (controller) => _buildTaskCard(task),
                      );
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priority = taskPriorityOf(task.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: () => _showTaskDetailDialog(task),
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

  String _formatDateTime(DateTime date) {
    return '${date.year}/${_two(date.month)}/${_two(date.day)} ${_two(date.hour)}:${_two(date.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatFocusTarget(TaskModel task) {
    return '目标：${FocusTargetPeriod.labelOf(task.focusTargetPeriod)} ${task.focusTargetMinutes} 分钟';
  }
}

class _PrioritySelector extends StatelessWidget {
  final RxInt selectedPriority;

  const _PrioritySelector({required this.selectedPriority});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final option = taskPriorityOf(selectedPriority.value);
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: '优先级',
          border: OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedPriority.value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: taskPriorityOptions.map((option) {
              return DropdownMenuItem<int>(
                value: option.value,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: option.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return taskPriorityOptions.map((_) {
                return Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: option.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                );
              }).toList();
            },
            onChanged: (value) {
              selectedPriority.value = value ?? 3;
            },
          ),
        ),
      );
    });
  }
}

class _TaskTypeSelector extends StatelessWidget {
  final RxString selectedType;

  const _TaskTypeSelector({required this.selectedType});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InputDecorator(
        decoration: const InputDecoration(
          labelText: '任务类型',
          border: OutlineInputBorder(),
        ),
        child: Wrap(
          spacing: 8,
          children: TaskType.values.map((type) {
            final selected = selectedType.value == type;
            return ChoiceChip(
              label: Text(TaskType.labelOf(type)),
              selected: selected,
              onSelected: (_) => selectedType.value = type,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DeadlineSelector extends StatelessWidget {
  final Rx<DateTime> selectedDeadline;

  const _DeadlineSelector({required this.selectedDeadline});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final deadline = selectedDeadline.value;
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: '截止时间',
          border: OutlineInputBorder(),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: Get.context!,
                  initialDate: deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                );
                if (date == null) {
                  return;
                }
                selectedDeadline.value = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  deadline.hour,
                  deadline.minute,
                );
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('${deadline.year}/${deadline.month}/${deadline.day}'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final time = await showTimePicker(
                  context: Get.context!,
                  initialTime: TimeOfDay.fromDateTime(deadline),
                );
                if (time == null) {
                  return;
                }
                selectedDeadline.value = DateTime(
                  deadline.year,
                  deadline.month,
                  deadline.day,
                  time.hour,
                  time.minute,
                );
              },
              icon: const Icon(Icons.access_time, size: 16),
              label: Text(
                '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FocusTargetSelector extends StatelessWidget {
  final RxString selectedPeriod;
  final TextEditingController minutesController;

  const _FocusTargetSelector({
    required this.selectedPeriod,
    required this.minutesController,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '专注目标',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Obx(
              () => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPeriod.value,
                  isExpanded: true,
                  items: FocusTargetPeriod.values.map((period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(FocusTargetPeriod.labelOf(period)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedPeriod.value = value ?? FocusTargetPeriod.daily;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '分钟数',
                suffixText: '分钟',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTypeFilter extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onSelected;

  const _TaskTypeFilter({required this.selectedType, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final filters = <String?, String>{
      null: '全部',
      TaskType.day: '日任务',
      TaskType.week: '周任务',
      TaskType.month: '月任务',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.entries.map((entry) {
          final selected = selectedType == entry.key;
          return ChoiceChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) => onSelected(entry.key),
            selectedColor: TaskTheme.appBarColor,
            backgroundColor: Colors.white.withValues(alpha: 0.76),
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.grey[700],
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  final String label;

  const _TaskBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TaskTheme.appBarColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: foreground)),
      ],
    );
  }
}
