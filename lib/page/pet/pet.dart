import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            _AnimatedPetSprite(controller: controller, pet: pet),
            _PetFeedbackOverlay(controller: controller, pet: pet),
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
    with TickerProviderStateMixin {
  static const String _spritePath =
      'lib/assets/images/pet/cat_orange_spritesheet.png';
  static const int _frameSize = 128;
  static const int _frameCount = 4;
  static const Map<PetAction, int> _actionRows = {
    PetAction.idle: 0,
    PetAction.pet: 2,
    PetAction.feed: 3,
    PetAction.sleep: 4,
  };

  late final AnimationController _idleController;
  late final AnimationController _walkController;
  Timer? _frameTimer;
  ui.Image? _spriteImage;
  int _frameIndex = 0;
  bool _facingLeft = false;
  PetAction _lastAction = PetAction.idle;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )
      ..addStatusListener(_handleWalkStatus)
      ..repeat(reverse: true);
    _loadSprite();
    _startFrameTimer();
  }

  @override
  void didUpdateWidget(covariant _AnimatedPetSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    _idleController.duration = widget.pet.isSleeping
        ? const Duration(milliseconds: 2600)
        : const Duration(milliseconds: 1600);
    if (!_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
    if (widget.pet.isSleeping) {
      _walkController.stop();
    } else if (!_walkController.isAnimating) {
      _walkController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _walkController.removeStatusListener(_handleWalkStatus);
    _idleController.dispose();
    _walkController.dispose();
    _spriteImage?.dispose();
    super.dispose();
  }

  Future<void> _loadSprite() async {
    final data = await rootBundle.load(_spritePath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _spriteImage = frame.image);
  }

  void _startFrameTimer() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _frameIndex = (_frameIndex + 1) % _frameCount);
    });
  }

  void _handleWalkStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward && _facingLeft) {
      setState(() => _facingLeft = false);
    } else if (status == AnimationStatus.reverse && !_facingLeft) {
      setState(() => _facingLeft = true);
    }
  }

  void _syncFrameAction(PetAction action) {
    if (_lastAction != action) {
      _lastAction = action;
      _frameIndex = 0;
    }
  }

  void _syncWalkMotion() {
    if (widget.pet.isSleeping && _walkController.isAnimating) {
      _walkController.stop();
    } else if (!widget.pet.isSleeping && !_walkController.isAnimating) {
      _walkController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final action = widget.controller.action.value;
      _syncWalkMotion();
      _syncFrameAction(action);
      return LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: Listenable.merge([_idleController, _walkController]),
            builder: (context, child) {
              final image = _spriteImage;
              final idleLift = widget.pet.isSleeping
                  ? 1.5 * _idleController.value
                  : 5 * _idleController.value;
              final actionBounce = action == PetAction.pet ||
                      action == PetAction.feed
                  ? -12.0
                  : 0.0;
              final walkRange = (constraints.maxWidth - 176)
                  .clamp(0, 96)
                  .toDouble();
              final walkOffset = widget.pet.isSleeping
                  ? 0.0
                  : (walkRange * (_walkController.value - 0.5));
              final row = widget.pet.isSleeping
                  ? _actionRows[PetAction.sleep]!
                  : action == PetAction.idle
                      ? 1
                      : _actionRows[action] ?? 1;

              return Transform.translate(
                offset: Offset(walkOffset, actionBounce - idleLift),
                child: Transform.scale(
                  scaleX: _facingLeft ? -1 : 1,
                  child: image == null
                      ? const SizedBox(width: 176, height: 176)
                      : CustomPaint(
                          size: const Size(176, 176),
                          painter: _SpriteSheetPainter(
                            image: image,
                            row: row,
                            frame: _frameIndex,
                            frameSize: _frameSize,
                          ),
                        ),
                ),
              );
            },
          );
        },
      );
    });
  }
}

class _PetFeedbackOverlay extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const _PetFeedbackOverlay({required this.controller, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final action = controller.action.value;
      if (pet.isSleeping) {
        return const Positioned(
          top: 48,
          right: 76,
          child: _FloatingFeedback(
            icon: Icons.nights_stay,
            color: Colors.indigoAccent,
            label: 'Z',
          ),
        );
      }

      if (action == PetAction.pet) {
        return const Positioned(
          top: 58,
          right: 82,
          child: _FloatingFeedback(
            icon: Icons.favorite,
            color: Colors.pinkAccent,
          ),
        );
      }

      if (action == PetAction.feed) {
        return const Positioned(
          bottom: 72,
          right: 78,
          child: _FloatingFeedback(
            icon: Icons.rice_bowl,
            color: Colors.orange,
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }
}

class _FloatingFeedback extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String? label;

  const _FloatingFeedback({
    required this.icon,
    required this.color,
    this.label,
  });

  @override
  State<_FloatingFeedback> createState() => _FloatingFeedbackState();
}

class _FloatingFeedbackState extends State<_FloatingFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, 10),
      end: const Offset(0, -22),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: widget.label == null
              ? Icon(widget.icon, color: widget.color, size: 22)
              : Text(
                  widget.label!,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
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

class _SpriteSheetPainter extends CustomPainter {
  final ui.Image image;
  final int row;
  final int frame;
  final int frameSize;

  _SpriteSheetPainter({
    required this.image,
    required this.row,
    required this.frame,
    required this.frameSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      frame * frameSize.toDouble(),
      row * frameSize.toDouble(),
      frameSize.toDouble(),
      frameSize.toDouble(),
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    canvas.drawImageRect(image, src, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _SpriteSheetPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.row != row ||
        oldDelegate.frame != frame ||
        oldDelegate.frameSize != frameSize;
  }
}
