import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/task_priority.dart';
import 'package:todolist/model/task/task.dart';

/// 任务优先级选择器。
///
/// 只维护弹窗内的临时选择值，提交时由新增任务弹窗统一读取。
class TaskPrioritySelector extends StatelessWidget {
  final RxInt selectedPriority;

  const TaskPrioritySelector({super.key, required this.selectedPriority});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final option = taskPriorityOf(selectedPriority.value);
      return InputDecorator(
        // 优先级表单块：下拉列表展示颜色和文案，选中值写回 selectedPriority。
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

/// 任务类型选择器，用于区分日任务、周任务和月任务。
class TaskTypeSelector extends StatelessWidget {
  final RxString selectedType;

  const TaskTypeSelector({super.key, required this.selectedType});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InputDecorator(
        // 任务类型表单块：ChoiceChip 切换日/周/月任务，影响是否展示专注目标。
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

/// 截止时间选择器，分别选择日期和时间后合并成一个 DateTime。
class TaskDeadlineSelector extends StatelessWidget {
  final Rx<DateTime> selectedDeadline;

  const TaskDeadlineSelector({super.key, required this.selectedDeadline});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final deadline = selectedDeadline.value;
      return InputDecorator(
        // 截止时间表单块：日期按钮和时间按钮共同维护同一个 selectedDeadline。
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
                // 保留原有时分，只替换日期部分。
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
                // 保留原有年月日，只替换时分部分。
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

/// 长期任务专注目标选择器。
///
/// 日任务不展示该控件；周/月任务可设置周期和目标分钟数，供番茄钟进度展示使用。
class TaskFocusTargetSelector extends StatelessWidget {
  final RxString selectedPeriod;
  final TextEditingController minutesController;

  const TaskFocusTargetSelector({
    super.key,
    required this.selectedPeriod,
    required this.minutesController,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      // 专注目标表单块：左侧选择周期，右侧输入目标分钟数。
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
