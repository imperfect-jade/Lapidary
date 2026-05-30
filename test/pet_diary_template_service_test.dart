import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/features/pet_diary/domain/pet_diary_stats.dart';
import 'package:todolist/features/pet_diary/services/pet_diary_template_service.dart';

void main() {
  test('fixed seed produces stable diary text', () {
    final stats = PetDiaryStats(
      completedTaskCount: 4,
      focusMinutes: 50,
      focusSessionCount: 2,
      lateNightTaskCount: 0,
    );
    final first = PetDiaryTemplateService(
      random: Random(12),
    ).buildDiaryText(stats: stats, petName: '小云');
    final second = PetDiaryTemplateService(
      random: Random(12),
    ).buildDiaryText(stats: stats, petName: '小云');

    expect(second, first);
  });

  test('two or three completed tasks use steady progress wording', () {
    final text = PetDiaryTemplateService(random: Random(1)).buildDiaryText(
      stats: const PetDiaryStats(
        completedTaskCount: 2,
        focusMinutes: 0,
        focusSessionCount: 0,
        lateNightTaskCount: 0,
      ),
      petName: '小云',
    );

    expect(text, contains('今天你完成了 2 个任务'));
    expect(text, isNot(contains('明天先从一件很小的事开始')));
    expect(text, isNot(contains('明天开始')));
  });

  test(
    'focus-only diary validates focus instead of treating it as no action',
    () {
      final text = PetDiaryTemplateService(random: Random(2)).buildDiaryText(
        stats: const PetDiaryStats(
          completedTaskCount: 0,
          focusMinutes: 35,
          focusSessionCount: 1,
          lateNightTaskCount: 0,
        ),
        petName: '小云',
      );

      expect(text, contains('今天还没有完成任务，还专注了 35 分钟'));
      expect(_containsAny(text, const ['专注', '投入', '坐下来']), isTrue);
      expect(text, isNot(contains('明天开始')));
    },
  );

  test('late night task completion prefers rest reminders', () {
    final text = PetDiaryTemplateService(random: Random(3)).buildDiaryText(
      stats: const PetDiaryStats(
        completedTaskCount: 2,
        focusMinutes: 0,
        focusSessionCount: 0,
        lateNightTaskCount: 1,
      ),
      petName: '小云',
    );

    expect(text, contains('今天你完成了 2 个任务'));
    expect(_containsAny(text, const ['休息', '睡', '灯', '熬']), isTrue);
  });

  test('multiple seeds produce variety without corrupting factual summary', () {
    final stats = PetDiaryStats(
      completedTaskCount: 5,
      focusMinutes: 65,
      focusSessionCount: 3,
      lateNightTaskCount: 0,
    );
    final results = <String>{};

    for (var seed = 0; seed < 12; seed += 1) {
      results.add(
        PetDiaryTemplateService(
          random: Random(seed),
        ).buildDiaryText(stats: stats, petName: '小云'),
      );
    }

    expect(results.length, greaterThan(1));
    for (final text in results) {
      expect(text, contains('今天你完成了 5 个任务，还专注了 65 分钟'));
    }
  });

  test(
    'recent exact diary text is avoided when another template is available',
    () {
      const stats = PetDiaryStats(
        completedTaskCount: 1,
        focusMinutes: 0,
        focusSessionCount: 0,
        lateNightTaskCount: 0,
      );
      final first = PetDiaryTemplateService(
        random: Random(4),
      ).buildDiaryText(stats: stats, petName: '小云');
      final second = PetDiaryTemplateService(
        random: Random(4),
      ).buildDiaryText(stats: stats, petName: '小云', recentDiaryTexts: [first]);

      expect(second, isNot(first));
      expect(second, contains('今天你完成了 1 个任务'));
    },
  );
}

bool _containsAny(String text, Iterable<String> needles) {
  return needles.any(text.contains);
}
