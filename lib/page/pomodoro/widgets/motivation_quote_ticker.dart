import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 运行态励志语轮播组件。
///
/// 从文本资源加载多条文案，运行时按固定间隔轮播，为专注过程提供轻量陪伴感。
class PomodoroMotivationQuoteTicker extends StatefulWidget {
  const PomodoroMotivationQuoteTicker({super.key});

  @override
  State<PomodoroMotivationQuoteTicker> createState() =>
      _MotivationQuoteTickerState();
}

class _MotivationQuoteTickerState extends State<PomodoroMotivationQuoteTicker> {
  static const String _assetPath = 'lib/assets/text/motivational_quotes.txt';

  Timer? _timer;
  List<String> _quotes = const [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 初始化时异步读取资源文件，避免阻塞页面构建。
    _loadQuotes();
  }

  /// 加载励志语资源并启动轮播计时器。
  ///
  /// 文本文件以空行分隔不同文案；只有多于一条文案时才启动定时轮换。
  Future<void> _loadQuotes() async {
    final raw = await rootBundle.loadString(_assetPath);
    final quotes = raw
        .split(RegExp(r'\r?\n\s*\r?\n'))
        .map((quote) => quote.trim())
        .where((quote) => quote.isNotEmpty)
        .toList();
    if (!mounted) {
      return;
    }
    setState(() => _quotes = quotes);
    if (quotes.length > 1) {
      // 每 6 秒切换一条文案；回调前检查 mounted，避免组件销毁后 setState。
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _currentIndex = (_currentIndex + 1) % _quotes.length);
      });
    }
  }

  @override
  void dispose() {
    // 组件销毁时取消轮播计时器，避免后台继续回调。
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quotes.isEmpty
        ? '预测未来的最好方法就是去创造未来。'
        : _quotes[_currentIndex];
    return Container(
      // 励志语卡片 UI：左侧强调线 + 中间文字，使用 AnimatedSwitcher 做轻量切换动画。
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(
            255,
            238,
            181,
            105,
          ).withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(
              255,
              197,
              122,
              46,
            ).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 225, 143, 63),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 520),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final offset = Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: Text(
                  quote,
                  key: ValueKey(quote),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'MaShanZheng',
                    color: Color.fromARGB(255, 197, 113, 43),
                    fontSize: 20,
                    height: 1.20,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: Color.fromARGB(34, 124, 73, 24),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
