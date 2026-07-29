// dart
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProfileMenuItem {
  final String icon;
  final String name;
  final IconData arrow;

  ProfileMenuItem({
    required this.icon,
    required this.name,
    this.arrow = Icons.arrow_forward_ios,
  });
}

class ProfileMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return [
      ProfileMenuItem(icon: AppAssets.profileMyPostsIcon, name: '我的帖子'),
      ProfileMenuItem(icon: AppAssets.profilePrivacyIcon, name: '用户隐私'),
      ProfileMenuItem(icon: AppAssets.profileAboutIcon, name: '关于我们'),
      ProfileMenuItem(icon: AppAssets.profileContactIcon, name: '联系我们'),
      ProfileMenuItem(icon: AppAssets.profileSettingIcon, name: '设置'),
    ];
  }
}
