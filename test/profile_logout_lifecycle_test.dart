import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/profile/mine/profile_models.dart';
import 'package:project/classes/profile/mine/profile_repository.dart';
import 'package:project/classes/profile/mine/profile_view_model.dart';
import 'package:project/model/user_profile.dart';

void main() {
  test(
    'logout debounces and late profile data cannot restore old account',
    () async {
      final repository = _ProfileRepository();
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        profileViewModelProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      final model = container.read(profileViewModelProvider.notifier);
      expect(
        container.read(profileViewModelProvider).profile?.user.nick,
        'Cached',
      );
      final logout = model.logout();
      expect(await model.logout(), isFalse);
      expect(repository.logoutCalls, 1);
      repository.logoutGate.complete();
      expect(await logout, isTrue);
      repository.fetchGate.complete(_profile('Old server data'));
      await Future<void>.delayed(Duration.zero);
      final state = container.read(profileViewModelProvider);
      expect(state.profile, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.loadError, isNull);
    },
  );

  test(
    'disposed profile requests are ignored; next page gets a fresh model',
    () async {
      final repository = _ProfileRepository();
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        profileViewModelProvider,
        (_, __) {},
      );
      await Future<void>.delayed(Duration.zero);
      final first = container.read(profileViewModelProvider.notifier);
      subscription.close();
      await container.pump();
      repository.fetchGate.complete(_profile('Old server data'));
      await Future<void>.delayed(Duration.zero);
      final nextSubscription = container.listen(
        profileViewModelProvider,
        (_, __) {},
      );
      addTearDown(nextSubscription.close);
      final next = container.read(profileViewModelProvider.notifier);
      expect(next, isNot(same(first)));
      expect(container.read(profileViewModelProvider).profile, isNull);
    },
  );
}

ProfileAccountSummary _profile(String name) =>
    ProfileAccountSummary.cached(UserData(uid: 10, nick: name));

class _ProfileRepository implements ProfileRepository {
  final fetchGate = Completer<ProfileAccountSummary>();
  final logoutGate = Completer<void>();
  int logoutCalls = 0;
  @override
  Future<ProfileAccountSummary?> cachedProfile() async => _profile('Cached');
  @override
  Future<ProfileAccountSummary> fetchProfile() => fetchGate.future;
  @override
  Future<void> logout() async {
    logoutCalls++;
    await logoutGate.future;
  }

  @override
  Future<void> deleteAccount() => logout();
}
