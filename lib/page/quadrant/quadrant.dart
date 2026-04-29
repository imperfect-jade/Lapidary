// lib/page/quadrant_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/task_controller.dart';

class QuadrantPage extends StatelessWidget {
  const QuadrantPage({super.key});

  // 象限配置
  static const _quadrants = [
    _QuadrantConfig(
      title: '重要且紧急',
      subtitle: '立刻做',
      priority: 1,
      color: Colors.red,
      icon: Icons.priority_high,
    ),
    _QuadrantConfig(
      title: '重要不紧急',
      subtitle: '计划做',
      priority: 2,
      color: Colors.orange,
      icon: Icons.event_note,
    ),
    _QuadrantConfig(
      title: '紧急不重要',
      subtitle: '快速做',
      priority: 3,
      color: Colors.blue,
      icon: Icons.speed,
    ),
    _QuadrantConfig(
      title: '不重要不紧急',
      subtitle: '尽量少做',
      priority: 4,
      color: Colors.grey,
      icon: Icons.low_priority,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TaskController>();

    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        title: const Text('四象限'),
      ),

      body: Obx(() {
        final pendingTasks = controller.pendingTasks;

        return Column(
          children: [
            // 顶部提示
            _buildSummary(pendingTasks),
            const SizedBox(height: 8),
            // 四象限网格
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuadrant(
                              _quadrants[0], pendingTasks, controller
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuadrant(
                              _quadrants[1], pendingTasks, controller
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuadrant(
                              _quadrants[2], pendingTasks, controller
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuadrant(
                              _quadrants[3], pendingTasks, controller
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // 顶部统计
  Widget _buildSummary(List<TaskModel> pendingTasks) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _quadrants.map((q) {
          final count = pendingTasks
            .where((t) => t.priority == q.priority).length;
          return _miniStat(q.color, '${q.title}', '$count');
        }).toList(),
      ),
    );
  }
  // 小统计项
  Widget _miniStat(Color color, String label, String count) {
    return Column(
      children: [
        Text(count, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  // 单个象限
  Widget _buildQuadrant(
    _QuadrantConfig config,
    List<TaskModel> allTasks,
    TaskController controller,
  ) {
    final tasks = allTasks
        .where((t) => t.priority == config.priority)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 象限标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(config.icon, size: 16, color: config.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: config.color,
                        ),
                      ),
                      Text(config.subtitle,
                        style: TextStyle(
                          fontSize: 10, color: config.color.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                // 任务数角标
                if (tasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: config.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${tasks.length}',
                      style: const TextStyle(
                        fontSize: 10, color: Colors.white)),
                  ),
              ],
            ),
          ),
          // 任务列表
          Expanded(
            child: tasks.isEmpty
              ? Center(
                  child: Text('暂无任务',
                    style: TextStyle(
                      fontSize: 12, color: Colors.grey[400])),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskItem(task, controller, config.color);
                  },
                ),
          ),
        ],
      ),
    );
  }

  // 单个任务卡片
  Widget _buildTaskItem(
    TaskModel task, TaskController controller, Color accentColor
  ) {
    return GestureDetector(
      onTap: () => _showTaskDetail(task, controller),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 完成按钮
            GestureDetector(
              onTap: () => controller.updateTaskStatus(task),
              child: Icon(
                task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
                size: 18,
                color: task.isCompleted ? accentColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 6),
            // 任务标题
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                  color: task.isCompleted ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            // 截止日期
            Text(
               _formatDate(task.deadline),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // 任务详情弹窗
  void _showTaskDetail(TaskModel task, TaskController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    controller.deleteTask(task);
                    Get.back();
                  },
                ),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: 8),
              Text(task.description!, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('优先级：${_quadrants[task.priority - 1].title}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('截止：${_formatDate(task.deadline)}'),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.updateTaskStatus(task);
                  Get.back();
                },
                child: Text(task.isCompleted ? '标记未完成' : '标记完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

// 象限配置类
class _QuadrantConfig {
  final String title;
  final String subtitle;
  final int priority;
  final Color color;
  final IconData icon;

  const _QuadrantConfig({
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.color,
    required this.icon,
  });
}
