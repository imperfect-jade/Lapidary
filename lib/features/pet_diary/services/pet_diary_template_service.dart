import 'dart:math';

import 'package:todolist/features/pet_diary/domain/pet_diary_stats.dart';

typedef _DiaryMatcher = bool Function(PetDiaryStats stats);
typedef _DiaryBuilder = String Function(PetDiaryStats stats, String petName);

enum _DiaryScenario {
  lateNight,
  highCompletion,
  steadyProgress,
  singleTask,
  focusCompanion,
  focusOnly,
}

/// Builds local, weighted-random pet diary text from daily behavior stats.
class PetDiaryTemplateService {
  PetDiaryTemplateService({Random? random}) : _random = random ?? Random();

  final Random _random;

  late final List<_DiaryTemplate> _templates = _buildTemplates();

  /// Builds one complete diary entry.
  ///
  /// The factual summary is deterministic and always uses [stats]. The
  /// emotional response is selected from matching templates with weighted
  /// randomness, then lightly decorated with occasional pet-like wording.
  String buildDiaryText({
    required PetDiaryStats stats,
    required String petName,
    Iterable<String> recentDiaryTexts = const [],
  }) {
    final summary = _summaryLine(stats);
    final candidates = _matchingTemplates(stats);
    final recent = recentDiaryTexts.take(5).toSet();
    final template = _pickTemplate(
      candidates: candidates,
      stats: stats,
      petName: petName,
      summary: summary,
      recentDiaryTexts: recent,
    );
    final response = template.build(stats, petName);
    final tone = _maybePetTone();
    final diaryText = _composeDiary(summary, response, tone);

    if (!recent.contains(diaryText)) {
      return diaryText;
    }

    final alternateTemplates = candidates.where(
      (item) => item.id != template.id,
    );
    if (alternateTemplates.isEmpty) {
      return diaryText;
    }

    final alternate = _pickWeighted(alternateTemplates.toList());
    return _composeDiary(summary, alternate.build(stats, petName), tone);
  }

  String _summaryLine(PetDiaryStats stats) {
    final taskPart = stats.completedTaskCount > 0
        ? '今天你完成了 ${stats.completedTaskCount} 个任务'
        : '今天还没有完成任务';

    if (stats.focusMinutes > 0) {
      return '$taskPart，还专注了 ${stats.focusMinutes} 分钟。';
    }
    return '$taskPart。';
  }

  List<_DiaryTemplate> _matchingTemplates(PetDiaryStats stats) {
    final matches = _templates
        .where((template) => template.match(stats))
        .toList();
    if (stats.lateNightTaskCount > 0) {
      final lateNightMatches = matches
          .where((template) => template.scenario == _DiaryScenario.lateNight)
          .toList();
      if (lateNightMatches.isNotEmpty) {
        return lateNightMatches;
      }
    }
    return matches.isEmpty ? _fallbackTemplates : matches;
  }

  _DiaryTemplate _pickTemplate({
    required List<_DiaryTemplate> candidates,
    required PetDiaryStats stats,
    required String petName,
    required String summary,
    required Set<String> recentDiaryTexts,
  }) {
    final freshCandidates = candidates.where((template) {
      final text = _composeDiary(summary, template.build(stats, petName), null);
      return !recentDiaryTexts.contains(text);
    }).toList();

    return _pickWeighted(
      freshCandidates.isEmpty ? candidates : freshCandidates,
    );
  }

  _DiaryTemplate _pickWeighted(List<_DiaryTemplate> candidates) {
    final totalWeight = candidates.fold<int>(
      0,
      (sum, template) => sum + template.weight,
    );
    var cursor = _random.nextInt(totalWeight);
    for (final template in candidates) {
      cursor -= template.weight;
      if (cursor < 0) {
        return template;
      }
    }
    return candidates.last;
  }

