import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 精灵图绘制器，从 spritesheet 中裁剪指定行和帧绘制到目标尺寸。
///
/// 这里关闭抗锯齿和滤镜，保持像素风边缘清晰；动画逻辑由外层组件推进 frame。
class SpriteSheetPainter extends CustomPainter {
  final ui.Image image;
  final int row;
  final int frame;
  final int frameWidth;
  final int frameHeight;

  SpriteSheetPainter({
    required this.image,
    required this.row,
    required this.frame,
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 源矩形按帧宽高定位到 spritesheet 的单格区域。
    final src = Rect.fromLTWH(
      frame * frameWidth.toDouble(),
      row * frameHeight.toDouble(),
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );
    final paint = Paint()
      // 像素宠物需要保留硬边，避免缩放后变成模糊插值效果。
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    canvas.drawImageRect(image, src, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant SpriteSheetPainter oldDelegate) {
    // 只在图片、行、帧或帧尺寸变化时重绘，减少动画之外的无效绘制。
    return oldDelegate.image != image ||
        oldDelegate.row != row ||
        oldDelegate.frame != frame ||
        oldDelegate.frameWidth != frameWidth ||
        oldDelegate.frameHeight != frameHeight;
  }
}
