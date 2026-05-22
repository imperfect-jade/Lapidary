part of '../calendar.dart';

void _showScheduleSessionDialog(
  BuildContext context,
  ScheduleController controller, {
  ScheduleSessionModel? session,
}) {
  final nameController = TextEditingController(text: session?.name ?? '');
  final teacherController = TextEditingController(text: session?.teacher ?? '');
  final locationController = TextEditingController(
    text: session?.location ?? '',
  );
  final customWeeksController = TextEditingController(
    text: session?.customRepeatWeeks.join(', ') ?? '',
  );
  final typeController = TextEditingController(text: session?.type ?? '');

  final selectedDay = (session?.dayOfWeek ?? 1).obs;
  final startSection =
      (session?.time.isNotEmpty == true ? session!.time.first : 1).obs;
  final endSection =
      (session?.time.isNotEmpty == true ? session!.time.last : 2).obs;
  final firstHalf = (session?.firstHalf ?? controller.useFirstHalf.value).obs;
  final secondHalf =
      (session?.secondHalf ?? !controller.useFirstHalf.value).obs;
  final oddWeek = (session?.oddWeek ?? true).obs;
  final evenWeek = (session?.evenWeek ?? true).obs;
  final customRepeat = (session?.customRepeat ?? false).obs;
  final online = (session?.online ?? false).obs;

  Get.dialog(
    AlertDialog(
      title: Text(session == null ? '添加课程' : '编辑课程'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: Get.height * 0.72,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '课程名',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: teacherController,
                decoration: const InputDecoration(
                  labelText: '教师',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: '地点',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<int>(
                        key: ValueKey('day_${selectedDay.value}'),
                        initialValue: selectedDay.value,
                        decoration: const InputDecoration(
                          labelText: '星期',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: List.generate(
                          7,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              '周${ScheduleSessionModel.dayMap[index + 1]}',
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            selectedDay.value = value;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<int>(
                        key: ValueKey('start_${startSection.value}'),
                        initialValue: startSection.value,
                        decoration: const InputDecoration(
                          labelText: '开始节',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _sectionItems(),
                        onChanged: (value) {
                          if (value != null) {
                            startSection.value = value;
                            if (endSection.value < value) {
                              endSection.value = value;
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<int>(
                        key: ValueKey('end_${endSection.value}'),
                        initialValue: endSection.value,
                        decoration: const InputDecoration(
                          labelText: '结束节',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _sectionItems(),
                        onChanged: (value) {
                          if (value != null) {
                            endSection.value = value;
                            if (startSection.value > value) {
                              startSection.value = value;
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  children: [
                    FilterChip(
                      label: const Text('上半学期'),
                      selected: firstHalf.value,
                      onSelected: (value) => firstHalf.value = value,
                    ),
                    FilterChip(
                      label: const Text('下半学期'),
                      selected: secondHalf.value,
                      onSelected: (value) => secondHalf.value = value,
                    ),
                    FilterChip(
                      label: const Text('单周'),
                      selected: oddWeek.value,
                      onSelected: (value) => oddWeek.value = value,
                    ),
                    FilterChip(
                      label: const Text('双周'),
                      selected: evenWeek.value,
                      onSelected: (value) => evenWeek.value = value,
                    ),
                    FilterChip(
                      label: const Text('线上'),
                      selected: online.value,
                      onSelected: (value) => online.value = value,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Obx(
                () => SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('指定上课周'),
                  value: customRepeat.value,
                  onChanged: (value) => customRepeat.value = value,
                ),
              ),
              Obx(() {
                if (!customRepeat.value) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: customWeeksController,
                    decoration: const InputDecoration(
                      labelText: '上课周',
                      hintText: '例如：1, 3, 5, 7',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                );
              }),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: '课程类型',
                  hintText: '选填，例如：专业必修课',
                  border: OutlineInputBorder(),
                  isDense: true,
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
              Get.snackbar(
                '请填写课程名',
                '课程名不能为空',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            if (!firstHalf.value && !secondHalf.value) {
              Get.snackbar(
                '请选择学期范围',
                '课程至少要属于上半或下半学期',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            if (!customRepeat.value && !oddWeek.value && !evenWeek.value) {
              Get.snackbar(
                '请选择单双周',
                '课程至少要在单周或双周上课',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }

            final customWeeks = _parseCustomWeeks(customWeeksController.text);
            if (customRepeat.value && customWeeks.isEmpty) {
              Get.snackbar(
                '请填写上课周',
                '指定上课周不能为空',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }

            final scheduleSession = ScheduleSessionModel(
              id: session?.id,
              name: name,
              teacher: teacherController.text.trim().isEmpty
                  ? '未知'
                  : teacherController.text.trim(),
              teacherId: session?.teacherId,
              location: locationController.text.trim().isEmpty
                  ? null
                  : locationController.text.trim(),
              confirmed: session?.confirmed ?? true,
              dayOfWeek: selectedDay.value,
              time: List<int>.generate(
                endSection.value - startSection.value + 1,
                (index) => startSection.value + index,
              ),
              firstHalf: firstHalf.value,
              secondHalf: secondHalf.value,
              oddWeek: oddWeek.value,
              evenWeek: evenWeek.value,
              customRepeat: customRepeat.value,
              customRepeatWeeks: customWeeks,
              credit: session?.credit,
              online: online.value,
              type: typeController.text.trim().isEmpty
                  ? null
                  : typeController.text.trim(),
            );

            if (session == null) {
              await controller.addSession(scheduleSession);
            } else {
              await controller.updateSession(scheduleSession);
            }
            Get.back();
          },
          child: Text(session == null ? '添加' : '保存'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    teacherController.dispose();
    locationController.dispose();
    customWeeksController.dispose();
    typeController.dispose();
  });
}

List<DropdownMenuItem<int>> _sectionItems() {
  return List.generate(
    13,
    (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}')),
  );
}

List<int> _parseCustomWeeks(String input) {
  return input
      .split(RegExp(r'[,，\s]+'))
      .map((item) => int.tryParse(item.trim()))
      .whereType<int>()
      .where((week) => week > 0)
      .toSet()
      .toList()
    ..sort();
}
