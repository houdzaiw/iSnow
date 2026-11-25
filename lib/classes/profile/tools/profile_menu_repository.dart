import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../configs/app_device.dart';
import '../../../manager/http_api.dart';
import '../../../model/server_response.dart';
import '../../../model/user_profile.dart';
import '../../../theme/app_assets.dart';
import '../mine/profile_menu_item.dart';
import '../mine/profile_view_model.dart';
import 'profile_feature_repository.dart';
import 'profile_tools_config.dart';

class ProfileMenuResult {
  const ProfileMenuResult(this.items, {this.error});
  final List<ProfileBadgeItem> items;
  final Object? error;
}

final profileMenuRepositoryProvider = Provider(
  (ref) => ProfileMenuRepository(ref.watch(profileFeatureRepositoryProvider)),
);
final profileMenuProvider = FutureProvider.autoDispose<ProfileMenuResult>((
  ref,
) {
  final user = ref.watch(
    profileViewModelProvider.select((s) => s.profile?.user),
  );
  if (user == null) return const ProfileMenuResult([]);
  return ref.watch(profileMenuRepositoryProvider).load(user);
});

class ProfileMenuRepository {
  ProfileMenuRepository(this.features);
  final ProfileFeatureRepository features;
  Future<Map<String, dynamic>>? _initializing;
  Map<String, dynamic>? _client;
  String? _clientAccount;
  final _menus = <String, Future<ProfileMenuResult>>{};

  Future<Map<String, dynamic>> client() async {
    final account = await features.identity();
    final key = '$account:${features.environment}';
    if (_clientAccount == key && _client != null) return _client!;
    if (_clientAccount == key && _initializing != null) return _initializing!;
    _clientAccount = key;
    _client = null;
    final device = AppDevice();
    final future = features
        .request(
          'POST',
          HttpApi.profileClientInit,
          account: account,
          params: {
            'deviceId': device.deviceId,
            'model': device.model,
            'os': device.os,
            'osVersion': device.osVersion,
            'app': 'nady',
            'appVersion': device.appVersion,
            'appVersionCode': device.appVersionCode,
            'systemLanguage': device.systemLanguage,
            'appLanguage': features.language,
            'channel': 'googleplay',
            'deviceBrand': device.deviceBrand,
            'bundleId': device.packageName,
          },
        )
        .then((value) {
          final data = membershipMap(value);
          if (data['isVersionAuditing'] is! bool) {
            throw const NadyApiException(
              message: 'Client configuration unavailable',
            );
          }
          if (_clientAccount == key) _client = data;
          return data;
        });
    _initializing = future;
    try {
      return await future;
    } finally {
      if (identical(_initializing, future)) _initializing = null;
    }
  }

  Future<ProfileMenuResult> load(UserData user) async {
    final account = await features.identity();
    if (user.uid != null && user.uid != account.uid) {
      throw const NadyApiException(message: 'Login session changed');
    }
    final key =
        '$account:${features.environment}:${features.language}:${user.roleType}:${user.isBd}:${user.isCoiner}';
    final future = _menus.putIfAbsent(key, () => _load(user, account));
    try {
      return await future;
    } finally {
      if (identical(_menus[key], future)) _menus.remove(key);
    }
  }

  Future<ProfileMenuResult> _load(
    UserData user,
    MembershipIdentity account,
  ) async {
    Object? error;
    final items = <ProfileBadgeItem>[
      const ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge06,
        titleKey: 'profile.dailyReward',
        webPath: '',
        destination: ProfileDestination(
          ProfileDestinationKind.dailyReward,
          '/daily-reward',
        ),
      ),
    ];
    final results = await Future.wait([
      client().then<Object?>((v) => v).catchError((Object e) {
        error = e;
        return null;
      }),
      features
          .request(
            'POST',
            HttpApi.homeResourceBanner,
            account: account,
            params: {'position': 8},
          )
          .catchError((Object e) {
            error = e;
            return null;
          }),
    ]);
    await features.check(account);
    final config = membershipMap(results[0]);
    if (config['isVersionAuditing'] == false) {
      final role = user.roleType;
      bool canSell = user.isCoiner == true;
      if (!canSell && (role == 1 || role == 3)) {
        try {
          canSell =
              await features.request(
                'GET',
                HttpApi.profileAgentPurseVisible,
                account: account,
              ) ==
              true;
        } catch (e) {
          error = e;
        }
      }
      void web(String key, String asset, String path) => items.add(
        ProfileBadgeItem(
          iconAsset: asset,
          titleKey: key,
          webPath: path,
          destination: ProfileDestination(
            ProfileDestinationKind.web,
            const ProfileToolsConfig().page(path, features.language).toString(),
          ),
        ),
      );
      if (role == 1 || role == 2 || role == 3) {
        web(
          'profile.agent',
          AppAssets.lanhuProfileBadge02,
          '/h5/agent/index.html',
        );
      }
      if (user.isBd == true) {
        web('profile.bd', AppAssets.lanhuProfileBadge03, '/h5/bd/index.html');
      }
      if (canSell) {
        web(
          'profile.saleCoin',
          AppAssets.lanhuProfileBadge07,
          '/h5/wallet/agent.html',
        );
      }
    }
    final banner = membershipMap(results[1]);
    final seen = <int>{};
    for (final item in membershipList(banner['list'], (j) => j)) {
      final id = membershipInt(item['id']);
      final destination = parseDestination(membershipString(item['routeUrl']));
      if (id <= 0 || !seen.add(id) || destination == null) continue;
      items.add(
        ProfileBadgeItem(
          iconAsset: AppAssets.iconMissing,
          iconUrl: membershipString(item['pic']),
          titleKey: '',
          title: membershipString(item['name']),
          webPath: '',
          destination: destination,
        ),
      );
    }
    await features.check(account);
    return ProfileMenuResult(items, error: error);
  }

  static ProfileDestination? parseDestination(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.userInfo.isNotEmpty) return null;
    if ({'http', 'https'}.contains(uri.scheme) && uri.host.isNotEmpty) {
      return ProfileDestination(ProfileDestinationKind.web, value);
    }
    if (uri.scheme == 'nady') {
      final route = switch (uri.path) {
        '/main/me-wallet' => '/wallet',
        '/main/me-store' => '/store',
        '/main/me-backpack' => '/backpack',
        '/main/me-badge' => '/honor',
        '/main/me-vip' => '/vip',
        '/main/me-aristocracy' => '/noble',
        '/main/setting/me-set-account-security' => '/settings/account-security',
        '/main/daily-reward' => '/daily-reward',
        _ => null,
      };
      if (route != null) {
        return ProfileDestination(ProfileDestinationKind.native, route);
      }
    }
    return null;
  }
}
