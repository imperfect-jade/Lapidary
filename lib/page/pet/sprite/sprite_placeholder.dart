import 'package:flutter/material.dart';

/// 精灵资源加载占位。
///
/// 正在加载时保持同尺寸空白，加载失败时显示错误文案，避免舞台尺寸跳动。
class SpriteLoadPlaceholder extends StatelessWidget {
  final bool failed;
  final Size size;

  const SpriteLoadPlaceholder({
    super.key,
    required this.failed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: failed
          ? const Center(
              child: Text('宠物加载中断', style: TextStyle(color: Colors.grey)),
            )
          : const SizedBox.shrink(),
    );
  }
}
