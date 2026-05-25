import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';

part 'sprite/animated_pet_sprite.dart';
part 'sprite/sprite_feedback.dart';
part 'sprite/sprite_models.dart';
part 'sprite/pet_sprite_cache.dart';
part 'sprite/sprite_placeholder.dart';
part 'sprite/sprite_sheet_painter.dart';
part 'widgets/action_bar.dart';
part 'widgets/food_picker_sheet.dart';
part 'widgets/growth_panel.dart';
part 'widgets/message_bubble.dart';
part 'widgets/pet_stage.dart';
part 'widgets/pet_global_feedback_overlay.dart';
part 'widgets/reward_shop_panel.dart';
part 'widgets/status_grid.dart';

// 像素宠物页面
class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  final PetController controller = Get.find<PetController>();
  final RewardController rewardController = Get.find<RewardController>();

  @override
  void initState() {
    super.initState();
    controller.refreshPetState();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final bodyFontFamily = Get.find<ThemeController>().currentBodyFontFamily;
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
        ),
        body: Obx(() {
          final pet = controller.pet.value;
          if (pet == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _MessageBubble(message: controller.message.value),
                const SizedBox(height: 18),
                _PetStage(controller: controller, pet: pet),
                const SizedBox(height: 18),
                _GrowthPanel(controller: controller, pet: pet),
                const SizedBox(height: 14),
                _StatusGrid(pet: pet),
                const SizedBox(height: 14),
                _ActionBar(
                  controller: controller,
                  pet: pet,
                  rewardController: rewardController,
                ),
                const SizedBox(height: 14),
                _RewardShopPanel(
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
