// dart
import '../../theme/app_theme.dart';

class ProfileMenuItem {
  final String? iconAsset;
  final String titleKey;
  final String action;

  ProfileMenuItem(this.iconAsset,{
    required this.titleKey,
    required this.action,
  });
}

class ProfileMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return [
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
}
class SettingMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return [
      ProfileMenuItem(
        null,
        titleKey: 'About Us',
        action: "/about-us",
      ),
      ProfileMenuItem(
        null,
        titleKey: 'User Agreement',
        action: "/web-view?title=User Agreement&uri=https://www.example.com/user-agreement",
      ),
      ProfileMenuItem(
        null,
        titleKey: 'Privacy Policy',
        action: "/web-view?title=Privacy Policy&uri=https://www.example.com/privacy-policy",
      ),

    ];
  }
}