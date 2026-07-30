// dart
import 'package:flutter/material.dart';

class ProfileMenuItem {
  final IconData icon;
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
      ProfileMenuItem(icon: Icons.article_rounded, name: '我的帖子'),
      ProfileMenuItem(icon: Icons.lock_rounded, name: '用户隐私'),
      ProfileMenuItem(icon: Icons.info_rounded, name: '关于我们'),
      ProfileMenuItem(icon: Icons.chat_bubble_rounded, name: '联系我们'),
      ProfileMenuItem(icon: Icons.settings_rounded, name: '设置'),
    ];
  }
}
