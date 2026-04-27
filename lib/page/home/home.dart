import 'package:flutter/material.dart';
import 'package:todolist/page/calendar/calendar.dart';
import 'package:todolist/page/pet/pet.dart';
import 'package:todolist/page/pomodoro/pomodoro.dart';
import 'package:todolist/page/quadrant/quadrant.dart';
import 'package:todolist/page/task/task.dart';
//主页面
class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomePage> {

  final List<Map<String, String>> _tabList = [
    {
      "icon": "lib/assets/images/task.png", 
      "active_icon": "lib/assets/images/task_active.png", 
      "title": "待办任务"
    },

    {
      "icon": "lib/assets/images/pomodoro.png", 
      "active_icon": "lib/assets/images/pomodoro_active.png", 
      "title": "番茄钟"
    },

    {
      "icon": "lib/assets/images/quadrant.png", 
      "active_icon": "lib/assets/images/quadrant_active.png", 
      "title": "四象限"
    },

    {
      "icon": "lib/assets/images/calendar.png", 
      "active_icon": "lib/assets/images/calendar_active.png", 
      "title": "日历"
    },

    {
      "icon": "lib/assets/images/pet.png", 
      "active_icon": "lib/assets/images/pet_active.png", 
      "title": "宠物"
    },

  ];

  //当前选中的索引
  int _currentIndex = 0;
  //获取底部导航栏的组件
  List<Widget> _getChildren(){
    return [
      TaskPage(),
      PomodoroPage(),
      QuadrantPage(),
      CalendarPage(),
      PetPage(),
    ];
  }

  //获取底部导航栏的组件
  List<BottomNavigationBarItem> _getTabBarWidget(){
    return List.generate(_tabList.length, (int index){
      return BottomNavigationBarItem(
        icon: Image.asset(_tabList[index]["icon"]!, width: 30, height: 30),
        activeIcon: Image.asset(_tabList[index]["active_icon"]!, width: 30, height: 30),
        label: _tabList[index]["title"]!,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //避开安全区组件
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex, //当前选中的索引
          children: _getChildren(), //获取子组件
        )
      ),
      //底部导航栏
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (int index){
          setState(() {
            _currentIndex = index;
          });
        },
        items: _getTabBarWidget(),
        currentIndex: _currentIndex,
      ),
    );
  }
}