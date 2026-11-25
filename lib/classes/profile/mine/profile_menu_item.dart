import '../../../theme/app_theme.dart';

class ProfileMenuItem {
  const ProfileMenuItem(
    this.iconAsset, {
    required this.titleKey,
    required this.action,
  });

  final String? iconAsset;
  final String titleKey;
  final String action;
}

class ProfileBadgeItem {
  const ProfileBadgeItem({
    required this.iconAsset,
    required this.titleKey,
    required this.webPath,
    this.iconUrl = '',
    this.title = '',
    this.destination,
  });

  final String iconAsset;
  final String titleKey;
  final String webPath;
  final String iconUrl, title;
  final ProfileDestination? destination;
}

enum ProfileDestinationKind { wallet, store, dailyReward, web, native }

class ProfileDestination {
  const ProfileDestination(this.kind, this.target);
  final ProfileDestinationKind kind;
  final String target;
}

class ProfileMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return const [
      ProfileMenuItem(
        AppAssets.profileMenuMyPosts,
        titleKey: 'profile.myPosts',
        action: 'my-posts',
      ),
      ProfileMenuItem(
        AppAssets.profileMenuBlockList,
        titleKey: 'profile.blockList',
        action: 'block-list',
      ),
      ProfileMenuItem(
        AppAssets.profileMenuContactUs,
        titleKey: 'profile.contactUs',
        action: 'contact-us',
      ),
      ProfileMenuItem(
        AppAssets.profileMenuSettings,
        titleKey: 'profile.settings',
        action: 'settings',
      ),
      ProfileMenuItem(
        AppAssets.profileMenuDeleteAccount,
        titleKey: 'profile.deleteAccount',
        action: 'delete-account',
      ),
      ProfileMenuItem(
        AppAssets.profileMenuLogOut,
        titleKey: 'profile.logOut',
        action: 'log-out',
      ),
    ];
  }

  static List<ProfileMenuItem> getQuickItems() {
    return const [
      ProfileMenuItem(
        AppAssets.lanhuProfileQuickWallet,
        titleKey: 'profile.wallet',
        action: 'wallet',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileQuickInvite,
        titleKey: 'profile.inviteFriends',
        action: 'invite-friends',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileQuickStore,
        titleKey: 'profile.store',
        action: 'store',
      ),
    ];
  }

  static List<ProfileMenuItem> getFeatureItems() {
    return const [
      ProfileMenuItem(
        AppAssets.lanhuProfileMenuLevel,
        titleKey: 'profile.level',
        action: 'level',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileMenuBackpack,
        titleKey: 'profile.backpack',
        action: 'backpack',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileMenuHonor,
        titleKey: 'profile.honor',
        action: 'honor',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileMenuSetting,
        titleKey: 'profile.settings',
        action: 'settings',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileMenuAbout,
        titleKey: 'profile.aboutUs',
        action: 'about-us',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileMenuPrivacy,
        titleKey: 'settings.privacyPolicy',
        action: 'privacy-policy',
      ),
      ProfileMenuItem(
        AppAssets.lanhuProfileMenuTerms,
        titleKey: 'settings.termsOfUse',
        action: 'terms-of-use',
      ),
    ];
  }

  static List<ProfileMenuItem> getAccountItems() {
    return const [
      ProfileMenuItem(
        AppAssets.profileMenuDeleteAccount,
        titleKey: 'profile.deleteAccount',
        action: 'delete-account',
      ),
      ProfileMenuItem(
        AppAssets.profileMenuLogOut,
        titleKey: 'profile.logOut',
        action: 'log-out',
      ),
    ];
  }

  // Business entries come from ProfileMenuRepository, not invented H5 paths.
  static List<ProfileBadgeItem> getBadgeItems() => const [];
}
