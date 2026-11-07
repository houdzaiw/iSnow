import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../configs/app_configs.dart';
import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import '../../../manager/locale_provider.dart';
import '../../../model/server_response.dart';
import '../../oauth/provider/login_provider.dart';
import '../../room/gift/room_gift_repository.dart';
import 'membership_models.dart';
import 'membership_session.dart';

abstract class MembershipApi {
  Future<Object?> get(String path, [Map<String, dynamic>? query]);
  Future<Object?> post(String path, Map<String, dynamic> body);
}

class NadyMembershipApi implements MembershipApi {
  NadyMembershipApi(this.http);
  final HttpDioManager http;
  @override
  Future<Object?> get(String path, [Map<String, dynamic>? query]) =>
      http.get(path, queryParameters: query);
  @override
  Future<Object?> post(String path, Map<String, dynamic> body) =>
      http.post(path, data: body);
}

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  final session = ref.watch(membershipSessionProvider);
  final language = ref.watch(appLocaleProvider).languageCode;
  return MembershipRepository(
    NadyMembershipApi(HttpDioManager()),
    identity: session.identity,
    namespace: '${AppConfig.shared.appEnv.baseUrl}:$language',
    refreshUser: () async {
      await LoginProvider().getMyProfileInfo();
    },
    refreshBalance: () async {
      await ref.read(roomGiftRepositoryProvider).fetchBalance();
    },
  );
});

class MembershipRepository {
  MembershipRepository(
    this.api, {
    required this.identity,
    this.namespace = '',
    this.refreshUser,
    this.refreshBalance,
  });
  final MembershipApi api;
  final Future<MembershipIdentity> Function() identity;
  final String namespace;
  final Future<void> Function()? refreshUser, refreshBalance;
  final Map<String, Object> _cache = {};
  final Map<String, Future<Object>> _pending = {};
  int _revision = 0;

  Future<void> check(MembershipIdentity expected) async {
    if (await identity() != expected) {
      throw const NadyApiException(message: 'Login session changed');
    }
  }

  Future<T> _request<T>(
    Future<Object?> Function() action,
    T Function(Object?) parse,
    MembershipIdentity expected,
  ) async {
    await check(expected);
    final raw = await action();
    await check(expected);
    final server = NadyServerResponse<T>.fromJson(membershipMap(raw), parse);
    if (!server.isSuccess) throw server.toException();
    if (server.data == null) {
      throw const NadyApiException(message: 'Invalid membership response');
    }
    return server.data as T;
  }

  Future<T> _read<T extends Object>(
    String path,
    T Function(Object?) parse, {
    bool force = false,
  }) async {
    final account = await identity();
    final key = '$namespace:$account:$_revision:$path';
    final pending = _pending[key];
    if (pending != null) return await pending as T;
    if (_cache[key] case final T cached when !force) return cached;
    final request = _request<T>(() => api.get(path), parse, account);
    _pending[key] = request;
    try {
      final result = await request;
      await check(account);
      _cache[key] = result;
      return result;
    } finally {
      if (identical(_pending[key], request)) _pending.remove(key);
    }
  }

  void invalidate() {
    _revision++;
    _cache.clear();
  }

  Future<VipMembership> vip({bool force = false}) =>
      _read(HttpApi.membershipVip, (v) {
        final map = membershipMap(v);
        if (map['userInfo'] is! Map ||
            map['vipInfos'] is! List ||
            map['grades'] is! List) {
          throw const NadyApiException(message: 'Invalid VIP data');
        }
        return VipMembership.fromJson(map);
      }, force: force);
  Future<List<NobleMembership>> nobles({bool force = false}) =>
      _read(HttpApi.membershipNoble, (v) {
        if (v is! List) {
          throw const NadyApiException(message: 'Invalid noble data');
        }
        return membershipList(v, NobleMembership.fromJson);
      }, force: force);
  Future<int> experienceCards({bool force = false}) =>
      _read(HttpApi.membershipVipExperienceCard, membershipInt, force: force);
  Future<List<NobleReward>> rewards({bool force = false}) => _read(
    HttpApi.membershipNobleRewards,
    (v) => membershipList(membershipMap(v)['infos'], NobleReward.fromJson),
    force: force,
  );
  Future<List<NobleTitle>> titles({bool force = false}) => _read(
    HttpApi.membershipNobleTitles,
    (v) => membershipList(v, NobleTitle.fromJson),
    force: force,
  );

