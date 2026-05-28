import 'package:get/get.dart';

/// 首页导航状态控制器。
///
/// 只保存当前选中的底部 Tab 和 Tab 展示元数据，具体业务状态由各功能模块自己的 Controller 管理。
class HomeController extends GetxController {
  /// 默认进入宠物页，让应用启动后优先呈现陪伴入口。
  final RxInt currentIndex = 2.obs;

  /// 底部导航元数据，顺序需要与 HomePage 中的页面列表保持一致。
  final List<Map<String, String>> tabList = [
    {
      'icon': 'lib/assets/images/task.png',
      'active_icon': 'lib/assets/images/task_active.png',
      'title': '待办任务',
    },
    {
      'icon': 'lib/assets/images/pomodoro.png',
      'active_icon': 'lib/assets/images/pomodoro_active.png',
      'title': '番茄钟',
    },
    {
      'icon': 'lib/assets/images/pet.png',
      'active_icon': 'lib/assets/images/pet_active.png',
      'title': '宠物',
    },
    {
      'icon': 'lib/assets/images/quadrant.png',
      'active_icon': 'lib/assets/images/quadrant_active.png',
      'title': '四象限',
    },
    {
      'icon': 'lib/assets/images/calendar.png',
      'active_icon': 'lib/assets/images/calendar_active.png',
      'title': '日历',
    },
  ];

  /// 切换底部 Tab，由底部导航栏和侧边栏入口共同调用。
  ///
  /// 这里只更新当前索引，不负责页面实例创建；页面保留由 HomePage 中的 IndexedStack 处理。
  void changeTab(int index) {
    currentIndex.value = index;
  }
}
