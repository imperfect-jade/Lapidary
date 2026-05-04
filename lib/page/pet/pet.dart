import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

//宠物页面
class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  final PetController controller = Get.find<PetController>();

  @override
  void initState() {
    super.initState();
    controller.refreshPetState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        title: const Text('像素小猫'),
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
              const SizedBox(height: 20),
              _ActionBar(controller: controller, pet: pet),
            ],
          ),
        );
      }),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _PetStage extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const _PetStage({required this.controller, required this.pet});

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
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            _AnimatedPetSprite(controller: controller, pet: pet),
          ],
        ),
      ),
    );
  }
}

class _AnimatedPetSprite extends StatefulWidget {
  final PetController controller;
  final PetModel pet;

  const _AnimatedPetSprite({required this.controller, required this.pet});

  @override
  State<_AnimatedPetSprite> createState() => _AnimatedPetSpriteState();
}

class _AnimatedPetSpriteState extends State<_AnimatedPetSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AnimatedPetSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animationController.duration = widget.pet.isSleeping
        ? const Duration(milliseconds: 2600)
        : const Duration(milliseconds: 1600);
    if (!_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final action = widget.controller.action.value;
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final idleLift = widget.pet.isSleeping
              ? 1.5 * _animationController.value
              : 7 * _animationController.value;
          final actionBounce =
              action == PetAction.pet || action == PetAction.feed ? -12.0 : 0.0;

          return Transform.translate(
            offset: Offset(0, actionBounce - idleLift),
            child: CustomPaint(
              size: const Size(168, 168),
              painter: _PixelCatPainter(
                action: action,
                species: widget.pet.species,
                animationValue: _animationController.value,
                isSleeping: widget.pet.isSleeping,
              ),
            ),
          );
        },
      );
    });
  }
}

class _GrowthPanel extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const _GrowthPanel({required this.controller, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TaskTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Lv.${pet.level}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: controller.expProgress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(TaskTheme.appBarColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '经验 ${pet.exp}/${controller.expToNextLevel}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final PetModel pet;

  const _StatusGrid({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            icon: Icons.favorite,
            label: '心情',
            value: pet.mood,
            color: Colors.pinkAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusCard(
            icon: Icons.restaurant,
            label: '饱腹',
            value: pet.hunger,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusCard(
            icon: Icons.bedtime,
            label: '精力',
            value: pet.energy,
            color: Colors.indigoAccent,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const _ActionBar({required this.controller, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.petCat,
            icon: const Icon(Icons.pan_tool_alt),
            label: const Text('抚摸'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.feed,
            icon: const Icon(Icons.rice_bowl),
            label: const Text('喂食'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.toggleSleep,
            icon: Icon(pet.isSleeping ? Icons.wb_sunny : Icons.bedtime),
            label: Text(pet.isSleeping ? '唤醒' : '睡觉'),
          ),
        ),
      ],
    );
  }
}

class _PixelCatPainter extends CustomPainter {
  final PetAction action;
  final String species;
  final double animationValue;
  final bool isSleeping;

  _PixelCatPainter({
    required this.action,
    required this.species,
    required this.animationValue,
    required this.isSleeping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (species != PetSpecies.cat) {
      return;
    }

    final pixel = size.width / 14;
    final tailLift = animationValue > 0.5 ? -1 : 0;
    final blink = !isSleeping && animationValue > 0.82;
    final body = Paint()..color = const Color.fromARGB(255, 88, 103, 118);
    final bodyDark = Paint()..color = const Color.fromARGB(255, 58, 68, 78);
    final face = Paint()..color = const Color.fromARGB(255, 245, 221, 186);
    final pink = Paint()..color = const Color.fromARGB(255, 246, 150, 169);
    final eye = Paint()..color = const Color.fromARGB(255, 26, 34, 42);
    final food = Paint()..color = const Color.fromARGB(255, 238, 156, 75);

    void px(int x, int y, Paint paint, {int w = 1, int h = 1}) {
      canvas.drawRect(
        Rect.fromLTWH(x * pixel, y * pixel, w * pixel, h * pixel),
        paint,
      );
    }

    // Tail
    px(1, 8 + tailLift, bodyDark);
    px(1, 7 + tailLift, bodyDark);
    px(2, 6 + tailLift, bodyDark);
    px(3, 6 + tailLift, bodyDark);

    // Body
    px(4, 7, body, w: 7, h: 5);
    px(5, 6, body, w: 5);
    px(5, 12, bodyDark);
    px(9, 12, bodyDark);

    // Head and ears
    px(4, 3, body, w: 7, h: 5);
    px(4, 2, bodyDark);
    px(5, 1, bodyDark);
    px(9, 1, bodyDark);
    px(10, 2, bodyDark);
    px(5, 2, pink);
    px(9, 2, pink);

    // Face
    px(5, 5, face, w: 5, h: 2);
    px(6, 4, face, w: 3);
    if (isSleeping) {
      px(5, 5, eye, w: 2);
      px(8, 5, eye, w: 2);
    } else if (blink) {
      px(5, 5, eye, w: 2);
      px(8, 5, eye, w: 2);
    } else {
      px(5, 4, eye);
      px(9, 4, eye);
      if (action == PetAction.pet) {
        px(6, 4, pink);
        px(8, 4, pink);
      }
    }
    px(7, 5, pink);
    px(6, 6, eye);
    px(8, 6, eye);

    // Paws
    px(4, 11, face);
    px(10, 11, face);

    if (action == PetAction.feed) {
      px(11, 9, food, w: 2);
      px(12, 8, food);
    }

    if (isSleeping) {
      final zPaint = Paint()
        ..color = const Color.fromARGB(255, 116, 154, 190)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(11.5 * pixel, 2.5 * pixel),
        Offset(13 * pixel, 2.5 * pixel),
        zPaint,
      );
      canvas.drawLine(
        Offset(13 * pixel, 2.5 * pixel),
        Offset(11.5 * pixel, 4 * pixel),
        zPaint,
      );
      canvas.drawLine(
        Offset(11.5 * pixel, 4 * pixel),
        Offset(13 * pixel, 4 * pixel),
        zPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PixelCatPainter oldDelegate) {
    return oldDelegate.action != action ||
        oldDelegate.species != species ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isSleeping != isSleeping;
  }
}
