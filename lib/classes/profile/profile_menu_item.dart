import '../../theme/app_theme.dart';

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
  });

  final String iconAsset;
  final String titleKey;
  final String webPath;
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
        AppAssets.lanhuProfileQuickRecharge,
        titleKey: 'profile.recharge',
        action: 'recharge',
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
    ];
  }

  static List<ProfileMenuItem> getLegalItems() {
    return const [
      ProfileMenuItem(
        AppAssets.profileAboutIcon,
        titleKey: 'profile.aboutUs',
        action: 'about-us',
      ),
      ProfileMenuItem(
        AppAssets.profilePrivacyIcon,
        titleKey: 'settings.privacyPolicy',
        action: 'privacy-policy',
      ),
      ProfileMenuItem(
        null,
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

  static List<ProfileBadgeItem> getBadgeItems() {
    return const [
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge01,
        titleKey: 'profile.myTeam',
        webPath: '/h5/profile/my-team.html',
      ),
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge02,
        titleKey: 'profile.agent',
        webPath: '/h5/profile/agent.html',
      ),
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge03,
        titleKey: 'profile.bd',
        webPath: '/h5/profile/bd.html',
      ),
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge04,
        titleKey: 'profile.host',
        webPath: '/h5/profile/host.html',
      ),
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge05,
        titleKey: 'profile.manage',
        webPath: '/h5/profile/manage.html',
      ),
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge06,
        titleKey: 'profile.dailyReward',
        webPath: '/h5/profile/daily-reward.html',
      ),
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge07,
        titleKey: 'profile.saleCoin',
        webPath: '/h5/profile/sale-coin.html',
      ),
      ProfileBadgeItem(
        iconAsset: AppAssets.lanhuProfileBadge08,
        titleKey: 'profile.gameCoin',
        webPath: '/h5/profile/game-coin.html',
      ),
    ];
  }
}

class SettingMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return const [
      ProfileMenuItem(null, titleKey: 'About Us', action: '/about-us'),
      ProfileMenuItem(
        null,
        titleKey: 'User Agreement',
        action:
            '/web-view?title=User Agreement&uri=https://www.example.com/user-agreement',
      ),
      ProfileMenuItem(
        null,
        titleKey: 'Privacy Policy',
        action:
            '/web-view?title=Privacy Policy&uri=https://www.example.com/privacy-policy',
      ),
    ];
  }
}
