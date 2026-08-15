import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'profile_repository.dart';
import 'profile_state.dart';

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);

class ProfileViewModel extends Notifier<ProfileState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ProfileState build() {
    Future.microtask(loadProfile);
    return ProfileState.initial();
  }

  Future<void> loadProfile() async {
    if (state.profile == null) {
      await _loadCachedProfile();
    }

    state = state.copyWith(isLoading: true, loadError: null);
    try {
      final profile = await _repository.fetchProfile();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        loadError: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, loadError: error);
    }
  }

  Future<bool> logout() {
    return _runAccountAction(_repository.logout);
  }

  Future<bool> deleteAccount() {
    return _runAccountAction(_repository.deleteAccount);
  }

  Future<void> _loadCachedProfile() async {
    try {
      final cached = await _repository.cachedProfile();
      if (cached != null) {
        state = state.copyWith(profile: cached);
      }
    } catch (_) {
      // Cached user is only a warm start; network state below remains canonical.
    }
  }

  Future<bool> _runAccountAction(Future<void> Function() action) async {
    state = state.copyWith(isSubmitting: true, actionError: null);
    try {
      await action();
      state = state.copyWith(isSubmitting: false, actionError: null);
      return true;
    } catch (error) {
      state = state.copyWith(isSubmitting: false, actionError: error);
      return false;
    }
  }
}
