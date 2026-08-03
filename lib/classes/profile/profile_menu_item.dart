// dart
import '../../theme/app_theme.dart';

class ProfileMenuItem {
  final String iconAsset;
  final String titleKey;
  final String action;

  ProfileMenuItem({
    required this.iconAsset,
    required this.titleKey,
    required this.action,
  });
}

class ProfileMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return [
      ProfileMenuItem(
        iconAsset: AppAssets.profileMenuMyPosts,
        titleKey: 'profile.myPosts',
        action: 'my-posts',
      ),
      ProfileMenuItem(
        iconAsset: AppAssets.profileMenuBlockList,
        titleKey: 'profile.blockList',
        action: 'block-list',
      ),
      ProfileMenuItem(
        iconAsset: AppAssets.profileMenuContactUs,
        titleKey: 'profile.contactUs',
        action: 'contact-us',
      ),
      ProfileMenuItem(
        iconAsset: AppAssets.profileMenuSettings,
        titleKey: 'profile.settings',
        action: 'settings',
      ),
      ProfileMenuItem(
        iconAsset: AppAssets.profileMenuDeleteAccount,
        titleKey: 'profile.deleteAccount',
        action: 'delete-account',
      ),
      ProfileMenuItem(
        iconAsset: AppAssets.profileMenuLogOut,
        titleKey: 'profile.logOut',
        action: 'log-out',
      ),
    ];
  }
}
