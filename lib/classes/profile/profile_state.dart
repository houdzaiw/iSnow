import 'profile_menu_item.dart';
import 'profile_models.dart';

const Object _profileStateUnset = Object();

class ProfileState {
  ProfileState({
    required this.quickItems,
    required this.featureItems,
    required this.legalItems,
    required this.accountItems,
    required this.badgeItems,
    this.profile,
    this.isLoading = false,
    this.isSubmitting = false,
    this.loadError,
    this.actionError,
  });

  factory ProfileState.initial() {
    return ProfileState(
      quickItems: ProfileMenuData.getQuickItems(),
      featureItems: ProfileMenuData.getFeatureItems(),
      legalItems: ProfileMenuData.getLegalItems(),
      accountItems: ProfileMenuData.getAccountItems(),
      badgeItems: ProfileMenuData.getBadgeItems(),
    );
  }

  final ProfileAccountSummary? profile;
  final bool isLoading;
  final bool isSubmitting;
  final Object? loadError;
  final Object? actionError;
  final List<ProfileMenuItem> quickItems;
  final List<ProfileMenuItem> featureItems;
  final List<ProfileMenuItem> legalItems;
  final List<ProfileMenuItem> accountItems;
  final List<ProfileBadgeItem> badgeItems;

  String? get avatarUrl {
    final avatar = profile?.user.avatar?.trim();
    return avatar == null || avatar.isEmpty ? null : avatar;
  }

  int get gender => profile?.user.gender ?? 0;

  String displayName(String fallback) {
    final nick = profile?.user.nick?.trim();
    if (nick == null || nick.isEmpty) return fallback;
    return nick;
  }

  String displayUserId() {
    final userNo = profile?.user.userNo;
    if (userNo != null && userNo > 0) return 'ID:$userNo';
    final uid = profile?.user.uid;
    if (uid != null && uid > 0) return 'ID:$uid';
    return 'ID:--';
  }

  String displayRegion(String fallback) {
    final region = profile?.user.region?.trim();
    if (region != null && region.isNotEmpty) return region;
    final countryCode = profile?.user.countryCode?.trim();
    if (countryCode != null && countryCode.isNotEmpty) return countryCode;
    return fallback;
  }

  List<ProfileMetricItem> get metricItems {
    final data = profile;
    return [
      ProfileMetricItem(
        value: _formatCompactCount(data?.followingNum ?? 0),
        titleKey: 'profile.following',
      ),
      ProfileMetricItem(
        value: _formatCompactCount(data?.followerNum ?? 0),
        titleKey: 'profile.followers',
      ),
      ProfileMetricItem(
        value: _formatCompactCount(data?.visitorNum ?? 0),
        titleKey: 'profile.visitors',
      ),
    ];
  }

  ProfileState copyWith({
    ProfileAccountSummary? profile,
    bool? isLoading,
    bool? isSubmitting,
    Object? loadError = _profileStateUnset,
    Object? actionError = _profileStateUnset,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      loadError: identical(loadError, _profileStateUnset)
          ? this.loadError
          : loadError,
      actionError: identical(actionError, _profileStateUnset)
          ? this.actionError
          : actionError,
      quickItems: quickItems,
      featureItems: featureItems,
      legalItems: legalItems,
      accountItems: accountItems,
      badgeItems: badgeItems,
    );
  }
}

String _formatCompactCount(int value) {
  if (value >= 1000000) {
    final formatted = (value / 1000000).toStringAsFixed(
      value % 1000000 == 0 ? 0 : 1,
    );
    return '${_trimTrailingZero(formatted)}M';
  }
  if (value >= 1000) {
    final formatted = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
    return '${_trimTrailingZero(formatted)}K';
  }
  return value.toString();
}

String _trimTrailingZero(String value) {
  return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
}
