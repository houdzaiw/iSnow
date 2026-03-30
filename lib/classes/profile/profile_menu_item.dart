// dart
import 'package:flutter/material.dart';

class ProfileMenuItem {
  final String? icon;
  final String name;
  final IconData arrow;
  final String router;

  ProfileMenuItem({
    this.icon,
    required this.name,
    this.arrow = Icons.arrow_forward_ios,
    this.router = "",
  });
}

class ProfileMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return [
      ProfileMenuItem(
        icon: "assets/profile/my_posts_icon.png",
        name: 'My Posts',
        router: "/my-posts",
      ),
      ProfileMenuItem(
        icon: "assets/profile/block_us_icon.png",
        name: 'Block List',
        router: "/block-list",
      ),
      ProfileMenuItem(
        icon: "assets/profile/contact_us_icon.png",
        name: 'Contact Us',
        router: "/about-us",
      ),
      ProfileMenuItem(
        icon: "assets/profile/setting_icon.png",
        name: 'Settings',
        router: "/setting-view",
      ),
      ProfileMenuItem(
        icon: "assets/profile/delete_account_icon.png",
        name: 'Delete Account',
      ),
      ProfileMenuItem(
        icon: "assets/profile/log_out_icon.png",
        name: 'Log Out',
      ),
    ];
  }
}

class SettingMenuData {
  static List<ProfileMenuItem> getMenuItems() {
    return [
      ProfileMenuItem(
        name: 'About Us',
        router: "/about-us",
      ),
      ProfileMenuItem(
        name: 'User Agreement',
        router: "/web-view?title=User Agreement&uri=https://www.example.com/user-agreement",
      ),
      ProfileMenuItem(
        name: 'Privacy Policy',
        router: "/web-view?title=Privacy Policy&uri=https://www.example.com/privacy-policy",
      ),

    ];
  }
}

