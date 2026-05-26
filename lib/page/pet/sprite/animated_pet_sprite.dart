part of '../pet.dart';

class _AnimatedPetSprite extends StatefulWidget {
  final PetController controller;
  final PetModel pet;

  const _AnimatedPetSprite({required this.controller, required this.pet});

  @override
  State<_AnimatedPetSprite> createState() => _AnimatedPetSpriteState();
}

class _AnimatedPetSpriteState extends State<_AnimatedPetSprite>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _moveController;
  Worker? _actionWorker;
  Timer? _frameTimer;
  Timer? _behaviorTimer;
  ui.Image? _spriteImage;
  PetSpriteSpec? _spriteSpec;
  bool _spriteLoadFailed = false;
  int _frameIndex = 0;
  bool _facingLeft = false;
  bool _wasSleeping = false;
  double _positionFactor = 0;
  double _moveStartFactor = 0;
  double _moveEndFactor = 0;
  final Random _random = Random();
  AmbientPetMotion _ambientMotion = AmbientPetMotion.idle;
  PetSpriteActionKey _lastAction = PetSpriteActionKey.idle;
  String? _loadedSpecies;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _wasSleeping = widget.pet.isSleeping;
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addStatusListener(_handleMoveStatus);
    _actionWorker = ever<PetAction>(
      widget.controller.action,
      _handlePetActionChanged,
    );
    _loadSprite();
    if (_wasSleeping) {
      _enterSleepMode();
    } else {
      _scheduleNextBehavior(initial: true);
    }
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
    _syncSleepMode();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _behaviorTimer?.cancel();
    _actionWorker?.dispose();
    _moveController.removeStatusListener(_handleMoveStatus);
    _idleController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  Future<void> _loadSprite() async {
    final species = widget.pet.species;
    try {
      final cached = await PetSpriteCache.load(species);
      _useCachedSprite(species, cached, const Size(184, 198));
    } catch (error) {
      debugPrint('Failed to load pet sprite: $error');
      if (mounted) {
        setState(() => _spriteLoadFailed = true);
      }
    }
  }

  void _useCachedSprite(
    String species,
    CachedPetSprite cached,
    Size displaySize,
  ) {
    if (!mounted || widget.pet.species != species) {
      return;
    }
    final spec = cached.spec.copyWith(displaySize: displaySize);
    setState(() {
      _spriteImage = cached.image;
      _spriteSpec = spec;
      _spriteLoadFailed = false;
      _loadedSpecies = species;
      _frameIndex = 0;
      _lastAction = PetSpriteActionKey.idle;
    });
    _startFrameTimer(spec.animationFor(PetSpriteActionKey.idle));
  }

  void _startFrameTimer(
    PetSpriteAnimationSpec animation, {
    bool holdLastFrame = false,
  }) {
    _frameTimer?.cancel();
    final fps = animation.fps.clamp(1, 12).toInt();
    _frameTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (_) {
      if (!mounted) {
        return;
      }
      final frames = animation.frames.clamp(1, 8).toInt();
      if (holdLastFrame) {
        final nextFrame = _frameIndex + 1;
        if (nextFrame >= frames) {
          _frameTimer?.cancel();
          _frameTimer = null;
          setState(() {
            _frameIndex = frames - 1;
          });
          return;
        }
        setState(() => _frameIndex = nextFrame);
        return;
      }
      setState(() => _frameIndex = (_frameIndex + 1) % frames);
    });
  }

  void _handleMoveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _positionFactor = _moveEndFactor;
    _moveController.reset();
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    setState(() => _ambientMotion = AmbientPetMotion.idle);
    _scheduleNextBehavior();
  }

  void _syncFrameAction(
    PetSpriteActionKey action,
    PetSpriteAnimationSpec animation,
  ) {
    if (_lastAction != action) {
      _lastAction = action;
      _frameIndex = 0;
      _startFrameTimer(
        animation,
        holdLastFrame: action == PetSpriteActionKey.sleep,
      );
    }
  }

  void _syncSleepMode() {
    if (_wasSleeping == widget.pet.isSleeping) {
      return;
    }
    _wasSleeping = widget.pet.isSleeping;
    if (_wasSleeping) {
      _enterSleepMode();
    } else {
      _exitSleepMode();
    }
  }

  void _handlePetActionChanged(PetAction action) {
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    if (_usesActionAnimation(action)) {
      _behaviorTimer?.cancel();
      _captureCurrentPosition();
      _moveController.stop();
      _moveController.reset();
      _setAmbientMotion(AmbientPetMotion.idle);
      return;
    }
    if (action == PetAction.idle &&
        (_behaviorTimer == null || !_behaviorTimer!.isActive)) {
      _scheduleNextBehavior(initial: true);
    }
  }

  void _enterSleepMode() {
    _behaviorTimer?.cancel();
    _moveController.stop();
    _moveController.reset();
    _positionFactor = 0;
    _moveStartFactor = 0;
    _moveEndFactor = 0;
    _lastAction = PetSpriteActionKey.idle;
    _frameIndex = 0;
    if (mounted) {
      setState(() => _ambientMotion = AmbientPetMotion.idle);
    }
  }

  void _exitSleepMode() {
    _lastAction = PetSpriteActionKey.idle;
    _frameIndex = 0;
    if (mounted) {
      setState(() => _ambientMotion = AmbientPetMotion.idle);
    }
    _scheduleNextBehavior(initial: true);
  }

  void _scheduleNextBehavior({bool initial = false}) {
    _behaviorTimer?.cancel();
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    final baseDelay = initial ? 1200 : 3000;
    final randomDelay = initial ? 1200 : 4000;
    _behaviorTimer = Timer(
      Duration(milliseconds: baseDelay + _random.nextInt(randomDelay)),
      _chooseNextBehavior,
    );
  }

  void _chooseNextBehavior() {
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    if (widget.controller.action.value != PetAction.idle) {
      _scheduleNextBehavior();
      return;
    }

    final roll = _random.nextDouble();
    if (roll < 0.55) {
      _setAmbientMotion(AmbientPetMotion.idle);
      _scheduleNextBehavior();
    } else if (roll < 0.75) {
      _playAmbientFor(
        AmbientPetMotion.waiting,
        const Duration(milliseconds: 2600),
      );
    } else if (roll < 0.85) {
      _playAmbientFor(
        AmbientPetMotion.jumping,
        const Duration(milliseconds: 900),
      );
    } else if (roll < 0.90) {
      _playAmbientFor(
        AmbientPetMotion.runningInPlace,
        const Duration(milliseconds: 1200),
      );
    } else {
      _startRunBurst(toLeft: _random.nextBool());
    }
  }

  void _setAmbientMotion(AmbientPetMotion motion) {
    if (!mounted || _ambientMotion == motion) {
      return;
    }
    setState(() => _ambientMotion = motion);
  }

  void _playAmbientFor(AmbientPetMotion motion, Duration duration) {
    _behaviorTimer?.cancel();
    _captureCurrentPosition();
    _moveController.stop();
    _moveController.reset();
    _setAmbientMotion(motion);
    _behaviorTimer = Timer(duration, () {
      if (!mounted || widget.pet.isSleeping) {
        return;
      }
      _setAmbientMotion(AmbientPetMotion.idle);
      _scheduleNextBehavior();
    });
  }

  void _startRunBurst({required bool toLeft}) {
    _behaviorTimer?.cancel();
    _captureCurrentPosition();
    _moveController.stop();
    _moveController.reset();
    _moveStartFactor = _positionFactor;
    final targetDistance = 0.15 + _random.nextDouble() * 0.35;
    _moveEndFactor = toLeft ? -targetDistance : targetDistance;
    _moveController.duration = Duration(
      milliseconds: 1800 + _random.nextInt(801),
    );
    setState(() {
      _facingLeft = toLeft;
      _ambientMotion = toLeft
          ? AmbientPetMotion.runLeft
          : AmbientPetMotion.runRight;
    });
    _moveController.forward(from: 0);
  }

  void _captureCurrentPosition() {
    if (!_moveController.isAnimating) {
      return;
    }
    final moveCurve = Curves.easeInOut.transform(_moveController.value);
    _positionFactor =
        ui.lerpDouble(_moveStartFactor, _moveEndFactor, moveCurve) ??
        _positionFactor;
  }

  PetSpriteActionKey _resolveSpriteAction(PetAction action) {
    if (action == PetAction.taskComplete) {
      return PetSpriteActionKey.taskComplete;
    }
    if (widget.pet.isSleeping) {
      return PetSpriteActionKey.sleep;
    }
    if (action == PetAction.pet) {
      return PetSpriteActionKey.pet;
    }
    if (action == PetAction.feed) {
      return PetSpriteActionKey.feed;
    }
    if (action == PetAction.overdue) {
      return PetSpriteActionKey.overdue;
    }
    switch (_ambientMotion) {
      case AmbientPetMotion.runRight:
        return PetSpriteActionKey.runningRight;
      case AmbientPetMotion.runLeft:
        return PetSpriteActionKey.runningLeft;
      case AmbientPetMotion.waiting:
        return PetSpriteActionKey.waiting;
      case AmbientPetMotion.jumping:
        return PetSpriteActionKey.jumping;
      case AmbientPetMotion.runningInPlace:
        return PetSpriteActionKey.running;
      case AmbientPetMotion.idle:
        return PetSpriteActionKey.idle;
    }
  }

  bool _usesActionAnimation(PetAction action) {
    return action == PetAction.pet ||
        action == PetAction.feed ||
        action == PetAction.taskComplete ||
        action == PetAction.overdue;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final action = widget.controller.action.value;
      if (_loadedSpecies != widget.pet.species && !_spriteLoadFailed) {
        _loadSprite();
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: Listenable.merge([_idleController, _moveController]),
            builder: (context, child) {
              final image = _spriteImage;
              final spec = _spriteSpec;
              final spriteAction = _resolveSpriteAction(action);
              final animation = spec?.animationFor(spriteAction);
              if (animation != null) {
                _syncFrameAction(spriteAction, animation);
              }
              final idleLift = widget.pet.isSleeping
                  ? 1.5 * _idleController.value
                  : 5 * _idleController.value;
              final actionBounce =
                  action == PetAction.pet ||
                      action == PetAction.feed ||
                      action == PetAction.taskComplete
                  ? -12.0
                  : 0.0;
              final displaySize = spec?.displaySize ?? const Size(176, 176);
              final walkRange = (constraints.maxWidth - displaySize.width)
                  .clamp(0, 96)
                  .toDouble();
              final moveCurve = Curves.easeInOut.transform(
                _moveController.value,
              );
              final positionFactor = _moveController.isAnimating
                  ? ui.lerpDouble(_moveStartFactor, _moveEndFactor, moveCurve)!
                  : _positionFactor;
              final walkOffset = widget.pet.isSleeping
                  ? 0.0
                  : (walkRange * positionFactor);
              final scaleX = spec?.flipLeft == true && _facingLeft ? -1.0 : 1.0;

              return Transform.translate(
                offset: Offset(walkOffset, actionBounce - idleLift),
                child: Transform.scale(
                  scaleX: scaleX,
                  child: image == null || spec == null || animation == null
                      ? _SpriteLoadPlaceholder(
                          failed: _spriteLoadFailed,
                          size: displaySize,
                        )
                      : CustomPaint(
                          size: displaySize,
                          painter: _SpriteSheetPainter(
                            image: image,
                            row: animation.row,
                            frame: _frameIndex % animation.frames,
                            frameWidth: spec.frameWidth,
                            frameHeight: spec.frameHeight,
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
