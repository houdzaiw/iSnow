enum ProfileRelationType {
  followers('followers', 'profile.followers'),
  following('following', 'profile.following'),
  visitors('visitors', 'profile.visitors');

  const ProfileRelationType(this.routeKey, this.titleKey);

  final String routeKey;
  final String titleKey;

  bool get showsFollowButton => this != visitors;
  bool get showsVisitTime => this == visitors;

  static ProfileRelationType fromRoute(String value) {
    return ProfileRelationType.values.firstWhere(
      (item) => item.routeKey == value,
      orElse: () => ProfileRelationType.followers,
    );
  }
}
