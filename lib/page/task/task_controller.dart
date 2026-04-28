//待办任务控制器
import 'package:get/get.dart';
import 'package:todolist/model/task/task.dart';
import 'package:hive_flutter/hive_flutter.dart';  

class TaskController extends GetxController
{
  final RxList<TaskModel> taskList = <TaskModel>[].obs;

  late Box<TaskModel> taskBox;

  //初始化
  @override
  void onInit() 
  {
    super.onInit();
    //打开数据库
    taskBox = Hive.box<TaskModel>('tasks');
    //获取所有任务
    getTasks();
  }

  //获取所有任务
  void getTasks() 
  {
    taskList.value = taskBox.values.toList();
  }

  //添加任务
  Future<void> addTask(String title, DateTime deadline, {int priority = 3, String? description}) async 
  {
    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 用时间戳作为唯一ID
      title: title,
      priority: priority,
      deadline: deadline,
      description: description,
    );
    
    await taskBox.put(task.id, task);       // 存入Hive
    taskList.add(task);                    // 更新响应式列表
  }

  //更新任务
  Future<void> updateTask(TaskModel task) async 
  {
    await task.save();  // 存入Hive
    taskList.refresh();
  }

  //删除任务
  Future<void> deleteTask(TaskModel task) async 
  {
    await task.delete();
    taskList.remove(task);
  }

  //修改任务状态
  Future<void> updateTaskStatus(TaskModel task) async 
  {
    task.isCompleted = !task.isCompleted;
    await task.save();  // 存入Hive
    taskList.refresh();
  }

  //按条件筛选任务
  List<TaskModel> get completedTasks =>   // 已完成任务
    taskList.where((t) => t.isCompleted).toList();
  
  List<TaskModel> get pendingTasks =>   // 待办任务
    taskList.where((t) => !t.isCompleted).toList();

}