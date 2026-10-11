import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'profile_repository.dart';
import 'profile_state.dart';

final profileViewModelProvider =
    NotifierProvider.autoDispose<ProfileViewModel, ProfileState>(
      ProfileViewModel.new,
    );

class ProfileViewModel extends AutoDisposeNotifier<ProfileState> {
  int _loadRevision = 0;
  bool _alive = true;
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    ref.onDispose(() {
      _alive = false;
      _loadRevision += 1;
    });
    Future.microtask(loadProfile);
    return ProfileState.initial();
  }

  Future<void> loadProfile() async {
    if (!_alive || state.isSubmitting) return;
    final revision = ++_loadRevision;
    if (state.profile == null) {
      await _loadCachedProfile(revision);
    }
    if (revision != _loadRevision) return;

    state = state.copyWith(isLoading: true, loadError: null);
    try {
      final profile = await _repository.fetchProfile();
      if (revision != _loadRevision) return;
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        loadError: null,
      );
    } catch (error) {
      if (revision != _loadRevision) return;
      state = state.copyWith(isLoading: false, loadError: error);
    }
  }

  Future<bool> logout() {
    return _runAccountAction(_repository.logout);
  }

  Future<bool> deleteAccount() {
    return _runAccountAction(_repository.deleteAccount);
  }

  Future<void> _loadCachedProfile(int revision) async {
    try {
      final cached = await _repository.cachedProfile();
      if (cached != null && revision == _loadRevision) {
        state = state.copyWith(profile: cached);
      }
    } catch (_) {
      // Cached user is only a warm start; network state below remains canonical.
    }
  }

  Future<bool> _runAccountAction(Future<void> Function() action) async {
    if (!_alive || state.isSubmitting) return false;
    _loadRevision += 1;
    state = state.copyWith(isSubmitting: true, actionError: null);
    try {
      await action();
      if (!_alive) return true;
      state = ProfileState.initial();
      return true;
    } catch (error) {
      if (!_alive) return false;
      state = state.copyWith(isSubmitting: false, actionError: error);
      return false;
    }
  }
}
