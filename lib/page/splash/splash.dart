import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPage extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const SplashPage({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color.fromARGB(255, 225, 238, 247),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color.fromARGB(255, 225, 238, 247),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _breath = Tween<double>(
      begin: 0.96,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 238, 247),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _SplashBackgroundPainter()),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _breath.value,
                          child: CustomPaint(
                            size: const Size(156, 156),
                            painter: _JadeLogoPainter(progress: _fade.value),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      '琢玉',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: Color.fromARGB(255, 42, 58, 72),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.errorMessage == null ? '打磨日常，温柔前行' : '初始化遇到了一点问题',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color.fromARGB(255, 91, 112, 128),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _SplashStatus(
                      isLoading: widget.isLoading,
                      errorMessage: widget.errorMessage,
                      onRetry: widget.onRetry,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashStatus extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _SplashStatus({
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(
                  255,
                  214,
                  104,
                  104,
                ).withValues(alpha: 0.26),
              ),
            ),
            child: Text(
              errorMessage!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color.fromARGB(255, 126, 72, 72),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: AlwaysStoppedAnimation(
              Color.fromARGB(255, 69, 132, 184),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isLoading ? '正在整理你的任务与陪伴' : '准备完成',
          style: const TextStyle(
            fontSize: 13,
            color: Color.fromARGB(255, 91, 112, 128),
          ),
        ),
      ],
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromARGB(255, 240, 248, 252),
        Color.fromARGB(255, 225, 238, 247),
        Color.fromARGB(255, 231, 246, 234),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    paint.shader = null;
    paint.color = Colors.white.withValues(alpha: 0.34);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.22), 96, paint);
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.72),
      118,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _JadeLogoPainter extends CustomPainter {
  final double progress;

  _JadeLogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()..isAntiAlias = true;

    paint.shader = const RadialGradient(
      colors: [
        Color.fromARGB(255, 255, 254, 239),
        Color.fromARGB(255, 237, 245, 236),
        Color.fromARGB(255, 190, 216, 210),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.88, paint);

    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color.fromARGB(255, 111, 143, 148).withValues(alpha: 0.5);
    canvas.drawCircle(center, radius * 0.88, paint);

    final sweepPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.72);
    final start = -math.pi / 2 + progress * math.pi * 0.7;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.62),
      start,
      math.pi * 0.42,
      false,
      sweepPaint,
    );

    final splitPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color.fromARGB(255, 78, 98, 102).withValues(alpha: 0.52);
    final path = Path()
      ..moveTo(center.dx + 10, center.dy - radius * 0.68)
      ..cubicTo(
        center.dx - 26,
        center.dy - 18,
        center.dx + 30,
        center.dy + 24,
        center.dx - 8,
        center.dy + radius * 0.66,
      );
    canvas.drawPath(path, splitPaint);

    final warmPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = const Color.fromARGB(
        255,
        202,
        170,
        102,
      ).withValues(alpha: 0.42);
    final warmPath = Path()
      ..moveTo(center.dx + 28, center.dy - radius * 0.68)
      ..cubicTo(
        center.dx + 4,
        center.dy - 16,
        center.dx + 50,
        center.dy + 20,
        center.dx + 20,
        center.dy + radius * 0.62,
      );
    canvas.drawPath(warmPath, warmPaint);
  }

  @override
  bool shouldRepaint(covariant _JadeLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
