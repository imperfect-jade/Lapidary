part of '../calendar.dart';

void _showScheduleSemesterDialog(
  BuildContext context,
  ScheduleController controller,
) {
  final now = DateTime.now();
  final schoolYearStart = now.month >= 8 ? now.year : now.year - 1;
  final season = now.month >= 8 ? '秋冬' : '春夏';
  final nameController = TextEditingController(
    text: '$schoolYearStart-${schoolYearStart + 1}$season',
  );
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
  ).whenComplete(nameController.dispose);
}

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
