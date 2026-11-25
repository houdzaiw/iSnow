import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import '../../../model/server_response.dart';
import '../../../model/user_profile.dart';
import '../homepage/profile_homepage_models.dart';
import '../tools/profile_feature_repository.dart';
import 'honor_models.dart';

final honorRepositoryProvider = Provider(
  (ref) => HonorRepository(ref.watch(profileFeatureRepositoryProvider)),
);
final honorCountProvider = FutureProvider<int>(
  (ref) async =>
      (await ref.watch(honorRepositoryProvider).achieved(force: true)).length,
);

class HonorRepository {
  HonorRepository(this.features);
  final ProfileFeatureRepository features;
  Future<List<ProfileHomepageHonorItem>>? _achieved;
  Future<List<ProfileHomepageHonorItem>>? _pendingAchieved;
  MembershipIdentity? _owner;
  Future<List<ProfileHomepageHonorItem>> achieved({bool force = false}) async {
    final account = await features.identity();
    if (_owner != account) {
      _achieved = null;
      _pendingAchieved = null;
    }
    _owner = account;
    if (_pendingAchieved case final pending?) return pending;
    if (!force && _achieved != null) return _achieved!;
    final pending = _pendingAchieved = _achieved = _fetchAchieved(account);
    try {
      return await pending;
    } catch (_) {
      if (identical(_achieved, pending)) _achieved = null;
      rethrow;
    } finally {
      if (identical(_pendingAchieved, pending)) _pendingAchieved = null;
    }
  }

  Future<List<ProfileHomepageHonorItem>> _fetchAchieved(
    MembershipIdentity account,
  ) async {
    final raw = await features.request(
      'GET',
      HttpApi.medalAchieved,
      account: account,
      params: {'targetUid': account.uid},
    );
    if (raw != null && raw is! List) {
      throw const NadyApiException(message: 'Invalid medal response');
    }
    return membershipList(
      raw,
      ProfileHomepageHonorItem.fromJson,
    ).where((m) => m.id.isNotEmpty).toList();
  }

  Future<List<HonorBadge>> badges(
    int type, {
    MembershipIdentity? account,
  }) async {
    final raw = await features.request(
      'GET',
      HttpApi.medalShowList,
      account: account,
      params: {'type': type},
    );
    if (raw != null && raw is! List) {
      throw const NadyApiException(message: 'Invalid medal catalog');
    }
    return membershipList(
      raw,
      HonorBadge.fromJson,
    ).where((b) => b.id.isNotEmpty).toList();
  }

  Future<HonorEquipment> equipment({MembershipIdentity? account}) async {
    final owner = account ?? await features.identity();
    final user = UserData.fromJson(
      membershipMap(
        membershipMap(
          await features.request('GET', HttpApi.myUserInfo, account: owner),
        )['userBaseInfo'],
      ),
    );
    if (user.uid != owner.uid) {
      throw const NadyApiException(message: 'Invalid user response');
    }
    final raw = membershipMap(
      await features.request('GET', HttpApi.medalWearingNum, account: owner),
    );
    final limit = int.tryParse('${raw['wearingNum']}');
    if (limit == null || limit < 0) {
      throw const NadyApiException(message: 'Unable to load medal limit');
    }
    return HonorEquipment(
      user,
      min(
        limit,
        HonorEquipment.nobleLimit(user.userLevel?.aristocracyLevel ?? 0),
      ),
    );
  }

  Future<bool> save(
    List<String> ids,
    MembershipIdentity account,
    bool Function() current,
  ) async {
    final equipment = await this.equipment(account: account);
    if (ids.toSet().length != ids.length || ids.length > equipment.limit) {
      throw const NadyApiException(message: 'Badges worn to the upper limit');
    }
    final catalog = <HonorBadge>[];
    for (final type in [1, 2, 3]) {
      catalog.addAll(await badges(type, account: account));
    }
    if (ids.any(
      (id) => !catalog.any((b) => b.id == id && b.wearable(DateTime.now())),
    )) {
      throw const NadyApiException(
        message: 'Medal unavailable or expired. Refresh and try again.',
      );
    }
    await features.request(
      'POST',
      HttpApi.medalWear,
      account: account,
      isCurrent: current,
      params: {'medalIds': List<String>.of(ids)},
    );
    _achieved = null;
    return features.synchronize(account);
  }
}