  Future<List<VipSettingItem>> settings() async {
    final account = await identity();
    return _request(
      () => api.get(HttpApi.userVipSetting, {'uid': account.uid}),
      (v) {
        final map = membershipMap(v);
        return ['invisibleEnter', 'invisibleVisitor']
            .where((k) => map[k] is Map)
            .map(
              (k) => VipSettingItem.fromJson({
                ...membershipMap(map[k]),
                'type': k,
              }),
            )
            .toList(growable: false);
      },
      account,
    );
  }

  Future<MembershipRecipient> recipient(
    int number, {
    bool unblock = false,
  }) async {
    final account = await identity();
    return _request(
      () => api.get(
        unblock ? HttpApi.membershipVipBlock : HttpApi.userHomepage,
        unblock ? {'userNo': number} : {'targetUid': number},
      ),
      (v) => unblock
          ? MembershipRecipient.fromBlock(membershipMap(v))
          : MembershipRecipient.fromHomepage(membershipMap(v)),
      account,
    );
  }

  Future<MembershipRecordPage> history(MembershipKind kind, int page) async {
    final account = await identity();
    final vip = kind == MembershipKind.vip;
    return _request(
      () => api.get(
        vip ? HttpApi.membershipVipHistory : HttpApi.membershipNobleHistory,
        {'pageNum': page, if (vip) 'pagePage': 20 else 'pageSize': 20},
      ),
      (v) {
        final map = membershipMap(v);
        return MembershipRecordPage(
          membershipList(
            map['list'],
            vip ? MembershipRecord.vip : MembershipRecord.noble,
          ),
          membershipInt(map['total']),
        );
      },
      account,
    );
  }

  /// The caller freezes this request in a confirmation dialog. Never auto-retry.
  Future<void> submit(
    MembershipAction action, {
    required MembershipIdentity account,
    int? gradeId,
    int? nobleId,
    int? targetUid,
  }) async {
    final path = switch (action) {
      MembershipAction.buyVip => HttpApi.membershipVipBuy,
      MembershipAction.buyNoble => HttpApi.membershipNobleBuy,
      MembershipAction.experienceCard => HttpApi.membershipVipExperienceCard,
      MembershipAction.reward => HttpApi.membershipNobleGive,
      MembershipAction.unblock => HttpApi.membershipVipUnblock,
    };
    await _request(
      () => action == MembershipAction.unblock
          ? api.get(path, {'targetUid': targetUid})
          : api.post(path, {
              if (action == MembershipAction.buyVip ||
                  action == MembershipAction.buyNoble)
                'gradeId': gradeId,
              if (action == MembershipAction.buyNoble ||
                  action == MembershipAction.reward)
                'aristocracyId': nobleId,
              'targetUid': targetUid,
            }),
      (_) => true,
      account,
    );
    invalidate();
  }

  Future<void> setSetting(int id, bool open) async {
    final account = await identity();
    await _request(
      () => api.post(HttpApi.userVipSetting, {'id': id, 'open': open}),
      (_) => true,
      account,
    );
  }

  Future<void> claimTitle(int id, MembershipIdentity account) async {
    await _request(
      () => api.post(HttpApi.membershipNobleTitleClaim, {'id': id}),
      (_) => true,
      account,
    );
    invalidate();
  }

  Future<void> syncAccount(MembershipIdentity account) async {
    await check(account);
    await Future.wait([
      if (refreshUser != null) refreshUser!(),
      if (refreshBalance != null) refreshBalance!(),
    ]);
    await check(account);
  }
}
