import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

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
      ),
      body: Obx(() {
        final isRunning = controller.isRunning.value;
        return isRunning
            ? _RunningState(controller: controller)
            : _IdleState(
                controller: controller,
                taskController: taskController,
              );
      }),
    );
  }
}

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
              Obx(
                () => DropdownButton<int>(
                  value: controller.focusDuration.value,
                  items: [15, 25, 30, 45, 60]
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text('$v分钟')),
                      )
                      .toList(),
                  onChanged: (v) => controller.focusDuration.value = v ?? 25,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('休息时长：'),
              Obx(
                () => DropdownButton<int>(
                  value: controller.breakDuration.value,
                  items: [5, 10, 15]
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text('$v分钟')),
                      )
                      .toList(),
                  onChanged: (v) => controller.breakDuration.value = v ?? 5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('完成')),
      ],
    ),
  );
}

class _IdleState extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const _IdleState({required this.controller, required this.taskController});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              children: [
                _TodayStats(controller: controller),
                SizedBox(height: constraints.maxHeight < 620 ? 28 : 56),
                _StartCircle(controller: controller),
                const SizedBox(height: 24),
                _TaskSelector(
                  controller: controller,
                  taskController: taskController,
                ),
                const SizedBox(height: 18),
                const _PomodoroHint(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PomodoroHint extends StatelessWidget {
  const _PomodoroHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '点击任务开始专注，点击计时器调整时长',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Color.fromARGB(255, 92, 118, 140),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TimerSettingsHint extends StatelessWidget {
  const _TimerSettingsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('点击计时器设置时长', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  final Widget child;
  final bool isFocus;

  const _TimerPanel({required this.child, required this.isFocus});

  @override
  Widget build(BuildContext context) {
    final color = isFocus
        ? const Color.fromARGB(255, 239, 116, 116)
        : const Color.fromARGB(255, 89, 174, 118);
    return Container(
      width: 242,
      height: 242,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.35), width: 5),
      ),
      child: Center(child: child),
    );
  }
}

class _RunningTaskInfo extends StatelessWidget {
  final PomodoroController controller;

  const _RunningTaskInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          taskTitle == null ? '自由专注' : '当前任务：$taskTitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 76, 96, 112),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
  }
}

class _IdleTimerLabel extends StatelessWidget {
  final PomodoroController controller;

  const _IdleTimerLabel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${controller.focusDuration.value.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 44, 58, 70),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '专注 ${controller.focusDuration.value} 分钟',
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 98, 118, 136),
            ),
          ),
          const SizedBox(height: 12),
          const _TimerSettingsHint(),
        ],
      ),
    );
  }
}

class _RunningTimerLabel extends StatelessWidget {
  final PomodoroController controller;

  const _RunningTimerLabel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            controller.formattedTime,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 44, 58, 70),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.currentMode.value == 'focus' ? '专注中' : '休息中',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: controller.currentMode.value == 'focus'
                  ? Colors.red
                  : Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          const _TimerSettingsHint(),
        ],
      ),
    );
  }
}

class _TimerProgressRing extends StatelessWidget {
  final PomodoroController controller;
  final Widget child;

  const _TimerProgressRing({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      final color = isFocus ? Colors.red : Colors.green;
      return SizedBox(
        width: 258,
        height: 258,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 258,
              height: 258,
              child: CircularProgressIndicator(
                value: controller.progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.78),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            child,
          ],
        ),
      );
    });
  }
}

class _SettingsTapTarget extends StatelessWidget {
  final PomodoroController controller;
  final Widget child;

  const _SettingsTapTarget({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSettings(controller),
      child: child,
    );
  }
}

class _MotivationQuoteTicker extends StatefulWidget {
  const _MotivationQuoteTicker();

  @override
  State<_MotivationQuoteTicker> createState() => _MotivationQuoteTickerState();
}

class _MotivationQuoteTickerState extends State<_MotivationQuoteTicker> {
  static const String _assetPath = 'lib/assets/text/motivational_quotes.txt';

