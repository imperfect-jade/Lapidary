import 'package:flutter/material.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

import '../sprite/animated_pet_sprite.dart';
import '../sprite/sprite_feedback.dart';

class PetStage extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const PetStage({super.key, required this.controller, required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            AnimatedPetSprite(controller: controller, pet: pet),
            PetFeedbackOverlay(controller: controller, pet: pet),
          ],
        ),
      ),
    );
  }
}
