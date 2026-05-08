import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';

//宠物页面
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
    return Scaffold(
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
  bool _spriteLoadFailed = false;
  int _frameIndex = 0;
  bool _facingLeft = false;
  PetAction _lastAction = PetAction.idle;
  String? _loadedSpecies;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _walkController =
        AnimationController(
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
    if (oldWidget.pet.species != widget.pet.species) {
      _loadSprite();
    }
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
    final species = widget.pet.species;
    final spritePath = _spritePathForSpecies(species);
    try {
      final data = await rootBundle.load(spritePath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      _spriteImage?.dispose();
      setState(() {
        _spriteImage = frame.image;
        _spriteLoadFailed = false;
        _loadedSpecies = species;
        _frameIndex = 0;
      });
    } catch (error) {
      debugPrint('Failed to load pet sprite: $error');
      if (mounted) {
        setState(() => _spriteLoadFailed = true);
      }
    }
  }

  String _spritePathForSpecies(String species) {
    if (species == PetSpecies.dog) {
      return 'lib/assets/images/pet/dog_spritesheet.png';
    }
    return 'lib/assets/images/pet/cat_orange_spritesheet.png';
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
      if (_loadedSpecies != widget.pet.species && !_spriteLoadFailed) {
        _loadSprite();
      }
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
              final actionBounce =
                  action == PetAction.pet || action == PetAction.feed
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
                      ? _SpriteLoadPlaceholder(failed: _spriteLoadFailed)
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

class _SpriteLoadPlaceholder extends StatelessWidget {
  final bool failed;

  const _SpriteLoadPlaceholder({required this.failed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 176,
      child: failed
          ? const Center(
              child: Text('宠物加载中断', style: TextStyle(color: Colors.grey)),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _PetFeedbackOverlay extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const _PetFeedbackOverlay({required this.controller, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tick = controller.feedbackTick.value;
      final feedbackAction = controller.feedbackAction.value;
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

      if (feedbackAction == PetAction.pet && tick > 0) {
        return Positioned(
          key: ValueKey('pet_feedback_$tick'),
          top: 48,
          right: 64,
          child: SizedBox(
            width: 92,
            height: 76,
            child: Stack(
              children: const [
                Positioned(
                  left: 30,
                  top: 16,
                  child: _FloatingFeedback(
                    icon: Icons.favorite,
                    color: Colors.pinkAccent,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 28,
                  child: _FloatingFeedback(
                    icon: Icons.favorite,
                    color: Color.fromARGB(255, 255, 121, 164),
                    delay: Duration(milliseconds: 110),
                    size: 30,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 22,
                  child: _FloatingFeedback(
                    icon: Icons.favorite,
                    color: Color.fromARGB(255, 255, 93, 135),
                    delay: Duration(milliseconds: 210),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (feedbackAction == PetAction.feed && tick > 0) {
        return Positioned(
          key: ValueKey('feed_feedback_$tick'),
          bottom: 72,
          right: 78,
          child: const _FloatingFeedback(
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
  final Duration delay;
  final double size;

  const _FloatingFeedback({
    required this.icon,
    required this.color,
    this.label,
    this.delay = Duration.zero,
    this.size = 38,
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
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, 10),
      end: const Offset(0, -22),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
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
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
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
              ? Icon(widget.icon, color: widget.color, size: widget.size * 0.58)
              : Text(
                  widget.label!,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: widget.size * 0.47,
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
              valueColor: AlwaysStoppedAnimation(TaskTheme.appBarColor),
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

class _RewardShopPanel extends StatefulWidget {
  final PetController petController;
  final RewardController rewardController;

  const _RewardShopPanel({
    required this.petController,
    required this.rewardController,
  });

  @override
  State<_RewardShopPanel> createState() => _RewardShopPanelState();
}

class _RewardShopPanelState extends State<_RewardShopPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final species = widget.petController.pet.value?.species ?? PetSpecies.cat;
      final foods = PetController.foodsForSpecies(species);
      final shopTitle = '${PetController.speciesLabel(species)}食物';

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
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '奖励积分：${widget.rewardController.points}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '宠物商城',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          shopTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12),
                  ...foods.map(
                    (food) => _FoodShopItem(
                      food: food,
                      rewardController: widget.rewardController,
                    ),
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      );
    });
  }
}

class _FoodInventoryLine extends StatelessWidget {
  final RewardController rewardController;
  final PetModel pet;

  const _FoodInventoryLine({required this.rewardController, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ownedFoods = PetController.foodsForSpecies(
        pet.species,
      ).where((food) => rewardController.foodCount(food.name) > 0).toList();
      if (ownedFoods.isEmpty) {
        return Text(
          '库存：暂无适合${PetController.speciesLabel(pet.species)}的食物',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
      }

      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: ownedFoods
            .map(
              (food) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${food.name} x${rewardController.foodCount(food.name)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
      );
    });
  }
}

class _FoodPickerSheet extends StatelessWidget {
  final PetController petController;
  final RewardController rewardController;

  const _FoodPickerSheet({
    required this.petController,
    required this.rewardController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Obx(() {
        final species = petController.pet.value?.species ?? PetSpecies.cat;
        final ownedFoods = PetController.foodsForSpecies(
          species,
        ).where((food) => rewardController.foodCount(food.name) > 0).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择食物',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (ownedFoods.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    '还没有适合当前宠物的食物，先去商城兑换吧',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...ownedFoods.map(
                (food) => ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.orange),
                  title: Text(food.name),
                  subtitle: Text(
                    '拥有 ${rewardController.foodCount(food.name)} 份  ·  +${food.hungerBoost} 饱腹  +${food.moodBoost} 心情',
                  ),
                  onTap: () => _useFood(food),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      }),
    );
  }

  Future<void> _useFood(PetFood food) async {
    final consumed = await rewardController.consumeFood(food);
    if (!consumed) {
      Get.snackbar('没有库存', '先去商城兑换这个食物吧', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await petController.feedWithFood(food);
    Get.back();
  }
}

class _ActionBar extends StatelessWidget {
  final PetController controller;
  final PetModel pet;
  final RewardController rewardController;

  const _ActionBar({
    required this.controller,
    required this.pet,
    required this.rewardController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
                onPressed: () => _showFoodPicker(),
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
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _FoodInventoryLine(
            rewardController: rewardController,
            pet: pet,
          ),
        ),
      ],
    );
  }

  void _showFoodPicker() {
    controller.feed();
    Get.bottomSheet(
      _FoodPickerSheet(
        petController: controller,
        rewardController: rewardController,
      ),
      isScrollControlled: true,
    );
  }
}

class _FoodShopItem extends StatelessWidget {
  final PetFood food;
  final RewardController rewardController;

  const _FoodShopItem({required this.food, required this.rewardController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TaskTheme.primaryColor.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${food.hungerBoost} 饱腹  +${food.moodBoost} 心情',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    '拥有 ${rewardController.foodCount(food.name)} 份',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final canBuy = rewardController.points >= food.cost;
            return ElevatedButton(
              onPressed: () => _buyFood(canBuy),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                backgroundColor: canBuy ? null : Colors.grey[300],
                foregroundColor: canBuy ? null : Colors.grey[600],
              ),
              child: Text('${food.cost}积分'),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _buyFood(bool canBuy) async {
    if (!canBuy) {
      Get.snackbar('积分不足', '再完成一些专注或任务吧', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final success = await rewardController.buyFood(food);
    if (!success) {
      Get.snackbar('积分不足', '再完成一些专注或任务吧', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.snackbar(
      '已购买',
      '${food.name} 已放入库存',
      snackPosition: SnackPosition.BOTTOM,
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
