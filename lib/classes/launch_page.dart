import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:project/manager/user_manager.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 短暂停留展示启动图
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // 使用 UserManager 检查登录状态（已在 AppConfig.run 中 restore）
    if (UserManager.shared.isLoggedIn) {
      context.go('/calendar');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: const Color(0xFFFDF5EB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/base/launch_bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
