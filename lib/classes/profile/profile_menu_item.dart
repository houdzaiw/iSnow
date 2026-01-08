// dart
import 'package:flutter/material.dart';

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
      ProfileMenuItem(
        icon: "assets/profile/my_posts_icon.png",
        name: 'My Posts',
      ),
      ProfileMenuItem(
        icon: "assets/profile/user_privacy_icon.png",
        name: 'User Privacy',
      ),
      ProfileMenuItem(
        icon: "assets/profile/about_us_icon.png",
        name: 'About Us',
      ),
      ProfileMenuItem(
        icon: "assets/profile/contact_us_icon.png",
        name: 'Contact Us',
      ),
      ProfileMenuItem(
        icon: "assets/profile/setting_icon.png",
        name: 'Settings',
      ),
    ];
  }
}

