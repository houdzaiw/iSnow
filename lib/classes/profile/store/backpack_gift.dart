import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../manager/http_api.dart';
import '../../../model/server_response.dart';
import '../honor/honor_models.dart';
import '../tools/profile_feature_repository.dart';
import 'store_models.dart';

/// Personal inventory uses two APIs; keys include the source to avoid collisions.
class BackpackGift {
  const BackpackGift({
    required this.key,
    required this.id,
    required this.name,
    required this.icon,
    required this.amount,
    required this.animation,
    this.animationType,
    this.direction,
    this.expiresAt,
  });
  final String key, name, icon, animation;
  final int id, amount;
  final int? animationType, direction;
  final DateTime? expiresAt;
  factory BackpackGift.fromJson(Map<String, dynamic> j, String source) =>
      BackpackGift(
        key: '$source:${j['itemType']}:${j['giftId'] ?? j['goodsId']}',
        id: membershipInt(j['giftId'] ?? j['goodsId']),
        name: membershipString(j['giftName'] ?? j['name']),
        icon: membershipString(j['icon']),
        amount: membershipInt(j['amount']),
        animation: membershipString(j['animationUrl']),
        animationType: int.tryParse('${j['animationType']}'),
        direction: int.tryParse('${j['direction']}'),
        expiresAt: HonorStage.date(j['nearestExpireTimestamp']),
      );
  StoreProduct get preview => StoreProduct(
    id: id,
    type: 9,
    name: name,
    icon: icon,
    animation: animation,
    animationType: animationType,
    direction: direction,
    prices: const [],
  );
}

class BackpackGiftRepository {
  BackpackGiftRepository(this.features);
  final ProfileFeatureRepository features;
  Future<List<BackpackGift>> load() async {
    final account = await features.identity();
    final rawGifts = await features.request(
      'GET',
      HttpApi.backpackGifts,
      account: account,
    );
    if (rawGifts != null && rawGifts is! List) {
      throw const NadyApiException(message: 'Invalid gift inventory response');
    }
    final gifts = membershipList(
      rawGifts,
      (j) => BackpackGift.fromJson(j, 'gift'),
    );
    final rawProps = await features.request(
      'GET',
      HttpApi.backpackUserProps,
      account: account,
    );
    if (rawProps != null && rawProps is! List) {
      throw const NadyApiException(message: 'Invalid prop inventory response');
    }
    final props = membershipList(
      rawProps,
      (j) => BackpackGift.fromJson(j, 'prop'),
    );
    return <String, BackpackGift>{
      for (final gift in [...gifts, ...props])
        if (gift.id > 0 && gift.amount > 0) gift.key: gift,
    }.values.toList();
  }
}

final backpackGiftRepositoryProvider = Provider(
  (ref) => BackpackGiftRepository(ref.watch(profileFeatureRepositoryProvider)),
);
final backpackGiftsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(backpackGiftRepositoryProvider).load(),
);
