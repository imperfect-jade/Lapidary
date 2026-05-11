part of '../task.dart';

void _showAddTaskDialog(TaskController controller) {
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: Get.height * 0.68,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              _PrioritySelector(selectedPriority: selectedPriority),
              const SizedBox(height: 10),
              _TaskTypeSelector(selectedType: selectedType),
              const SizedBox(height: 10),
              _DeadlineSelector(selectedDeadline: selectedDeadline),
              Obx(() {
                if (selectedType.value == TaskType.day) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
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
