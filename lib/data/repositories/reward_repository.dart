import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/reward/reward_wallet.dart';

class RewardRepository {
  RewardRepository({Box<RewardWalletModel>? box})
    : _box = box ?? Hive.box<RewardWalletModel>(BoxNames.rewardWallet);

  static const String walletKey = 'default_wallet';

  final Box<RewardWalletModel> _box;

  Future<RewardWalletModel> getWallet() async {
    final savedWallet = _box.get(walletKey);
    if (savedWallet != null) {
      return savedWallet;
    }

    final emptyWallet = RewardWalletModel.empty();
    await putWallet(emptyWallet);
    return emptyWallet;
  }

  Future<void> putWallet(RewardWalletModel wallet) {
    return _box.put(walletKey, wallet);
  }

  Future<void> save(RewardWalletModel wallet) {
    return wallet.save();
  }
}
