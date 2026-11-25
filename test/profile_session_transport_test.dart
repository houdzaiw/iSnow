import 'dart:typed_data';
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/manager/auth_session.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/user_profile.dart';
import 'package:project/classes/profile/mine/profile_models.dart';
import 'package:project/classes/profile/mine/profile_repository.dart';
import 'package:project/classes/profile/mine/profile_view_model.dart';
import 'package:project/classes/profile/membership/membership_session.dart';

class _Session extends MembershipSession {
  void change() => notifyListeners();
}

class _Profiles implements ProfileRepository {
  int uid = 10;
  final requests = <Completer<ProfileAccountSummary>>[];
  @override
  Future<ProfileAccountSummary?> cachedProfile() async =>
      ProfileAccountSummary.cached(
        UserData(uid: uid, roleType: uid == 10 ? 3 : 0),
      );
  @override
  Future<ProfileAccountSummary> fetchProfile() {
    final pending = Completer<ProfileAccountSummary>();
    requests.add(pending);
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Adapter implements HttpClientAdapter {
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      '{"code":200,"data":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'nady.pubUid': 10,
      'nady.oauthToken': 'fixture',
      'nady.phone': 'old',
      'nady.areaCode': '1',
    }),
  );
  test(
    'profile discards previous role and pending response when login generation changes',
    () async {
      final session = _Session(), profiles = _Profiles();
      final container = ProviderContainer(
        overrides: [
          membershipSessionProvider.overrideWith((ref) => session),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(profileViewModelProvider, (_, __) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(profileViewModelProvider).profile!.user.roleType,
        3,
      );
      profiles.uid = 11;
      session.change();
      await container.pump();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(profileViewModelProvider).profile!.user.uid, 11);
      profiles.requests.first.complete(
        ProfileAccountSummary.cached(const UserData(uid: 10, roleType: 3)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(profileViewModelProvider).profile!.user.roleType,
        0,
      );
      profiles.requests.last.complete(
        ProfileAccountSummary.cached(const UserData(uid: 11, roleType: 0)),
      );
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'phone binding metadata updates cached profile without changing login generation',
    () async {
      await AuthSession.instance.saveUser(
        const UserData(uid: 10, nick: 'Owner', phone: 'old', areaCode: '1'),
      );
      var changes = 0;
      void listener() => changes++;
      AuthSession.instance.addListener(listener);
      addTearDown(() => AuthSession.instance.removeListener(listener));
      await AuthSession.instance.saveBoundPhone(
        expectedUid: 10,
        expectedToken: 'fixture',
        phone: '55555555',
        areaCode: '966',
      );
      expect(await AuthSession.instance.phone(), '55555555');
      expect((await AuthSession.instance.user())!.phone, '55555555');
      expect((await AuthSession.instance.user())!.areaCode, '966');
      expect(changes, 0);
      await AuthSession.instance.saveBoundPhone(
        expectedUid: 11,
        expectedToken: 'other',
        phone: 'evil',
        areaCode: '44',
      );
      expect(await AuthSession.instance.phone(), '55555555');
    },
  );
  test(
    'late auth change or page closure is rejected before network dispatch',
    () async {
      final http = HttpDioManager(), adapter = _Adapter();
      final old = http.getDio().httpClientAdapter;
      http.getDio().httpClientAdapter = adapter;
      addTearDown(() => http.getDio().httpClientAdapter = old);
      Options guard(int uid, bool current) => Options(
        extra: {
          HttpDioManager.expectedAuthUid: uid,
          HttpDioManager.expectedAuthToken: 'fixture',
          HttpDioManager.requestIsCurrent: () => current,
        },
      );
      for (final options in [guard(11, true), guard(10, false)]) {
        await expectLater(
          http.post('/api/profile/tools/fixture', data: {}, options: options),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'cancel',
              DioExceptionType.cancel,
            ),
          ),
        );
      }
      expect(adapter.calls, 0);
      await http.post(
        '/api/profile/tools/fixture',
        data: {},
        options: guard(10, true),
      );
      expect(adapter.calls, 1);
    },
  );
}
