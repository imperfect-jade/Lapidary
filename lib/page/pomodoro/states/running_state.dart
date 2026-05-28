import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/pet/widgets/pet_focus_companion_card.dart';

import '../pomodoro_controller.dart';
import '../widgets/motivation_quote_ticker.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_panel.dart';

/// 番茄钟运行态页面内容。
///
/// 展示励志语、倒计时进度、任务信息、宠物陪伴卡和暂停/放弃控制按钮。
class PomodoroRunningState extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroRunningState({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final compact = availableHeight < 620;
        final tight = availableHeight < 560;
        final horizontalPadding = compact ? 16.0 : 24.0;
        final verticalPadding = tight ? 10.0 : (compact ? 14.0 : 24.0);
        final quoteGap = tight ? 8.0 : (compact ? 10.0 : 14.0);
        final petBottomGap = tight ? 10.0 : (compact ? 12.0 : 16.0);
        final timerGap = tight ? 12.0 : (compact ? 16.0 : 24.0);
        final controlsGap = tight ? 16.0 : (compact ? 22.0 : 32.0);
        final contentWidth = (availableWidth - horizontalPadding * 2)
            .clamp(0.0, 420.0)
            .toDouble();

        // 运行态保持固定页面，不再使用滚动容器；极小高度下整体等比缩小以避免溢出。
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 励志语区：运行时轮播文案，给专注过程提供轻量陪伴。
                    const PomodoroMotivationQuoteTicker(),
                    Obx(() {
                      if (controller.currentMode.value != 'focus') {
                        return SizedBox(height: quoteGap);
                      }
                      // 宠物陪伴卡只在专注模式显示；独立“专注中/休息中”标签已移除。
                      return Padding(
                        padding: EdgeInsets.only(
                          top: quoteGap,
                          bottom: petBottomGap,
                        ),
                        child: PetFocusCompanionCard(
                          taskTitle: controller.currentTaskTitle.value,
                        ),
                      );
                    }),
                    // 倒计时进度区：显示剩余时间和环形进度，点击可调整时长。
                    PomodoroTimerProgress(controller: controller),
                    SizedBox(height: timerGap),
                    // 当前任务信息区：显示关联任务标题，没有任务时显示自由专注。
                    PomodoroRunningTaskInfo(controller: controller),
                    SizedBox(height: controlsGap),
                    // 控制按钮区：根据暂停状态切换暂停/继续，并提供放弃入口。
                    PomodoroTimerControls(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
