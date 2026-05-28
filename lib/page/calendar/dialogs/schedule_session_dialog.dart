import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';

/// 显示添加/编辑课程弹窗。
///
/// 弹窗只收集和校验课程表单数据，保存动作统一交给 `ScheduleController`；
/// 传入 `session` 时为编辑模式，否则为新增模式。
void showScheduleSessionDialog(
  BuildContext context,
  ScheduleController controller, {
  ScheduleSessionModel? session,
}) {
  // 文本控制器承载课程基础字段，关闭弹窗后统一释放。
  final nameController = TextEditingController(text: session?.name ?? '');
  final teacherController = TextEditingController(text: session?.teacher ?? '');
  final locationController = TextEditingController(
    text: session?.location ?? '',
  );
  final customWeeksController = TextEditingController(
    text: session?.customRepeatWeeks.join(', ') ?? '',
  );
  final typeController = TextEditingController(text: session?.type ?? '');

  // 下拉、筛选和开关字段使用 Rx 做局部刷新，不额外引入页面级 State。
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
              // 课程名是必填字段，也是课表卡片和详情页的主标题。
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '课程名',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              // 教师为空时保存为“未知”，保持详情展示有稳定 fallback。
              TextField(
                controller: teacherController,
                decoration: const InputDecoration(
                  labelText: '教师',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              // 地点为空时保存为 null，展示层用 scheduleValueOrFallback 处理。
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
                      // 星期决定课程进入课表的哪一列。
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
                      // 开始节改变时会自动拉齐结束节，避免出现倒置时间段。
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
                      // 结束节改变时也会自动修正开始节，确保 time 连续合法。
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
                // 半学期、单双周和线上标签共同决定课程在课表和月历中的展示条件。
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
                // 开启自定义上课周后，会用具体周次覆盖单双周过滤规则。
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
                  // 自定义周次支持逗号、中文逗号和空白分隔，解析逻辑在 _parseCustomWeeks。
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
                // 课程类型为可选展示字段，不参与日期过滤或网格布局。
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
            // 表单校验只检查必要边界，避免保存无法显示或无重复规则的课程。
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

            // 将起止节转换为连续节次数组，课表布局服务依赖这个列表定位卡片。
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
              // 新增课程由 Controller 补 id 并写入当前学期。
              await controller.addSession(scheduleSession);
            } else {
              // 编辑课程保留原 id，只替换当前学期中的对应 session。
              await controller.updateSession(scheduleSession);
            }
            Get.back();
          },
          child: Text(session == null ? '添加' : '保存'),
        ),
      ],
    ),
  ).whenComplete(() {
    // 释放所有文本控制器，防止多次打开弹窗后泄漏。
    nameController.dispose();
    teacherController.dispose();
    locationController.dispose();
    customWeeksController.dispose();
    typeController.dispose();
  });
}

/// 构建 1-13 节的下拉选项。
List<DropdownMenuItem<int>> _sectionItems() {
  return List.generate(
    13,
    (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}')),
  );
}

/// 解析自定义上课周输入。
///
/// 支持英文逗号、中文逗号和空白分隔；无效项会被忽略，结果去重并排序。
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
