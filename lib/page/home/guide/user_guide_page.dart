part of '../home.dart';

class _UserGuidePage extends StatelessWidget {
  const _UserGuidePage();

  @override
  Widget build(BuildContext context) {
    final sections = [
      const _GuideSectionData(
        icon: Icons.rocket_launch_outlined,
        title: '快速开始',
        items: [
          '底部导航包含任务、番茄钟、宠物、四象限和日历。',
          '先创建任务，再用番茄钟专注推进，完成后让宠物给你即时反馈。',
          '侧边栏可进入设置、宠物设置、使用指南、关于和版本信息。',
        ],
      ),
      const _GuideSectionData(
        icon: Icons.check_circle_outline,
        title: '待办任务',
        items: [
          '在任务页点击添加按钮，填写标题、描述和截止时间。',
          '选择日任务、周任务或月任务，并设置优先级。',
          '长期任务可以设置专注目标，方便配合番茄钟持续推进。',
          '首次完成任务会获得积分、宠物鼓励、心情和经验奖励。',
        ],
      ),
      const _GuideSectionData(
        icon: Icons.grid_view_outlined,
        title: '四象限',
        items: [
          '任务会按优先级进入四个象限：重要紧急、重要不紧急、紧急不重要、不重要不紧急。',
          '优先处理重要紧急任务，再安排重要不紧急任务。',
          '四象限页适合快速判断今天最值得投入精力的事情。',
        ],
      ),
      const _GuideSectionData(
        icon: Icons.calendar_month_outlined,
        title: '日历与课表',
        items: [
          '日历会展示本地任务和手机日历事项，点击日期可查看当天安排。',
          '任务详情中可以同步到手机系统日历，便于统一查看。',
          '课表模式可创建学期，再添加课程。',
          '课程支持设置周几、节次、单双周、上下半学期和线上/线下。',
        ],
      ),
      const _GuideSectionData(
        icon: Icons.timer_outlined,
        title: '番茄钟',
        items: [
          '可以选择一个任务开始专注，也可以使用自由专注。',
          '点击计时器可调整专注和休息时长。',
          '专注完成后会记录今日专注、发放积分，并触发宠物鼓励。',
          '休息完成会恢复宠物精力，帮助形成专注和恢复的循环。',
        ],
      ),
      const _GuideSectionData(
        icon: Icons.pets_outlined,
        title: '像素宠物',
        items: [
          '宠物会在任务完成、专注结束、任务逾期等场景提供轻量反馈。',
          '可以抚摸、喂食、让宠物睡觉或唤醒宠物。',
          '完成任务和番茄钟获得的积分可在宠物商城兑换食物。',
          '宠物浮层会尽量出现在当前页面，避免打断你的工作流。',
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        title: const Text('使用指南'),
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _GuideIntro(),
            const SizedBox(height: 12),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GuideSection(section: section),
              ),
            ),
            const _PetMechanismSection(),
          ],
        ),
      ),
    );
  }
}

class _GuideIntro extends StatelessWidget {
  const _GuideIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _guideDecoration(TaskTheme.selectedColor),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '把任务变成可见的进步',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            '琢玉将待办、日历、番茄钟和像素宠物放在一起，帮助你规划事情、进入专注，并在完成后得到温柔的正向反馈。',
            style: TextStyle(fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionData {
  final IconData icon;
  final String title;
  final List<String> items;

  const _GuideSectionData({
    required this.icon,
    required this.title,
    required this.items,
  });
}

class _GuideSection extends StatelessWidget {
  final _GuideSectionData section;

  const _GuideSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _guideDecoration(TaskTheme.appBarColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideTitle(icon: section.icon, title: section.title),
          const SizedBox(height: 10),
          ...section.items.map((item) => _GuideBullet(text: item)),
        ],
      ),
    );
  }
}

class _PetMechanismSection extends StatelessWidget {
  const _PetMechanismSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _guideDecoration(Colors.indigoAccent),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideTitle(icon: Icons.favorite_border, title: '宠物数值机制'),
          SizedBox(height: 10),
          _MechanismRow(
            label: '经验',
            text:
                '喂食增加经验；完成番茄钟 +8；完成任务按优先级 +16/+12/+8/+4；升级需要当前等级 * 40 经验，升级时心情 +10。',
          ),
          _MechanismRow(
            label: '心情',
            text:
                '抚摸 +1；喂食按食物增加；完成任务 +10/+8/+6/+4；完成专注 +6；逾期任务每个 -2，单次最多 -6；自然每分钟 -1。',
          ),
          _MechanismRow(
            label: '饱腹',
            text: '喂食增加 +12/+28/+45；自然每分钟 -1。饱腹过低时，宠物会提醒你照顾它。',
          ),
          _MechanismRow(
            label: '精力',
            text:
                '醒着每累计 10 分钟 -1；专注每 5 分钟 -1，不足 5 分钟也消耗 1；休息每 2 分钟 +1；睡觉每分钟 +2，满 100 自动醒来；抚摸 -2。',
          ),
          _MechanismRow(
            label: '食物',
            text: '完成任务和番茄钟获得积分，积分可在宠物商城兑换食物，食物用于恢复饱腹并提升心情。',
          ),
        ],
      ),
    );
  }
}

class _GuideTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _GuideTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: TaskTheme.selectedColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _GuideBullet extends StatelessWidget {
  final String text;

  const _GuideBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8, right: 9),
            decoration: BoxDecoration(
              color: TaskTheme.selectedColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.42),
            ),
          ),
        ],
      ),
    );
  }
}

class _MechanismRow extends StatelessWidget {
  final String label;
  final String text;

  const _MechanismRow({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TaskTheme.selectedColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TaskTheme.selectedColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.42),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _guideDecoration(Color accent) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: accent.withValues(alpha: 0.22)),
  );
}
