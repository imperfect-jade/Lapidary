import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/task/task_controller.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/constants/task_priority.dart';

class TaskPage extends StatelessWidget {
  TaskPage({Key? key}) : super(key: key);

  final TaskController controller = Get.find<TaskController>();
  // 创建任务详情弹窗
  void _showTaskDetailDialog(TaskModel task) {
    final priority = taskPriorityOf(task.priority);
    Get.dialog(
      AlertDialog(
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // 完成状态
              Row(
                children: [
                  const Text(
                    '完成状态: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.isCompleted ? '已完成' : '待完成',
                      style: TextStyle(
                        color: task.isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 截止日期
              const Text(
                '截止日期:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(task.deadline.toLocal().toString().split(' ')[0]),
              const SizedBox(height: 12),
              // 创建时间
              const Text(
                '创建时间:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(task.createdAt.toLocal().toString().split(' ')[0]),
              const SizedBox(height: 12),

              // 优先级
              const Text('优先级:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(
                priority.label,
                style: TextStyle(
                  color: priority.color,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),
              // 完整描述
              if (task.description != null && task.description!.isNotEmpty) ...[
                const Text(
                  '任务描述:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(task.description!),
              ] else ...[
                const Text('暂无描述'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
        ],
      ),
    );
  }

  //创建添加任务弹窗
  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final selectedPriority = 3.obs; // 默认选中"重要不紧急"
    final selectedDate = DateTime.now().obs;

    Get.dialog(
      AlertDialog(
        title: const Text('添加任务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 任务标题输入框
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '任务标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 任务描述输入框
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '任务描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // 优先级下拉选择
            Row(
              children: [
                // 左侧优先级文本
                const Expanded(
                  flex: 2,
                  child: Text(
                    '优先级:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                // 右侧优先级下拉选择
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        //左侧返回选择结果
                        Expanded(
                          child: Center(
                            child: Obx(() {
                              // 遍历列表查找当前选中的优先级
                              final option = taskPriorityOf(
                                selectedPriority.value,
                              );
                              return Text(
                                option.label,
                                style: TextStyle(
                                  color: option.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }),
                          ),
                        ),
                        // 右侧下拉选择按钮
                        PopupMenuButton<int>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (value) {
                            selectedPriority.value = value; // 更新选中的优先级
                          },
                          itemBuilder: (context) => taskPriorityOptions.map((
                            option,
                          ) {
                            return PopupMenuItem<int>(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 选择完成日期按钮
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: Get.context!,
                  initialDate: selectedDate.value,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate.value = date;
                }
              },
              child: Obx(
                () => Text(
                  '选择完成日期: ${selectedDate.value.toLocal().toString().split(' ')[0]}',
                ),
              ),
            ),
          ],
        ),
        // 添加按钮
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                controller.addTask(
                  titleController.text,
                  selectedDate.value,
                  priority: selectedPriority.value,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                );
                Get.back();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  //创建任务列表页面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 清新浅蓝色背景
      backgroundColor: TaskTheme.primaryColor,
      //页面头部标题
      appBar: AppBar(
        title: const Text('我的任务'),
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GetBuilder<TaskController>(
        id: 'task_list',
        builder: (controller) {
          final tasks = controller.sortedTasks;
          //判断是否有任务
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                '暂无任务',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          //具体任务列表
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return GetBuilder<TaskController>(
                id: 'task_${task.id}',
                builder: (controller) => _buildTaskCard(task),
              );
            },
          );
        },
      ),
      //浮动添加任务按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showTaskDetailDialog(task),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            controller.updateTaskStatus(task);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              '创建时间: ${task.createdAt.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            Get.dialog(
              AlertDialog(
                title: const Text('删除任务'),
                content: const Text('确定要删除这个任务吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.deleteTask(task);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('删除'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
