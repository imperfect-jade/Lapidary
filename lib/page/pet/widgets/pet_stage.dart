import 'package:flutter/material.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

import '../sprite/animated_pet_sprite.dart';
import '../sprite/sprite_feedback.dart';

/// 宠物主舞台，展示像素精灵、地面阴影和局部漂浮反馈。
///
/// 舞台由 `PetController.action` 驱动动画；用户点击整块区域会调用 `petCat()`，
/// 由 Controller 负责修改宠物数值、保存并触发反馈。
class PetStage extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const PetStage({super.key, required this.controller, required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 点击舞台等同于抚摸宠物，UI 层不直接修改 mood/energy。
      onTap: controller.petCat,
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 246, 251, 255),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 底部阴影用于承托像素宠物，随精灵动画保持固定，不参与交互。
            Positioned(
              bottom: 42,
              child: Container(
                width: 190,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            // 主精灵负责帧动画、待机随机动作和睡眠状态展示。
            AnimatedPetSprite(controller: controller, pet: pet),
            // 局部反馈只在宠物页内显示，例如爱心、星星、睡眠 Z。
            PetFeedbackOverlay(controller: controller, pet: pet),
          ],
        ),
      ),
    );
  }
}
