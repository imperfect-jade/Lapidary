import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet_diary/pet_diary_page.dart';
import 'package:todolist/page/pet/reward_controller.dart';

import 'widgets/action_bar.dart';
import 'widgets/growth_panel.dart';
import 'widgets/message_bubble.dart';
import 'widgets/pet_stage.dart';
import 'widgets/reward_shop_panel.dart';
import 'widgets/status_grid.dart';

/// 像素宠物页入口，负责组合宠物主舞台、状态、操作和奖励商城。
///
/// 页面只通过已注册的 `PetController` / `RewardController` 获取状态和调用公开 API，
/// 不直接处理 Hive 读写、奖励计算或宠物数值规则，便于后续扩展装扮和自定义宠物。
class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  // 页面层依赖全局注册的控制器：宠物控制器驱动展示和交互，奖励控制器提供积分和库存。
  final PetController controller = Get.find<PetController>();
  final RewardController rewardController = Get.find<RewardController>();
  @override
  void initState() {
    super.initState();
    // 进入页面时主动刷新一次离线衰减/睡眠恢复，避免展示上次打开时的旧状态。
    unawaited(controller.refreshPetState());
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final bodyFontFamily = Get.find<ThemeController>().currentBodyFontFamily;
    // 宠物页沿用全局字体设置，但只覆盖本页主题，不影响其他 Tab。
    final petTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: bodyFontFamily),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontFamily: bodyFontFamily,
      ),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
          fontFamily: bodyFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
    return Theme(
      data: petTheme,
      child: Scaffold(
        backgroundColor: TaskTheme.primaryColor,
        appBar: AppBar(
          title: const Text('像素宠物'),
          centerTitle: true,
          backgroundColor: TaskTheme.appBarColor,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: '宠物日记',
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => Get.to(() => const PetDiaryPage()),
            ),
          ],
        ),
        body: Obx(() {
          // 宠物模型由 Controller 异步加载；加载完成前只显示等待态，不触发任何交互。
          final pet = controller.pet.value;
          if (pet == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 顶部消息气泡展示当前状态/操作反馈，由 PetController.message 响应式驱动。
                PetMessageBubble(message: controller.message.value),
                const SizedBox(height: 18),
                // 主舞台展示精灵动画和局部反馈，点击舞台会调用 controller.petCat()。
                PetStage(controller: controller, pet: pet),
                const SizedBox(height: 18),
                // 成长面板展示名称、等级和经验进度，经验阈值由 PetStateService 计算。
                PetGrowthPanel(controller: controller, pet: pet),
                const SizedBox(height: 14),
                // 三项状态网格只读展示心情、饱腹和精力，不在 UI 层修改数值。
                PetStatusGrid(pet: pet),
                const SizedBox(height: 14),
                // 操作栏负责抚摸、喂食入口和睡眠切换，所有实际变更委托给 Controller。
                PetActionBar(
                  controller: controller,
                  pet: pet,
                  rewardController: rewardController,
                ),
                const SizedBox(height: 14),
                // 商城区块依赖奖励钱包积分和库存，购买成功后由 RewardController 持久化。
                PetRewardShopPanel(
                  petController: controller,
                  rewardController: rewardController,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