  Timer? _timer;
  List<String> _quotes = const [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final raw = await rootBundle.loadString(_assetPath);
    final quotes = raw
        .split(RegExp(r'\r?\n\s*\r?\n'))
        .map((quote) => quote.trim())
        .where((quote) => quote.isNotEmpty)
        .toList();
    if (!mounted) {
      return;
    }
    setState(() => _quotes = quotes);
    if (quotes.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _currentIndex = (_currentIndex + 1) % _quotes.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quotes.isEmpty
        ? '预测未来的最好方法就是去创造未来。'
        : _quotes[_currentIndex];
    return Container(
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(
            255,
            238,
            181,
            105,
          ).withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(
              255,
              197,
              122,
              46,
            ).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 225, 143, 63),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 520),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: Text(
                  quote,
                  key: ValueKey(quote),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'MaShanZheng',
                    color: Color.fromARGB(255, 197, 113, 43),
                    fontSize: 20,
                    height: 1.20,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: Color.fromARGB(34, 124, 73, 24),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningState extends StatelessWidget {
  final PomodoroController controller;

  const _RunningState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _MotivationQuoteTicker(),
                const SizedBox(height: 24),
                _ModeLabel(controller: controller),
                const SizedBox(height: 18),
                _TimerProgress(controller: controller),
                const SizedBox(height: 24),
                _RunningTaskInfo(controller: controller),
                const SizedBox(height: 36),
                _TimerControls(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayStats extends StatelessWidget {
  final PomodoroController controller;

  const _TodayStats({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCard('今日专注', '${controller.todayFocusMinutes.value}分钟'),
          _statCard('完成番茄', '${controller.todayPomodoroCount.value}个'),
        ],
      );
    });
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSelector extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const _TaskSelector({required this.controller, required this.taskController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      if (taskTitle != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.task_alt, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Flexible(child: Text('当前任务：$taskTitle')),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  controller.currentTaskId.value = null;
                  controller.currentTaskTitle.value = null;
                },
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return OutlinedButton.icon(
        onPressed: () => _showTaskPicker(controller, taskController),
        icon: const Icon(Icons.add_task),
        label: const Text('选择要专注的任务（可选）'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}

class _StartCircle extends StatelessWidget {
  final PomodoroController controller;

  const _StartCircle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return _SettingsTapTarget(
        controller: controller,
        child: _TimerPanel(
          isFocus: isFocus,
          child: _IdleTimerLabel(controller: controller),
        ),
      );
    });
  }
}

class _ModeLabel extends StatelessWidget {
  final PomodoroController controller;

  const _ModeLabel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return Text(
        isFocus ? '专注中' : '休息中',
        style: TextStyle(
          fontSize: 20,
          color: isFocus ? Colors.red : Colors.green,
        ),
      );
    });
  }
}

class _TimerProgress extends StatelessWidget {
  final PomodoroController controller;

  const _TimerProgress({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return _SettingsTapTarget(
        controller: controller,
        child: _TimerProgressRing(
          controller: controller,
          child: _TimerPanel(
            isFocus: isFocus,
            child: _RunningTimerLabel(controller: controller),
          ),
        ),
      );
    });
  }
}

class _TimerControls extends StatelessWidget {
  final PomodoroController controller;

  const _TimerControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!controller.isPaused.value)
            ElevatedButton.icon(
              onPressed: controller.pause,
              icon: const Icon(Icons.pause),
              label: const Text('暂停'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: controller.resume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('继续'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: controller.giveUp,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              foregroundColor: Colors.red,
            ),
            child: const Text('放弃'),
          ),
        ],
      );
    });
  }
}

void _showTaskPicker(
  PomodoroController controller,
  TaskController taskController,
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
          const Text(
            '选择任务',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...taskController.pendingTasks.map(
            (task) => ListTile(
              title: Text(task.title),
              onTap: () {
                controller.currentTaskId.value = task.id;
                controller.currentTaskTitle.value = task.title;
                controller.startFocus(taskId: task.id, taskTitle: task.title);
                Get.back();
              },
            ),
          ),
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
