part of '../pet.dart';

class _SpriteLoadPlaceholder extends StatelessWidget {
  final bool failed;
  final Size size;

  const _SpriteLoadPlaceholder({required this.failed, required this.size});

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
