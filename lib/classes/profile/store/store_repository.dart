import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import '../../../model/server_response.dart';
import '../../../model/user_profile.dart';
import '../../wallet/wallet_models.dart';
import '../tools/profile_feature_repository.dart';
import 'store_models.dart';

final storeRepositoryProvider = Provider(
  (ref) => StoreRepository(ref.watch(profileFeatureRepositoryProvider)),
);

class StoreRepository {
  StoreRepository(this.features);
  final ProfileFeatureRepository features;

  Future<StorePageData> products(StoreCategory category, int page) async {
    final raw = await features.request(
      'POST',
      HttpApi.storeProducts,
      params: {'type': category.type, 'pageNum': page, 'pageSize': 20},
    );
    final data = membershipMap(raw);
    if (data['shopPropList'] is! List) {
      throw const NadyApiException(message: 'Invalid store response');
    }
    final items = membershipList(
      data['shopPropList'],
      StoreProduct.fromJson,
    ).where((item) => item.id > 0 && item.type == category.type).toList();
    final pages = membershipInt(data['totalPage']);
    return StorePageData(items, pages > 0 ? page < pages : items.length >= 20);
  }

  Future<Set<int>> newProducts() async {
    final raw = await features.request('POST', HttpApi.storeNewProducts);
    return membershipList(
          membershipMap(raw)['newProductFlagItemList'],
          (j) => j,
        )
        .where((j) => membershipInt(j['markNewProduct']) == 1)
        .map((j) => membershipInt(j['type']))
        .toSet();
  }

  Future<WalletPurse> purse() async {
    final account = await features.identity();
    final raw = await features.request(
      'GET',
      HttpApi.walletPurse,
      account: account,
    );
    return WalletPurse.fromJson(membershipMap(raw));
  }

  Future<UserData> recipient(String uid) async {
    if (int.tryParse(uid.trim()) == null || int.parse(uid.trim()) <= 0) {
      throw const NadyApiException(message: 'Invalid user ID');
    }
    final raw = await features.request(
      'GET',
      HttpApi.userHomepage,
      params: {'targetUid': int.parse(uid.trim())},
    );
    var data = membershipMap(raw);
    if (data['info'] is Map) data = membershipMap(data['info']);
    final user = UserData.fromJson(membershipMap(data['userBaseInfo']));
    if ((user.uid ?? 0) <= 0 ||
        user.userStatus != NadyLoginStatus.normal ||
        data['blocked'] == true ||
        membershipMap(data['userBaseInfo'])['blocked'] == true) {
      throw const NadyApiException(message: 'Recipient unavailable');
    }
    return user;
  }

  Future<bool> purchase(StoreOrder order, {bool Function()? isCurrent}) async {
    await features.check(order.account);
    if (!order.price.valid ||
        !order.product.prices.any((p) => p.key == order.price.key) ||
        order.product.id <= 0 ||
        order.targetUid != null && order.targetUid! <= 0) {
      throw const NadyApiException(message: 'Invalid purchase selection');
    }
    if (order.targetUid != null) {
      final target = await recipient('${order.targetUid}');
      if (target.uid != order.targetUid) {
        throw const NadyApiException(message: 'Recipient changed');
      }
    }
    final balance = await purse();
    await features.check(order.account);
    final available = order.price.currency == 1
        ? balance.coin
        : balance.diamond;
    if (available < order.price.price) throw StoreInsufficientBalance();
    await features.request(
      'POST',
      HttpApi.storePurchase,
      account: order.account,
      isCurrent: isCurrent,
      params: {
        'type': order.product.type,
        'id': order.product.id,
        'currencyType': order.price.currency,
        'day': order.price.days,
        if (order.targetUid != null) 'targetUserId': order.targetUid,
      },
    );
    return features.synchronize(order.account);
  }

  Future<List<OwnedProp>> props(StoreCategory category, int page) async =>
      membershipList(
        await features.request(
          'GET',
          HttpApi.profileProps,
          params: {'type': category.type, 'pageNum': page},
        ),
        OwnedProp.fromJson,
      ).where((p) => p.id > 0 && p.type == category.type).toList();

  Future<UserData> currentUser({MembershipIdentity? account}) async {
    final expected = account ?? await features.identity();
    final user = UserData.fromJson(
      membershipMap(
        membershipMap(
          await features.request('GET', HttpApi.myUserInfo, account: expected),
        )['userBaseInfo'],
      ),
    );
    if (user.uid != expected.uid) {
      throw const NadyApiException(message: 'Invalid user response');
    }
    return user;
  }

  Future<PropTransfer> prepareTransfer(
    OwnedProp prop,
    int targetUid,
    MembershipIdentity account,
  ) async {
    await features.check(account);
    final user = await currentUser(account: account);
    if (user.uid != account.uid ||
        (user.userLevel?.vipLevel ?? 0) < 5 ||
        targetUid == account.uid ||
        targetUid <= 0 ||
        prop.expired(DateTime.now())) {
      throw const NadyApiException(
        message: 'Transfer unavailable. VIP 5 or above is required.',
      );
    }
    final target = await recipient('$targetUid');
    if (target.uid != targetUid) {
      throw const NadyApiException(message: 'Recipient changed');
    }
    return PropTransfer(account, prop, targetUid, target.nick ?? '$targetUid');
  }

  Future<bool> transfer(PropTransfer order, bool Function() isCurrent) async {
    await prepareTransfer(order.prop, order.targetUid, order.account);
    // Verify the owned instance still exists; never submit its goodsId as id.
    final category = StoreCategory.values.firstWhere(
      (c) => c.type == order.prop.type,
    );
    OwnedProp? fresh;
    final seen = <int>{};
    for (var page = 1; page <= 100; page++) {
      final items = await props(category, page);
      fresh = items
          .where(
            (p) => p.id == order.prop.id && p.goodsId == order.prop.goodsId,
          )
          .firstOrNull;
      if (fresh != null || items.isEmpty) break;
      final previousCount = seen.length;
      seen.addAll(items.map((p) => p.id));
      if (seen.length == previousCount) break;
      if (!isCurrent()) throw const NadyApiException(message: 'Page closed');
    }
    if (fresh == null || fresh.expired(DateTime.now())) {
      throw const NadyApiException(message: 'Item unavailable or expired');
    }
    await features.request(
      'POST',
      HttpApi.backpackTransfer,
      account: order.account,
      isCurrent: isCurrent,
      params: {'targetUid': order.targetUid, 'id': fresh.id},
    );
    return features.synchronize(order.account);
  }

  Future<bool> use(
    OwnedProp prop, {
    required bool enable,
    bool Function()? isCurrent,
  }) async {
    final account = await features.identity();
    if (prop.expired(DateTime.now()) || prop.goodsId <= 0) {
      throw const NadyApiException(message: 'This item has expired');
    }
    await features.request(
      'POST',
      HttpApi.profileUseProp,
      account: account,
      isCurrent: isCurrent,
      params: {
        'goodsType': prop.type,
        'goodsId': prop.goodsId,
        'useState': enable ? 1 : 0,
      },
    );
    return features.synchronize(account);
  }
}