  String? _maybePetTone() {
    if (_random.nextDouble() >= 0.35) {
      return null;
    }

    const tones = [
      '喵，我把今天的小努力收好了。',
      '呼噜呼噜，今天也有被认真对待的一小块时间。',
      '尾巴轻轻晃了一下，我知道你已经很努力了。',
      '喵喵，明天也不用一下子做到很多，我们慢慢来。',
      '我把这封信悄悄放好，等你需要的时候再读一遍。',
      '呼噜，今天的你值得被温柔地夸一夸。',
    ];
    return tones[_random.nextInt(tones.length)];
  }

  String _composeDiary(String summary, String response, String? tone) {
    if (tone == null) {
      return '$summary\n$response';
    }
    return '$summary\n$response\n$tone';
  }

  List<_DiaryTemplate> _buildTemplates() {
    return [
      ..._lateNightTemplates,
      ..._highCompletionTemplates,
      ..._steadyProgressTemplates,
      ..._singleTaskTemplates,
      ..._focusCompanionTemplates,
      ..._focusOnlyTemplates,
    ];
  }

  List<_DiaryTemplate> get _fallbackTemplates {
    return [
      _DiaryTemplate(
        id: 'fallback-gentle-start',
        scenario: _DiaryScenario.singleTask,
        weight: 1,
        match: (_) => true,
        build: (_, petName) => '$petName还在这里陪你。明天我们先从一件很小的事开始，也很好。',
      ),
    ];
  }

  List<_DiaryTemplate> get _lateNightTemplates {
    return [
      _DiaryTemplate(
        id: 'late-night-1',
        scenario: _DiaryScenario.lateNight,
        weight: 8,
        match: (stats) => stats.lateNightTaskCount > 0,
        build: (_, petName) => '我看见你晚上还在认真收尾。现在可以把灯调暗一点了，$petName陪你慢慢休息。',
      ),
      _DiaryTemplate(
        id: 'late-night-2',
        scenario: _DiaryScenario.lateNight,
        weight: 7,
        match: (stats) => stats.lateNightTaskCount > 0,
        build: (_, petName) => '夜里完成事情很不容易，但你也需要被好好照顾。今天到这里就很棒了。',
      ),
      _DiaryTemplate(
        id: 'late-night-3',
        scenario: _DiaryScenario.lateNight,
        weight: 7,
        match: (stats) => stats.lateNightTaskCount > 0,
        build: (_, petName) => '你把一些事带到了夜晚，也把它们稳稳放下了。接下来换我守着你休息一会儿。',
      ),
      _DiaryTemplate(
        id: 'late-night-4',
        scenario: _DiaryScenario.lateNight,
        weight: 6,
        match: (stats) => stats.lateNightTaskCount > 0,
        build: (_, petName) => '今天的努力已经够亮了，不需要再熬得更晚。$petName希望你今晚睡得轻松一点。',
      ),
      _DiaryTemplate(
        id: 'late-night-5',
        scenario: _DiaryScenario.lateNight,
        weight: 6,
        match: (stats) => stats.lateNightTaskCount > 0,
        build: (_, petName) => '晚上还完成任务，说明你真的很在意生活的节奏。现在请把自己也放进计划里，好好休息。',
      ),
    ];
  }

  List<_DiaryTemplate> get _highCompletionTemplates {
    return [
      _DiaryTemplate(
        id: 'high-completion-1',
        scenario: _DiaryScenario.highCompletion,
        weight: 7,
        match: (stats) => stats.completedTaskCount >= 4,
        build: (_, petName) => '今天你处理了好多事情，像是把桌面一点点擦亮了。$petName真的为你开心。',
      ),
      _DiaryTemplate(
        id: 'high-completion-2',
        scenario: _DiaryScenario.highCompletion,
        weight: 7,
        match: (stats) => stats.completedTaskCount >= 4,
        build: (_, petName) => '这么多任务被你拿下，不是偶然，是你一直在认真推进。今晚可以给自己一点奖励。',
      ),
      _DiaryTemplate(
        id: 'high-completion-3',
        scenario: _DiaryScenario.highCompletion,
        weight: 6,
        match: (stats) => stats.completedTaskCount >= 4,
        build: (_, petName) => '我偷偷数了数，今天的完成清单很长。你把压力拆小，也把事情做成了。',
      ),
      _DiaryTemplate(
        id: 'high-completion-4',
        scenario: _DiaryScenario.highCompletion,
        weight: 6,
        match: (stats) => stats.completedTaskCount >= 4,
        build: (_, petName) => '今天的你很有行动力。不是每一步都要很大，只要像这样连续往前，就已经很好。',
      ),
      _DiaryTemplate(
        id: 'high-completion-5',
        scenario: _DiaryScenario.highCompletion,
        weight: 6,
        match: (stats) => stats.completedTaskCount >= 4,
        build: (_, petName) => '$petName把这些完成的小星星都收进了口袋。你真的完成了很扎实的一天。',
      ),
    ];
  }

