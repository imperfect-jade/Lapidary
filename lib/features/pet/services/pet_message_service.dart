import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/features/pet/services/pet_food_catalog.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

class PetMessageService {
  String statusMessage(PetModel pet) {
    if (pet.isSleeping) {
      return '${pet.name}正在睡觉恢复精力';
    }
    if (pet.hunger < 35) {
      return '${pet.name}有点饿了';
    }
    if (pet.energy < 30) {
      return '${pet.name}想休息一下';
    }
    if (pet.mood < 35) {
      return '${pet.name}想要一点陪伴';
    }
    return '今天也一起慢慢完成任务吧';
  }

  String wokeUp(PetModel pet) {
    return '${pet.name}睡醒啦，精神很好';
  }

  String petting(PetModel pet) {
    return '${pet.name}蹭了蹭你的手';
  }

  String feedPrompt(String species) {
    return '请选择已购买的${PetFoodCatalog.speciesLabel(species)}食物来喂食';
  }

  String fed(PetModel pet, PetFood food) {
    return '${pet.name}吃了${food.name}，很满足';
  }

  String focusCompanion(PetModel pet, String? taskTitle) {
    final target = taskTitle == null || taskTitle.isEmpty
        ? '这一轮'
        : '“$taskTitle”';
    return '${pet.name}正在陪你专注，先守住$target。';
  }

  String speciesSelected(String species) {
    return '已经切换为${PetFoodCatalog.speciesLabel(species)}';
  }

  String renamed(String name) {
    return '现在叫我$name吧';
  }

  String sleepToggled(PetModel pet) {
    return pet.isSleeping ? '${pet.name}蜷起来睡觉了' : '${pet.name}醒来陪你啦';
  }

  String levelUp(PetModel pet) {
    return '${pet.name}升级到 Lv.${pet.level} 啦';
  }

  String taskCompletion(PetModel pet, TaskModel task) {
    if (task.priority == 1 || task.priority == 3) {
      return '这件重要的事被你拿下了，${pet.name}超开心！';
    }
    return '${pet.name}开心地跳起来：任务完成啦，做得很好！';
  }

  String overdue(int count, String? title) {
    if (count == 1 && title != null && title.isNotEmpty) {
      return '“$title”超过时间了，我们先从一点点开始吧。';
    }
    return '有 $count 个任务超过时间了，我们先从一个小任务重新开始吧。';
  }

  String focusCompletion(PetModel pet, PomodoroModel record, int reward) {
    final minutes = record.actualSeconds ~/ 60;
    if (record.taskTitle != null && record.taskTitle!.isNotEmpty) {
      return '${pet.name}陪你专注了 $minutes 分钟，“${record.taskTitle}”向前推进啦！';
    }
    return '${pet.name}陪你守住了 $minutes 分钟专注，奖励 +$reward 积分！';
  }
}
