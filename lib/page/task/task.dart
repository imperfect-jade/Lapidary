import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/dialogs/add_task_dialog.dart';
import 'package:todolist/page/task/dialogs/task_detail_dialog.dart';
import 'package:todolist/page/task/task_controller.dart';
import 'package:todolist/page/task/widgets/task_card.dart';
import 'package:todolist/page/task/widgets/task_type_filter.dart';

/// 待办任务页，负责展示任务筛选、任务列表和新增任务入口。
///
/// 页面只处理展示和交互入口，任务持久化、缓存和跨模块通知统一交给 [TaskController]。
class TaskPage extends StatelessWidget {
  TaskPage({super.key});

  final TaskController controller = Get.find<TaskController>();

  /// 当前页面内的任务类型筛选，不写入持久化，也不影响其他页面读取任务。
  final RxnString selectedTaskType = RxnString();

  @override
  Widget build(BuildContext context) {
    // 待办页整体骨架：顶部标题、类型筛选、任务列表和新增按钮。
    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      // 顶部标题栏：只展示页面标题，不承载筛选或编辑动作。
      appBar: AppBar(
        title: const Text('我的任务'),
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 类型筛选区：由 selectedTaskType 驱动，选择后只影响当前列表显示。
          Obx(
            () => TaskTypeFilter(
              selectedType: selectedTaskType.value,
              onSelected: (value) => selectedTaskType.value = value,
            ),
          ),
          Expanded(
            // 任务列表区：读取 TaskController 的派生查询结果，并响应列表级刷新。
            child: GetBuilder<TaskController>(
              // 列表级刷新用于任务新增、删除、筛选结果变化和跨页面缓存同步。
              id: 'task_list',
              builder: (controller) {
                return Obx(() {
                  final tasks = controller.tasksForType(selectedTaskType.value);
                  if (tasks.isEmpty) {
                    // 空状态区：根据当前筛选条件展示“全部为空”或“某类型为空”。
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
                    // 列表底部预留空间，避免最后一张任务卡被悬浮新增按钮遮挡。
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return GetBuilder<TaskController>(
                        // 单卡片刷新用于完成状态、标题等局部变化，避免整页不必要重建。
                        id: 'task_${task.id}',
                        // 单任务卡片区：展示任务摘要，点击进入详情，勾选/删除交给卡片内部处理。
                        builder: (controller) => TaskCard(
                          task: task,
                          controller: controller,
                          onTap: () => showTaskDetailDialog(task),
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
        // 新增任务入口：打开表单弹窗，表单提交后由 TaskController 负责保存和刷新。
        onPressed: () => showAddTaskDialog(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}
