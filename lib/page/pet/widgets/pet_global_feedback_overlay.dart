part of '../pet.dart';

class PetGlobalFeedbackOverlay extends StatefulWidget {
  const PetGlobalFeedbackOverlay({super.key});

  @override
  State<PetGlobalFeedbackOverlay> createState() =>
      _PetGlobalFeedbackOverlayState();
}

class _PetGlobalFeedbackOverlayState extends State<PetGlobalFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _visibleDuration = Duration(milliseconds: 1800);

  final PetController _controller = Get.find<PetController>();
  late final AnimationController _entranceController;
  Worker? _eventWorker;
  Timer? _hideTimer;
  PetOverlayEvent? _event;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _eventWorker = ever<PetOverlayEvent?>(
      _controller.overlayEvent,
      _handleOverlayEvent,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _eventWorker?.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleOverlayEvent(PetOverlayEvent? event) {
    if (!mounted || event == null) {
      return;
    }

    _hideTimer?.cancel();
    setState(() => _event = event);
    _entranceController.forward(from: 0);
    _hideTimer = Timer(_visibleDuration, () async {
      if (!mounted || _event?.id != event.id) {
        return;
      }
      await _entranceController.reverse();
      if (mounted && _event?.id == event.id) {
        setState(() => _event = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      bottom: 20,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entranceController,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeIn,
                ),
              ),
              child: _PetOverlayCard(
                key: ValueKey(event.id),
                event: event,
                controller: _controller,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetOverlayCard extends StatelessWidget {
  final PetOverlayEvent event;
  final PetController controller;

  const _PetOverlayCard({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(event.action);
    final icon = _iconFor(event.action);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 82,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 68,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  _MiniPetSprite(controller: controller, action: event.action),
                  Positioned(
                    right: 2,
                    top: 4,
                    child: _OverlayIconBadge(icon: icon, color: accent),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _MoodDeltaPill(delta: event.moodDelta, color: accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentFor(PetAction action) {
    return action == PetAction.overdue ? Colors.blueGrey : Colors.amber;
  }

  IconData _iconFor(PetAction action) {
    return action == PetAction.overdue ? Icons.access_time : Icons.star_rounded;
  }
}

class _MiniPetSprite extends StatefulWidget {
  final PetController controller;
  final PetAction action;

  const _MiniPetSprite({required this.controller, required this.action});

  @override
  State<_MiniPetSprite> createState() => _MiniPetSpriteState();
}

class _MiniPetSpriteState extends State<_MiniPetSprite> {
  Timer? _frameTimer;
  int _frameIndex = 0;
  _CachedPetSprite? _sprite;
  bool _loadFailed = false;
  _SpriteActionKey? _lastAction;

  @override
  void initState() {
    super.initState();
    _loadSprite();
  }

  @override
  void didUpdateWidget(covariant _MiniPetSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.pet.value?.species !=
        widget.controller.pet.value?.species) {
      _loadSprite();
    }
    if (oldWidget.action != widget.action) {
      _lastAction = null;
      _frameIndex = 0;
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSprite() async {
    try {
      final species = widget.controller.pet.value?.species ?? PetSpecies.cat;
      final sprite = await _PetSpriteCache.load(species);
      if (!mounted) {
        return;
      }
      setState(() {
        _sprite = sprite;
        _loadFailed = false;
        _frameIndex = 0;
        _lastAction = null;
      });
      _syncAnimation();
    } catch (error) {
      debugPrint('Failed to load pet overlay sprite: $error');
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  void _syncAnimation() {
    final sprite = _sprite;
    if (sprite == null) {
      return;
    }
    final action = _actionKeyFor(widget.action);
    final animation = sprite.spec.animationFor(action);
    if (_lastAction == action && _frameTimer?.isActive == true) {
      return;
    }
    _lastAction = action;
    _frameTimer?.cancel();
    final fps = animation.fps.clamp(1, 8).toInt();
    _frameTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (_) {
      if (!mounted) {
        return;
      }
      final frames = animation.frames.clamp(1, 8).toInt();
      setState(() => _frameIndex = (_frameIndex + 1) % frames);
    });
  }

  _SpriteActionKey _actionKeyFor(PetAction action) {
    if (action == PetAction.overdue) {
      return _SpriteActionKey.overdue;
    }
    return _SpriteActionKey.taskComplete;
  }

  @override
  Widget build(BuildContext context) {
    final sprite = _sprite;
    if (_loadFailed || sprite == null) {
      return const Icon(Icons.pets, color: Colors.black45, size: 54);
    }

    final action = _actionKeyFor(widget.action);
    final animation = sprite.spec.animationFor(action);
    return CustomPaint(
      size: sprite.spec.displaySize,
      painter: _SpriteSheetPainter(
        image: sprite.image,
        row: animation.row,
        frame: _frameIndex % animation.frames,
        frameWidth: sprite.spec.frameWidth,
        frameHeight: sprite.spec.frameHeight,
      ),
    );
  }
}

class _OverlayIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OverlayIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _MoodDeltaPill extends StatelessWidget {
  final int delta;
  final Color color;

  const _MoodDeltaPill({required this.delta, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = delta >= 0 ? '心情 +$delta' : '心情 $delta';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color == Colors.amber ? Colors.orange[800] : color,
        ),
      ),
    );
  }
}
