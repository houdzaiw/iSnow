// dart
import 'package:flutter/material.dart';

class ProfileMenuItem {
  final IconData icon;
  final String titleKey;
  final String action;
  final IconData arrow;

  ProfileMenuItem({
    required this.icon,
    required this.titleKey,
    required this.action,
    this.arrow = Icons.arrow_forward_ios,
  });
}

class ProfileMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return [
      ProfileMenuItem(
        icon: Icons.article_rounded,
        titleKey: 'profile.myPosts',
        action: 'my-posts',
      ),
      ProfileMenuItem(
        icon: Icons.lock_rounded,
        titleKey: 'profile.privacy',
        action: 'privacy',
      ),
      ProfileMenuItem(
        icon: Icons.info_rounded,
        titleKey: 'profile.aboutUs',
        action: 'about-us',
      ),
      ProfileMenuItem(
        icon: Icons.chat_bubble_rounded,
        titleKey: 'profile.contactUs',
        action: 'contact-us',
      ),
      ProfileMenuItem(
        icon: Icons.settings_rounded,
        titleKey: 'profile.settings',
        action: 'settings',
      ),
    ];
  }
}
