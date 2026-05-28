import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/task_priority.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/task_controller.dart';

/// 四象限页面，用任务优先级把未完成任务分成四个决策区域。
///
/// 页面不持有独立任务状态，也不直接读写 Hive；任务数据来自
/// `TaskController.pendingTasksForPriority()`，完成和删除操作统一委托任务控制器。
class QuadrantPage extends StatelessWidget {
  const QuadrantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 页面骨架只提供四象限视图容器，颜色沿用全局任务主题。
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        title: const Text('四象限'),
      ),

      body: GetBuilder<TaskController>(
        // TaskController 在任务增删改、完成状态变化和逾期检查后会刷新 quadrant id。
        id: 'quadrant',
        builder: (controller) {
          return Column(
            children: [
              // 顶部统计区显示每个象限当前未完成任务数量，帮助快速判断任务压力。
              _buildSummary(controller),
              const SizedBox(height: 8),
              // 四象限网格按固定优先级顺序展示：重要且紧急、紧急不重要、重要不紧急、不重要不紧急。
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
                                taskPriorityOptions[0],
                                controller,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuadrant(
                                taskPriorityOptions[1],
                                controller,
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
                                taskPriorityOptions[2],
                                controller,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildQuadrant(
                                taskPriorityOptions[3],
                                controller,
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
        },
      ),
    );
  }

  /// 构建顶部四个象限的任务数量统计。
  ///
  /// 统计只读取未完成任务缓存，不会触发持久化或任务状态变更。
  Widget _buildSummary(TaskController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: taskPriorityOptions.map((q) {
          // 每个统计项和下面对应象限使用同一份 TaskPriorityOption 配置。
          final count = controller.pendingTasksForPriority(q.value).length;
          return _miniStat(q.color, q.label, '$count');
        }).toList(),
      ),
    );
  }

  /// 顶部单个小统计项，展示象限名称和未完成数量。
  Widget _miniStat(Color color, String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  /// 构建单个象限面板。
  ///
  /// 面板的颜色、图标、标题和副标题来自 `TaskPriorityOption`；
  /// 任务列表只展示该优先级下的未完成任务。
  Widget _buildQuadrant(TaskPriorityOption config, TaskController controller) {
    // 四象限只关注待完成任务，已完成任务会从这里移出但仍保留在任务模块中。
    final tasks = controller.pendingTasksForPriority(config.value);

    return Container(
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 象限标题区展示优先级名称、处理建议和当前数量角标。
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(config.icon, size: 16, color: config.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: config.color,
                        ),
                      ),
                      Text(
                        config.subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: config.color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // 任务数角标只在当前象限存在任务时显示，减少空象限视觉噪音。
                if (tasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: config.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          // 任务列表区：空象限展示空状态，有任务时用紧凑卡片列表展示。
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      '暂无任务',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
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

  /// 构建象限内的单个任务卡片。
  ///
  /// 卡片点击打开详情 Sheet；左侧完成按钮调用 `TaskController.updateTaskStatus()`，
  /// 因此奖励、宠物反馈和跨页面刷新仍沿用任务模块既有流程。
  Widget _buildTaskItem(
    TaskModel task,
    TaskController controller,
    Color accentColor,
  ) {
    return GestureDetector(
      // 点击卡片空白处查看任务详情，不在这里直接编辑任务字段。
      onTap: () => _showTaskDetail(task, controller),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 完成按钮只切换任务状态，持久化、奖励和刷新由 TaskController 处理。
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
            // 任务标题保持单行省略，避免紧凑象限卡片被长标题撑开。
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
            // 截止时间使用四象限专用的紧凑格式，方便小卡片快速扫描。
            Text(
              _formatDateTime(task.deadline),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示任务详情底部 Sheet。
  ///
  /// 详情展示标题、描述、优先级和截止时间，并提供删除和完成/取消完成操作；
  /// 这些操作都委托给 `TaskController`，页面层不直接处理持久化。
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
            // 顶部标题行展示任务名和删除入口。
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // 删除任务后 TaskController 会刷新任务页、四象限和日历。
                    controller.deleteTask(task);
                    Get.back();
                  },
                ),
              ],
            ),
            if (task.description != null) ...[
              // 有描述时展示任务补充信息，空描述不占用空间。
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            // 优先级行复用统一配置，避免页面内硬编码四象限标签。
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('优先级：${taskPriorityOf(task.priority).label}'),
              ],
            ),
            const SizedBox(height: 4),
            // 截止时间行使用与卡片一致的紧凑格式。
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('截止：${_formatDateTime(task.deadline)}'),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 完成切换仍走任务控制器，保持奖励、宠物反馈和缓存刷新一致。
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

  /// 将日期格式化为四象限卡片/详情使用的紧凑时间。
  ///
  /// 该格式只用于展示，不改变任务的 deadline。
  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day} ${_two(date.hour)}:${_two(date.minute)}';
  }

  /// 将小时或分钟补齐为两位数字。
  String _two(int value) => value.toString().padLeft(2, '0');
}
