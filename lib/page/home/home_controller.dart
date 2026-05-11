import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxInt currentIndex = 2.obs;

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

  void changeTab(int index) {
    currentIndex.value = index;
  }
}