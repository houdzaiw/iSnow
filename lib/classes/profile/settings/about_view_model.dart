import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../manager/http_api.dart';
import '../../../manager/profile_app_info_manager.dart';
import '../../../model/server_response.dart';
import '../tools/profile_feature_repository.dart';

class ProfileUpdate {
  const ProfileUpdate({
    required this.needUpdate,
    this.type,
    this.title = '',
    this.description = '',
    this.url,
  });
  final bool needUpdate;
  final int? type;
  final String title, description;
  final Uri? url;
  factory ProfileUpdate.fromJson(Map<String, dynamic> j) {
    if (j['needUpdate'] is! bool) {
      throw const NadyApiException(message: 'Invalid update response');
    }
    final uri = Uri.tryParse(membershipString(j['skipUrl']));
    return ProfileUpdate(
      needUpdate: j['needUpdate'] as bool,
      type: int.tryParse('${j['updateType']}'),
      title: membershipString(j['title']),
      description: membershipString(j['explain']),
      url:
          uri != null &&
              {'http', 'https'}.contains(uri.scheme) &&
              uri.host.isNotEmpty &&
              uri.userInfo.isEmpty
          ? uri
          : null,
    );
  }
}

final profileAppInfoManagerProvider = Provider(
  (ref) => ProfileAppInfoManager(),
);
final aboutRepositoryProvider = Provider(
  (ref) => AboutRepository(
    ref.watch(profileFeatureRepositoryProvider),
    ref.watch(profileAppInfoManagerProvider),
  ),
);

class AboutRepository {
  AboutRepository(this.features, this.manager);
  final ProfileFeatureRepository features;
  final ProfileAppInfoManager manager;
  Future<ProfileAppInfo> info() => manager.read(features.language);
  Future<ProfileUpdate> check(
    ProfileAppInfo info,
    MembershipIdentity account,
    bool Function() current,
  ) async => ProfileUpdate.fromJson(
    membershipMap(
      await features.request(
        'POST',
        HttpApi.appVersion,
        account: account,
        isCurrent: current,
        params: info.params,
      ),
    ),
  );
}

class AboutState {
  const AboutState({
    this.info,
    this.update,
    this.busy = false,
    this.error,
    this.checked = false,
  });
  final ProfileAppInfo? info;
  final ProfileUpdate? update;
  final bool busy, checked;
  final Object? error;
}

final aboutProvider =
    StateNotifierProvider.autoDispose<AboutViewModel, AboutState>(
      (ref) => AboutViewModel(ref.watch(aboutRepositoryProvider)),
    );

class AboutViewModel extends StateNotifier<AboutState> {
  AboutViewModel(this.repo) : super(const AboutState()) {
    Future.microtask(load);
  }
  final AboutRepository repo;
  bool _alive = true;
  MembershipIdentity? _account;
  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  Future<void> load() async {
    if (!_alive || state.busy) return;
    state = const AboutState(busy: true);
    try {
      final account = await repo.features.identity(), info = await repo.info();
      await repo.features.check(account);
      if (!_alive) return;
      _account = account;
      state = AboutState(info: info);
    } catch (e) {
      if (_alive) state = AboutState(error: e);
    }
  }

  Future<void> check() async {
    if (!_alive || state.busy || state.info == null || _account == null) return;
    final info = state.info!;
    state = AboutState(info: info, busy: true);
    try {
      final update = await repo.check(info, _account!, () => _alive);
      if (_alive) state = AboutState(info: info, update: update, checked: true);
    } catch (e) {
      if (_alive) state = AboutState(info: info, error: e);
    }
  }

  Future<void> open() async {
    if (!_alive || state.busy || _account == null) return;
    final old = state, url = state.update?.url;
    if (url == null) return;
    state = AboutState(
      info: old.info,
      update: old.update,
      checked: old.checked,
      busy: true,
    );
    try {
      await repo.features.check(_account!);
      if (!_alive) return;
      if (!await repo.manager.open(url)) {
        throw const NadyApiException(message: 'Unable to open update link');
      }
      if (_alive) state = old;
    } catch (e) {
      if (_alive) {
        state = AboutState(
          info: old.info,
          update: old.update,
          checked: old.checked,
          error: e,
        );
      }
    }
  }
}
