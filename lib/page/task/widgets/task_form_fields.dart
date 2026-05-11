part of '../task.dart';

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
