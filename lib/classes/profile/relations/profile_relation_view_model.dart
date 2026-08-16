import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'profile_relation_models.dart';
import 'profile_relation_repository.dart';
import 'profile_relation_state.dart';
import 'profile_relation_type.dart';

final profileRelationViewModelProvider =
    NotifierProvider.family<
      ProfileRelationViewModel,
      ProfileRelationState,
      ProfileRelationType
    >(ProfileRelationViewModel.new);

class ProfileRelationViewModel
    extends FamilyNotifier<ProfileRelationState, ProfileRelationType> {
  late final ProfileRelationRepository _repository;

  @override
  ProfileRelationState build(ProfileRelationType arg) {
    _repository = ProfileRelationRepository();
    Future.microtask(refresh);
    return ProfileRelationState(type: arg);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.fetch(type: state.type, pageNum: 1);
      state = state.copyWith(
        items: result.items,
        pageNum: result.pageNum,
        hasMore: result.hasMore,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.fetch(
        type: state.type,
        pageNum: state.pageNum + 1,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        pageNum: result.pageNum,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleFollow(ProfileRelationUser user) async {
    if (state.isUpdatingFollow || user.uid == 0) return;
    final nextFollowing = !user.isFollowing;
    state = state.copyWith(isUpdatingFollow: true);
    try {
      await _repository.setFollowing(
        targetUid: user.uid,
        isFollowing: nextFollowing,
      );
      state = state.copyWith(
        items: [
          for (final item in state.items)
            item.uid == user.uid
                ? item.copyWith(isFollowing: nextFollowing)
                : item,
        ],
        isUpdatingFollow: false,
      );
    } catch (_) {
      state = state.copyWith(isUpdatingFollow: false);
    }
  }
}
