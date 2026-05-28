import 'package:flutter/material.dart';

/// 宠物顶部消息气泡，用于展示状态文案和操作后的短反馈。
///
/// 文案由 `PetController.message` 提供，气泡本身不判断宠物状态，
/// 避免 UI 层重复维护文案规则。
class PetMessageBubble extends StatelessWidget {
  final String message;

  const PetMessageBubble({super.key, required this.message});

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
        // 直接展示 Controller 当前文案，临时提示和状态恢复都在 Controller 中处理。
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