  List<_DiaryTemplate> get _steadyProgressTemplates {
    return [
      _DiaryTemplate(
        id: 'steady-progress-1',
        scenario: _DiaryScenario.steadyProgress,
        weight: 7,
        match: (stats) =>
            stats.completedTaskCount >= 2 && stats.completedTaskCount <= 3,
        build: (_, petName) => '今天不是猛冲的一天，而是稳稳推进的一天。这样的节奏很可靠。',
      ),
      _DiaryTemplate(
        id: 'steady-progress-2',
        scenario: _DiaryScenario.steadyProgress,
        weight: 7,
        match: (stats) =>
            stats.completedTaskCount >= 2 && stats.completedTaskCount <= 3,
        build: (_, petName) => '你把几件事慢慢完成了，我觉得这很珍贵。生活就是这样一点点变好的。',
      ),
      _DiaryTemplate(
        id: 'steady-progress-3',
        scenario: _DiaryScenario.steadyProgress,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount >= 2 && stats.completedTaskCount <= 3,
        build: (_, petName) => '$petName看见你没有放弃节奏。今天的推进不吵闹，但很踏实。',
      ),
      _DiaryTemplate(
        id: 'steady-progress-4',
        scenario: _DiaryScenario.steadyProgress,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount >= 2 && stats.completedTaskCount <= 3,
        build: (_, petName) => '几件事被你认真放到了完成那一边，这就是很好的进展。请记得夸夸自己。',
      ),
      _DiaryTemplate(
        id: 'steady-progress-5',
        scenario: _DiaryScenario.steadyProgress,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount >= 2 && stats.completedTaskCount <= 3,
        build: (_, petName) => '今天的脚步刚刚好。你没有急着证明什么，只是把该做的事一点点做好。',
      ),
    ];
  }

  List<_DiaryTemplate> get _singleTaskTemplates {
    return [
      _DiaryTemplate(
        id: 'single-task-1',
        scenario: _DiaryScenario.singleTask,
        weight: 7,
        match: (stats) => stats.completedTaskCount == 1,
        build: (_, petName) => '完成一件事也是很好的开始。今天已经有一个小小的结被你解开了。',
      ),
      _DiaryTemplate(
        id: 'single-task-2',
        scenario: _DiaryScenario.singleTask,
        weight: 7,
        match: (stats) => stats.completedTaskCount == 1,
        build: (_, petName) => '$petName看见你迈出了那一步。只完成一件，也是真实的前进。',
      ),
      _DiaryTemplate(
        id: 'single-task-3',
        scenario: _DiaryScenario.singleTask,
        weight: 6,
        match: (stats) => stats.completedTaskCount == 1,
        build: (_, petName) => '今天有一件事被你认真完成了。它不需要很大，也足够值得被记下来。',
      ),
      _DiaryTemplate(
        id: 'single-task-4',
        scenario: _DiaryScenario.singleTask,
        weight: 6,
        match: (stats) => stats.completedTaskCount == 1,
        build: (_, petName) => '开始往往比看起来更难。你今天已经开始了，这一点很重要。',
      ),
      _DiaryTemplate(
        id: 'single-task-5',
        scenario: _DiaryScenario.singleTask,
        weight: 6,
        match: (stats) => stats.completedTaskCount == 1,
        build: (_, petName) => '我把今天完成的这一件事圈起来了。它像一颗小扣子，把一天轻轻扣住。',
      ),
    ];
  }

