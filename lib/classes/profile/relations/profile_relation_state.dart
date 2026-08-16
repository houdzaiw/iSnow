import 'profile_relation_models.dart';
import 'profile_relation_type.dart';

const Object _profileRelationUnset = Object();

class ProfileRelationState {
  const ProfileRelationState({
    required this.type,
    this.items = const [],
    this.pageNum = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isUpdatingFollow = false,
    this.error,
  });

  final ProfileRelationType type;
  final List<ProfileRelationUser> items;
  final int pageNum;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isUpdatingFollow;
  final Object? error;

  ProfileRelationState copyWith({
    List<ProfileRelationUser>? items,
    int? pageNum,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isUpdatingFollow,
    Object? error = _profileRelationUnset,
  }) {
    return ProfileRelationState(
      type: type,
      items: items ?? this.items,
      pageNum: pageNum ?? this.pageNum,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUpdatingFollow: isUpdatingFollow ?? this.isUpdatingFollow,
      error: identical(error, _profileRelationUnset) ? this.error : error,
    );
  }
}
