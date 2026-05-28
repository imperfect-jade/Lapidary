import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';

/// 显示创建学期弹窗。
///
/// 弹窗负责收集学期名称和上下半学期日期范围，校验通过后调用
/// `ScheduleController.createSemester()` 生成半学期日期表并持久化。
void showScheduleSemesterDialog(
  BuildContext context,
  ScheduleController controller,
) {
  final now = DateTime.now();
  // 默认学年和季节按当前月份推导，减少用户首次创建课表时的输入成本。
  final schoolYearStart = now.month >= 8 ? now.year : now.year - 1;
  final season = now.month >= 8 ? '秋冬' : '春夏';
  final nameController = TextEditingController(
    text: '$schoolYearStart-${schoolYearStart + 1}$season',
  );
  // 日期字段用 Rx 驱动局部刷新，选择日期后只更新对应 ListTile。
  final firstHalfStart = DateTime(now.year, now.month, now.day).obs;
  final firstHalfEnd = firstHalfStart.value.add(const Duration(days: 55)).obs;
  final secondHalfStart = firstHalfEnd.value.add(const Duration(days: 1)).obs;
  final secondHalfEnd = secondHalfStart.value.add(const Duration(days: 55)).obs;

  Get.dialog(
    AlertDialog(
      title: const Text('创建学期'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: Get.height * 0.7),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 学期名称会直接进入 ScheduleSemesterModel.name，用于工具栏和学期菜单展示。
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '学期名称',
                  hintText: '例如：2025-2026秋冬',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                // 上半学期开始日期，是生成课表日期表的第一个边界。
                () => _ScheduleDateTile(
                  label: '上半学期开始',
                  date: firstHalfStart.value,
                  onTap: () async {
                    final date = await _pickScheduleDate(
                      context,
                      firstHalfStart.value,
                    );
                    if (date != null) {
                      firstHalfStart.value = date;
                    }
                  },
                ),
              ),
              Obx(
                // 上半学期结束日期必须不早于开始日期。
                () => _ScheduleDateTile(
                  label: '上半学期结束',
                  date: firstHalfEnd.value,
                  onTap: () async {
                    final date = await _pickScheduleDate(
                      context,
                      firstHalfEnd.value,
                    );
                    if (date != null) {
                      firstHalfEnd.value = date;
                    }
                  },
                ),
              ),
              Obx(
                // 下半学期开始日期必须晚于上半学期结束日期，避免两个半学期重叠。
                () => _ScheduleDateTile(
                  label: '下半学期开始',
                  date: secondHalfStart.value,
                  onTap: () async {
                    final date = await _pickScheduleDate(
                      context,
                      secondHalfStart.value,
                    );
                    if (date != null) {
                      secondHalfStart.value = date;
                    }
                  },
                ),
              ),
              Obx(
                // 下半学期结束日期必须不早于下半学期开始日期。
                () => _ScheduleDateTile(
                  label: '下半学期结束',
                  date: secondHalfEnd.value,
                  onTap: () async {
                    final date = await _pickScheduleDate(
                      context,
                      secondHalfEnd.value,
                    );
                    if (date != null) {
                      secondHalfEnd.value = date;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        ElevatedButton(
          onPressed: () async {
            // 提交前只做表单边界校验，日期表生成和保存交给 ScheduleController。
            final name = nameController.text.trim();
            if (name.isEmpty) {
              Get.snackbar('请填写学期名称', '学期名称不能为空');
              return;
            }
            if (firstHalfEnd.value.isBefore(firstHalfStart.value) ||
                !secondHalfStart.value.isAfter(firstHalfEnd.value) ||
                secondHalfEnd.value.isBefore(secondHalfStart.value)) {
              Get.snackbar('日期范围无效', '请确认四个日期按时间顺序排列');
              return;
            }
            await controller.createSemester(
              name: name,
              firstHalfStart: firstHalfStart.value,
              firstHalfEnd: firstHalfEnd.value,
              secondHalfStart: secondHalfStart.value,
              secondHalfEnd: secondHalfEnd.value,
            );
            Get.back();
          },
          child: const Text('创建'),
        ),
      ],
    ),
    // 弹窗关闭后释放输入控制器，日期 Rx 会随函数栈结束被回收。
  ).whenComplete(nameController.dispose);
}

/// 打开日期选择器，用于四个半学期边界日期。
Future<DateTime?> _pickScheduleDate(
  BuildContext context,
  DateTime initialDate,
) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
}

/// 学期日期选择行，展示标签、当前日期和日历图标。
class _ScheduleDateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _ScheduleDateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('${date.year}年${date.month}月${date.day}日'),
      trailing: const Icon(Icons.calendar_month),
      onTap: onTap,
    );
  }
}
