import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../configs/app_configs.dart';
import '../../../manager/account_balance_revision.dart';
import '../../../manager/http_dio_manager.dart';
import '../../../manager/locale_provider.dart';
import '../../../model/server_response.dart';
import '../../oauth/provider/login_provider.dart';
import '../membership/membership_models.dart';
import '../membership/membership_repository.dart';
import '../membership/membership_session.dart';

export '../membership/membership_models.dart'
    show membershipMap, membershipList, membershipInt, membershipString;
export '../membership/membership_session.dart' show MembershipIdentity;

final profileFeatureRepositoryProvider = Provider<ProfileFeatureRepository>((
  ref,
) {
  final session = ref.watch(membershipSessionProvider);
  final language = ref.watch(appLocaleProvider).languageCode;
  return ProfileFeatureRepository(
    NadyProfileFeatureApi(HttpDioManager()),
    identity: session.identity,
    environment: AppConfig.shared.appEnv.baseUrl,
    language: language,
    refresh: () async {
      await LoginProvider().getMyProfileInfo();
      ref.read(accountBalanceRevisionProvider.notifier).state++;
    },
  );
});

abstract interface class ProfileSessionTransport {
  Future<Object?> forAccount(
    String method,
    String path,
    Map<String, dynamic> params,
    MembershipIdentity account,
    bool Function()? isCurrent,
  );
}

class NadyProfileFeatureApi extends NadyMembershipApi
    implements ProfileSessionTransport {
  NadyProfileFeatureApi(super.http);
  @override
  Future<Object?> forAccount(
    String method,
    String path,
    Map<String, dynamic> params,
    MembershipIdentity account,
    bool Function()? isCurrent,
  ) {
    final options = Options(
      extra: {
        HttpDioManager.expectedAuthUid: account.uid,
        HttpDioManager.expectedAuthToken: account.token,
        if (isCurrent != null) HttpDioManager.requestIsCurrent: isCurrent,
      },
    );
    return method == 'GET'
        ? http.get(path, queryParameters: params, options: options)
        : http.post(path, data: params, options: options);
  }
}

/// Shared transport/session boundary, not a second wallet or user cache.
class ProfileFeatureRepository {
  ProfileFeatureRepository(
    this.api, {
    required this.identity,
    this.environment = '',
    this.language = 'en',
    this.refresh,
  });
  final MembershipApi api;
  final Future<MembershipIdentity> Function() identity;
  final String environment, language;
  final Future<void> Function()? refresh;

  Future<void> check(MembershipIdentity expected) async {
    if (await identity() != expected ||
        environment.isNotEmpty &&
            environment != AppConfig.shared.appEnv.baseUrl) {
      throw const NadyApiException(message: 'Login session changed');
    }
  }

  Future<Object?> request(
    String method,
    String path, {
    Map<String, dynamic> params = const {},
    MembershipIdentity? account,
    bool Function()? isCurrent,
  }) async {
    final expected = account ?? await identity();
    await check(expected);
    if (isCurrent?.call() == false) {
      throw const NadyApiException(message: 'Page closed');
    }
    final transport = api;
    final raw = transport is ProfileSessionTransport
        ? await (transport as ProfileSessionTransport).forAccount(
            method,
            path,
            params,
            expected,
            isCurrent,
          )
        : method == 'GET'
        ? await api.get(path, params.isEmpty ? null : params)
        : await api.post(path, params);
    await check(expected);
    if (isCurrent?.call() == false) {
      throw const NadyApiException(message: 'Page closed');
    }
    final server = NadyServerResponse<Object?>.fromJson(
      membershipMap(raw),
      (data) => data,
    );
    if (!server.isSuccess) throw server.toException();
    return server.data;
  }

  /// Business success remains success when the follow-up refresh fails.
  Future<bool> synchronize(MembershipIdentity account) async {
    await check(account);
    try {
      await refresh?.call();
      await check(account);
      return true;
    } catch (_) {
      await check(account);
      return false;
    }
  }
}
