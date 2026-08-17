import 'profile_homepage_models.dart';

const Object _profileHomepageUnset = Object();

class ProfileHomepageState {
  const ProfileHomepageState({
    required this.targetUid,
    this.info,
    this.isLoading = false,
    this.isUpdatingFollow = false,
    this.error,
  });

  final int targetUid;
  final ProfileHomepageInfo? info;
  final bool isLoading;
  final bool isUpdatingFollow;
  final Object? error;

  ProfileHomepageState copyWith({
    ProfileHomepageInfo? info,
    bool? isLoading,
    bool? isUpdatingFollow,
    Object? error = _profileHomepageUnset,
  }) {
    return ProfileHomepageState(
      targetUid: targetUid,
      info: info ?? this.info,
      isLoading: isLoading ?? this.isLoading,
      isUpdatingFollow: isUpdatingFollow ?? this.isUpdatingFollow,
      error: identical(error, _profileHomepageUnset) ? this.error : error,
    );
  }
}
