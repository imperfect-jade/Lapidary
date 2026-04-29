import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/task/task_controller.dart';
import 'package:todolist/constants/theme.dart';
//番茄钟页面

class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PomodoroController>();
    final taskController = Get.find<TaskController>();
    
    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        title: const Text('番茄钟'),
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(controller),
          ),
        ],
      ),
      body: Obx(() => _buildBody(controller, taskController)),
    );
  }
  // 构建主体
  Widget _buildBody(PomodoroController controller, TaskController taskController) {
    if (!controller.isRunning.value) {
      // 未开始状态
      return _buildIdleState(controller, taskController);
    } else {
      // 计时中状态
      return _buildRunningState(controller);
    }
  }
  
  // 空闲状态
  Widget _buildIdleState(PomodoroController controller, TaskController taskController) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // 今日统计
          _buildTodayStats(controller),
          const SizedBox(height: 48),
          
          // 选择任务
          _buildTaskSelector(controller, taskController),
          const SizedBox(height: 48),
          
          // 开始按钮
          GestureDetector(
            onTap: () => _showTaskPicker(controller, taskController),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.currentMode.value == 'focus' 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
                border: Border.all(
                  color: controller.currentMode.value == 'focus' 
                    ? Colors.red 
                    : Colors.green,
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  '${controller.focusDuration.value}:00',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('点击上方开始专注', 
              style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 138, 160, 12), fontWeight: FontWeight.bold),
            ),
          ),
          
        ],
      ),
    );
  }
  
  // 计时中状态
  Widget _buildRunningState(PomodoroController controller) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 模式标识
          Text(
            controller.currentMode.value == 'focus' ? '专注中' : '休息中',
            style: TextStyle(
              fontSize: 20,
              color: controller.currentMode.value == 'focus' 
                ? Colors.red 
                : Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          
          // 关联任务
          if (controller.currentTaskTitle.value != null)
            Text(
              '当前任务：${controller.currentTaskTitle.value}',
              style: const TextStyle(fontSize: 16),
            ),
          const SizedBox(height: 32),
          
          // 圆形进度
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: controller.progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    controller.currentMode.value == 'focus' 
                      ? Colors.red 
                      : Colors.green,
                  ),
                ),
              ),
              Text(
                controller.formattedTime,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!controller.isPaused.value)
                ElevatedButton.icon(
                  onPressed: controller.pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('暂停'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: controller.resume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('继续'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  ),
                ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: controller.giveUp,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                  foregroundColor: Colors.red,
                ),
                child: const Text('放弃'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 今日统计
  Widget _buildTodayStats(PomodoroController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statCard('今日专注', '${controller.todayFocusMinutes.value}分钟'),
        _statCard('完成番茄', '${controller.todayPomodoroCount.value}个'),
      ],
    );
  }
  // 统计卡片
  Widget _statCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  
  // 任务选择器
  Widget _buildTaskSelector(
    PomodoroController controller, 
    TaskController taskController
  ) {
    return Obx(() {
      // final pendingTasks = taskController.pendingTasks;
      
      if (controller.currentTaskTitle.value != null) {
        return Chip(
          label: Text('当前任务：${controller.currentTaskTitle.value}'),
          onDeleted: () {
            controller.currentTaskId.value = null;
            controller.currentTaskTitle.value = null;
          },
        );
      }
      
      return TextButton.icon(
        onPressed: () => _showTaskPicker(controller, taskController),
        icon: const Icon(Icons.add_task),
        label: const Text('选择要专注的任务（可选）'),
      );
    });
  }
  
  // 任务选择弹窗
  void _showTaskPicker(
    PomodoroController controller, 
    TaskController taskController
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择任务', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...taskController.pendingTasks.map((task) => ListTile(
              title: Text(task.title),
              onTap: () {
                controller.currentTaskId.value = task.id;
                controller.currentTaskTitle.value = task.title;
                controller.startFocus(taskId: task.id, taskTitle: task.title);
                Get.back();
              },
            )),
            ListTile(
              title: const Text('自由专注（不关联任务）'),
              onTap: () {
                controller.startFocus();
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // 设置弹窗
  void _showSettings(PomodoroController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('番茄钟设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('专注时长：'),
                Obx(() => DropdownButton<int>(
                  value: controller.focusDuration.value,
                  items: [15, 25, 30, 45, 60].map((v) => 
                    DropdownMenuItem(value: v, child: Text('$v分钟'))
                  ).toList(),
                  onChanged: (v) => controller.focusDuration.value = v ?? 25,
                )),
              ],
            ),
            Row(
              children: [
                const Text('休息时长：'),
                Obx(() => DropdownButton<int>(
                  value: controller.breakDuration.value,
                  items: [5, 10, 15].map((v) => 
                    DropdownMenuItem(value: v, child: Text('$v分钟'))
                  ).toList(),
                  onChanged: (v) => controller.breakDuration.value = v ?? 5,
                )),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}