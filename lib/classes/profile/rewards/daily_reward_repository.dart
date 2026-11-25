import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import '../../../model/server_response.dart';
import '../tools/profile_feature_repository.dart';
import 'daily_reward_models.dart';

final dailyRewardRepositoryProvider = Provider(
  (ref) => DailyRewardRepository(ref.watch(profileFeatureRepositoryProvider)),
);

class DailyRewardRepository {
  DailyRewardRepository(this.features);
  final ProfileFeatureRepository features;
  Future<DailySignInfo> signInfo() async {
    final data = await features.request('GET', HttpApi.dailySignInfo);
    if (membershipMap(data)['signInfos'] is! List) {
      throw const NadyApiException(message: 'Invalid check-in response');
    }
    return DailySignInfo.fromJson(membershipMap(data));
  }

  Future<List<DailyTaskGroup>> tasks() async => membershipList(
    await features.request('GET', HttpApi.dailyMissions),
    DailyTaskGroup.fromJson,
  );
  Future<bool> sign({bool Function()? isCurrent}) async {
    final account = await features.identity();
    final data = await features.request(
      'POST',
      HttpApi.dailySign,
      account: account,
      isCurrent: isCurrent,
    );
    if (data == false) {
      throw const NadyApiException(message: 'Check-in was not completed');
    }
    return features.synchronize(account);
  }

  Future<DailyOutcome> claim(int id, {bool Function()? isCurrent}) async {
    final account = await features.identity();
    final data = await features.request(
      'POST',
      HttpApi.dailyClaim,
      account: account,
      isCurrent: isCurrent,
      params: {'missionId': id},
    );
    final rewards = membershipList(data, DailyRewardItem.fromJson);
    return DailyOutcome(rewards, await features.synchronize(account));
  }

  Future<DailyRoomTarget?> recommendedRoom() async {
    final raw = await features.request(
      'GET',
      HttpApi.homeRecommendRoom,
      params: {'page': 1},
    );
    final data = raw is List ? raw : membershipMap(raw)['list'];
    final list = membershipList(data, (j) => j);
    for (final item in list) {
      final id = '${item['roomId'] ?? ''}'.trim();
      if (id.isNotEmpty) return DailyRoomTarget(id, membershipInt(item['uid']));
    }
    return null;
  }

  Future<DailyRoomTarget?> ownRoom() async {
    final user = membershipMap(
      membershipMap(
        await features.request('GET', HttpApi.myUserInfo),
      )['userBaseInfo'],
    );
    final roomId = '${user['roomId'] ?? ''}'.trim();
    return roomId.isEmpty
        ? null
        : DailyRoomTarget(roomId, membershipInt(user['uid']));
  }
}
