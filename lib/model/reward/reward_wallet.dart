import 'package:hive/hive.dart';

part 'reward_wallet.g.dart';

@HiveType(typeId: 3)
class RewardWalletModel extends HiveObject {
  @HiveField(0)
  int points;

  @HiveField(1)
  List<String> rewardedPomodoroIds;

  @HiveField(2)
  List<String> rewardedTaskIds;

  @HiveField(3)
  Map<String, int> taskFocusSeconds;

  @HiveField(4)
  Map<String, int> foodInventory;

  RewardWalletModel({
    required this.points,
    required this.rewardedPomodoroIds,
    required this.rewardedTaskIds,
    required this.taskFocusSeconds,
    required this.foodInventory,
  });

  factory RewardWalletModel.empty() {
    return RewardWalletModel(
      points: 0,
      rewardedPomodoroIds: <String>[],
      rewardedTaskIds: <String>[],
      taskFocusSeconds: <String, int>{},
      foodInventory: <String, int>{},
    );
  }
}
