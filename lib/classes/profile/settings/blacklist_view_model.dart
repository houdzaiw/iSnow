import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../manager/http_api.dart';
import '../../../model/server_response.dart';
import '../tools/profile_feature_repository.dart';

class ProfileBlockedUser {
  const ProfileBlockedUser(this.uid, this.userNo, this.name, this.avatar);
  final int uid, userNo;
  final String name, avatar;
  factory ProfileBlockedUser.fromJson(Map<String, dynamic> j) {
    final u = membershipMap(j['targetUserInfo']);
    return ProfileBlockedUser(
      membershipInt(u['uid']),
      membershipInt(u['userNo']),
      membershipString(u['nick']),
      membershipString(u['avatar']),
    );
  }
}

final blacklistRepositoryProvider = Provider(
  (ref) => BlacklistRepository(ref.watch(profileFeatureRepositoryProvider)),
);

class BlacklistRepository {
  BlacklistRepository(this.features);
  final ProfileFeatureRepository features;
  Future<List<ProfileBlockedUser>> load(
    int page,
    MembershipIdentity account,
  ) async {
    final raw = membershipMap(
      await features.request(
        'POST',
        HttpApi.userBlacklist,
        account: account,
        params: {'pageNum': page, 'pageSize': 20},
      ),
    );
    if (raw['list'] is! List) {
      throw const NadyApiException(message: 'Invalid blacklist response');
    }
    return membershipList(
      raw['list'],
      ProfileBlockedUser.fromJson,
    ).where((u) => u.uid > 0).toList();
  }

  Future<void> remove(
    int uid,
    MembershipIdentity account,
    bool Function() current,
  ) => features.request(
    'POST',
    HttpApi.userBlacklistUpdate,
    account: account,
    isCurrent: current,
    params: {'targetUid': uid, 'blackOrNot': false},
  );
}

class BlacklistState {
  const BlacklistState({
    this.items = const [],
    this.page = 0,
    this.more = true,
    this.loading = false,
    this.removing,
    this.error,
  });
  final List<ProfileBlockedUser> items;
  final int page;
  final bool more, loading;
  final int? removing;
  final Object? error;
}

final blacklistProvider =
    StateNotifierProvider.autoDispose<BlacklistViewModel, BlacklistState>(
      (ref) => BlacklistViewModel(ref.watch(blacklistRepositoryProvider)),
    );

class BlacklistViewModel extends StateNotifier<BlacklistState> {
  BlacklistViewModel(this.repo) : super(const BlacklistState()) {
    Future.microtask(load);
  }
  final BlacklistRepository repo;
  MembershipIdentity? _account;
  bool _alive = true;
  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    if (!_alive ||
        state.loading ||
        state.removing != null ||
        more && !state.more) {
      return;
    }
    final old = state;
    state = BlacklistState(
      items: old.items,
      page: old.page,
      more: old.more,
      loading: true,
    );
    try {
      final account = await repo.features.identity(),
          page = more ? old.page + 1 : 1;
      final items = await repo.load(page, account);
      if (!_alive) return;
      _account = account;
      state = BlacklistState(
        items: <int, ProfileBlockedUser>{
          if (more)
            for (final u in old.items) u.uid: u,
          for (final u in items) u.uid: u,
        }.values.toList(),
        page: page,
        more: items.length >= 20,
      );
    } catch (e) {
      if (_alive) {
        state = BlacklistState(
          items: old.items,
          page: old.page,
          more: old.more,
          error: e,
        );
      }
    }
  }

  Future<bool> remove(int uid) async {
    if (!_alive ||
        state.loading ||
        state.removing != null ||
        _account == null ||
        !state.items.any((u) => u.uid == uid)) {
      return false;
    }
    final old = state;
    state = BlacklistState(
      items: old.items,
      page: old.page,
      more: old.more,
      removing: uid,
    );
    try {
      await repo.remove(uid, _account!, () => _alive);
      if (!_alive) return false;
      state = BlacklistState(
        items: old.items.where((u) => u.uid != uid).toList(),
        page: old.page,
        more: old.more,
      );
      await load();
      return _alive;
    } catch (e) {
      if (_alive) {
        state = BlacklistState(
          items: old.items,
          page: old.page,
          more: old.more,
          error: e,
        );
      }
      return false;
    }
  }
}
