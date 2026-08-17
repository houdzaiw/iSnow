import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'profile_homepage_repository.dart';
import 'profile_homepage_state.dart';

final profileHomepageViewModelProvider =
    NotifierProvider.family<
      ProfileHomepageViewModel,
      ProfileHomepageState,
      int
    >(ProfileHomepageViewModel.new);

class ProfileHomepageViewModel
    extends FamilyNotifier<ProfileHomepageState, int> {
  late final ProfileHomepageRepository _repository;

  @override
  ProfileHomepageState build(int arg) {
    _repository = ProfileHomepageRepository();
    Future.microtask(refresh);
    return ProfileHomepageState(targetUid: arg);
  }

  Future<void> refresh() async {
    if (state.targetUid <= 0) {
      state = state.copyWith(error: ArgumentError('Missing target uid'));
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final info = await _repository.fetch(targetUid: state.targetUid);
      state = state.copyWith(info: info, isLoading: false, error: null);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> toggleFollow() async {
    final info = state.info;
    if (info == null || info.user.uid <= 0 || state.isUpdatingFollow) return;

    final nextFollowing = !info.user.isFollowing;
    state = state.copyWith(isUpdatingFollow: true);
    try {
      await _repository.setFollowing(
        targetUid: info.user.uid,
        isFollowing: nextFollowing,
      );
      state = state.copyWith(
        info: info.copyWith(
          user: info.user.copyWith(isFollowing: nextFollowing),
        ),
        isUpdatingFollow: false,
      );
    } catch (error) {
      state = state.copyWith(isUpdatingFollow: false, error: error);
    }
  }
}