  List<_DiaryTemplate> get _focusCompanionTemplates {
    return [
      _DiaryTemplate(
        id: 'focus-companion-1',
        scenario: _DiaryScenario.focusCompanion,
        weight: 7,
        match: (stats) =>
            stats.completedTaskCount > 0 &&
            (stats.focusSessionCount >= 2 || stats.focusMinutes >= 50),
        build: (_, petName) => '你今天不只是完成任务，也安静地守住了专注时间。$petName一直在旁边陪着。',
      ),
      _DiaryTemplate(
        id: 'focus-companion-2',
        scenario: _DiaryScenario.focusCompanion,
        weight: 7,
        match: (stats) =>
            stats.completedTaskCount > 0 &&
            (stats.focusSessionCount >= 2 || stats.focusMinutes >= 50),
        build: (_, petName) => '专注的时间像慢慢亮起的小灯。你坐下来、坚持住，然后真的推进了事情。',
      ),
      _DiaryTemplate(
        id: 'focus-companion-3',
        scenario: _DiaryScenario.focusCompanion,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount > 0 &&
            (stats.focusSessionCount >= 2 || stats.focusMinutes >= 50),
        build: (_, petName) => '今天的你很会把心收回来。每一段专注都在帮你离目标近一点。',
      ),
      _DiaryTemplate(
        id: 'focus-companion-4',
        scenario: _DiaryScenario.focusCompanion,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount > 0 &&
            (stats.focusSessionCount >= 2 || stats.focusMinutes >= 50),
        build: (_, petName) => '$petName听见了计时结束的声音，也看见了你认真停留的样子。很棒。',
      ),
      _DiaryTemplate(
        id: 'focus-companion-5',
        scenario: _DiaryScenario.focusCompanion,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount > 0 &&
            (stats.focusSessionCount >= 2 || stats.focusMinutes >= 50),
        build: (_, petName) => '任务和专注都留下了痕迹。今天的努力不是一阵风，它有慢慢落地。',
      ),
    ];
  }

  List<_DiaryTemplate> get _focusOnlyTemplates {
    return [
      _DiaryTemplate(
        id: 'focus-only-1',
        scenario: _DiaryScenario.focusOnly,
        weight: 7,
        match: (stats) =>
            stats.completedTaskCount == 0 && stats.focusMinutes > 0,
        build: (_, petName) => '虽然任务还没有被勾掉，但你已经认真投入过了。专注本身也值得被记住。',
      ),
      _DiaryTemplate(
        id: 'focus-only-2',
        scenario: _DiaryScenario.focusOnly,
        weight: 7,
        match: (stats) =>
            stats.completedTaskCount == 0 && stats.focusMinutes > 0,
        build: (_, petName) => '$petName知道，有些努力不会立刻变成完成。你愿意坐下来，就已经很不容易。',
      ),
      _DiaryTemplate(
        id: 'focus-only-3',
        scenario: _DiaryScenario.focusOnly,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount == 0 && stats.focusMinutes > 0,
        build: (_, petName) => '今天的成果藏在专注里，不一定写在完成清单上。我有看见。',
      ),
      _DiaryTemplate(
        id: 'focus-only-4',
        scenario: _DiaryScenario.focusOnly,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount == 0 && stats.focusMinutes > 0,
        build: (_, petName) => '没有勾选任务也没关系。你把注意力交给了一段时间，这已经是在照顾未来的自己。',
      ),
      _DiaryTemplate(
        id: 'focus-only-5',
        scenario: _DiaryScenario.focusOnly,
        weight: 6,
        match: (stats) =>
            stats.completedTaskCount == 0 && stats.focusMinutes > 0,
        build: (_, petName) => '我陪你安静待过一会儿。那些看不见的积累，也会慢慢帮上忙。',
      ),
    ];
  }
}

class _DiaryTemplate {
  const _DiaryTemplate({
    required this.id,
    required this.scenario,
    required this.weight,
    required this.match,
    required this.build,
  });

  final String id;
  final _DiaryScenario scenario;
  final int weight;
  final _DiaryMatcher match;
  final _DiaryBuilder build;
}
