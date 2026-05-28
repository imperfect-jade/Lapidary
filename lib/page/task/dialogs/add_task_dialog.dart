import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/task_controller.dart';
import 'package:todolist/page/task/widgets/task_form_fields.dart';

/// 显示新增任务弹窗。
///
/// 弹窗只负责收集和校验输入，真正的创建、保存和跨模块刷新由 [TaskController.addTask] 完成。
void showAddTaskDialog(TaskController controller) {
  // 表单输入控制器：只在本弹窗生命周期内使用，关闭弹窗后统一释放。
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final focusTargetController = TextEditingController();

  // 表单临时状态：提交前都只保存在弹窗内，不直接写入任务列表。
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
    // 新增任务弹窗 UI：基础输入、优先级、类型、截止时间和长期任务专注目标。
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
                // 任务标题输入区：必填，提交时会做非空校验。
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                // 任务描述输入区：可选，空字符串会在提交时转换为 null。
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TaskPrioritySelector(selectedPriority: selectedPriority),
              const SizedBox(height: 10),
              TaskTypeSelector(selectedType: selectedType),
              const SizedBox(height: 10),
              TaskDeadlineSelector(selectedDeadline: selectedDeadline),
              Obx(() {
                if (selectedType.value == TaskType.day) {
                  return const SizedBox.shrink();
                }
                // 只有周/月等长期任务才显示专注目标，日任务不记录该字段。
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TaskFocusTargetSelector(
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
          onPressed: () async {
            final title = titleController.text.trim();
            if (title.isEmpty) {
              Get.snackbar(
                '请填写标题',
                '任务标题不能为空',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            if (!selectedDeadline.value.isAfter(DateTime.now())) {
              Get.snackbar(
                '截止时间无效',
                '请选择晚于当前时间的截止时间',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }

            final isLongTermTask = selectedType.value != TaskType.day;
            // 专注目标允许留空；非法输入按 0 处理，由业务层保持轻量容错。
            final focusMinutes = isLongTermTask
                ? int.tryParse(focusTargetController.text.trim()) ?? 0
                : 0;

            await controller.addTask(
              // 提交动作：将弹窗临时状态转换为 TaskModel 所需字段并交给 Controller 保存。
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
    // 弹窗关闭后释放输入控制器，避免多次打开新增任务时产生资源残留。
    titleController.dispose();
    descriptionController.dispose();
    focusTargetController.dispose();
  });
}
