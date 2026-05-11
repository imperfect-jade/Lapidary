import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/task_priority.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/task_controller.dart';

part 'dialogs/add_task_dialog.dart';
part 'dialogs/task_detail_dialog.dart';
part 'utils/formatters.dart';
part 'widgets/task_card.dart';
part 'widgets/task_chips.dart';
part 'widgets/task_form_fields.dart';
part 'widgets/task_type_filter.dart';

class TaskPage extends StatelessWidget {
  TaskPage({super.key});

  final TaskController controller = Get.find<TaskController>();
  final RxnString selectedTaskType = RxnString();

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
                        builder: (controller) => _TaskCard(
                          task: task,
                          controller: controller,
                          onTap: () => _showTaskDetailDialog(task),
                        ),
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
        onPressed: () => _showAddTaskDialog(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}
