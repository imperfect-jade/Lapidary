import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/features/pet/services/pet_food_catalog.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

/// 宠物文案服务，集中生成状态、交互和跨模块反馈文案。
///
/// 该服务只返回字符串，不访问 GetX、Hive、Repository 或 UI；这样后续扩展多语言、
/// 鼓励文案池或宠物性格时，不需要修改 Controller 和页面组件。
class PetMessageService {
  /// 根据当前宠物状态生成默认气泡文案。
  ///
  /// Controller 的临时反馈结束后会回到这条文案。
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

  /// 睡眠自动恢复到满精力后展示的醒来文案。
  String wokeUp(PetModel pet) {
    return '${pet.name}睡醒啦，精神很好';
  }

  /// 用户抚摸宠物后的短反馈文案。
  String petting(PetModel pet) {
    return '${pet.name}蹭了蹭你的手';
  }

  /// 打开喂食 Sheet 前的提示文案，按物种提醒选择对应食物。
  String feedPrompt(String species) {
    return '请选择已购买的${PetFoodCatalog.speciesLabel(species)}食物来喂食';
  }

  /// 成功喂食后的反馈文案。
  String fed(PetModel pet, PetFood food) {
    return '${pet.name}吃了${food.name}，很满足';
  }

  /// 番茄钟专注开始时的陪伴文案，可带上关联任务标题。
  String focusCompanion(PetModel pet, String? taskTitle) {
    final target = taskTitle == null || taskTitle.isEmpty
        ? '这一轮'
        : '“$taskTitle”';
    return '${pet.name}正在陪你专注，先守住$target。';
  }

  /// 切换宠物物种后的反馈文案。
  String speciesSelected(String species) {
    return '已经切换为${PetFoodCatalog.speciesLabel(species)}';
  }

  /// 改名成功后的反馈文案。
  String renamed(String name) {
    return '现在叫我$name吧';
  }

  /// 睡眠/唤醒按钮点击后的反馈文案。
  String sleepToggled(PetModel pet) {
    return pet.isSleeping ? '${pet.name}蜷起来睡觉了' : '${pet.name}醒来陪你啦';
  }

  /// 宠物升级后的反馈文案。
  String levelUp(PetModel pet) {
    return '${pet.name}升级到 Lv.${pet.level} 啦';
  }

  /// 任务完成后的庆祝文案，重要任务会给出更强的正向反馈。
  String taskCompletion(PetModel pet, TaskModel task) {
    if (task.priority == 1 || task.priority == 3) {
      return '这件重要的事被你拿下了，${pet.name}超开心！';
    }
    return '${pet.name}开心地跳起来：任务完成啦，做得很好！';
  }

  /// 任务逾期反馈文案。
  ///
  /// 单个任务时尽量带上标题；多个任务时用数量提醒，避免文案过长。
  String overdue(int count, String? title) {
    if (count == 1 && title != null && title.isNotEmpty) {
      return '“$title”超过时间了，我们先从一点点开始吧。';
    }
    return '有 $count 个任务超过时间了，我们先从一个小任务重新开始吧。';
  }

  /// 专注完成后的庆祝文案，优先展示关联任务标题，否则展示专注时长和积分奖励。
  String focusCompletion(PetModel pet, PomodoroModel record, int reward) {
    final minutes = record.actualSeconds ~/ 60;
    if (record.taskTitle != null && record.taskTitle!.isNotEmpty) {
      return '${pet.name}陪你专注了 $minutes 分钟，“${record.taskTitle}”向前推进啦！';
    }
    return '${pet.name}陪你守住了 $minutes 分钟专注，奖励 +$reward 积分！';
  }
}
