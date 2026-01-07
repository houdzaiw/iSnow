import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    // 模拟检查登录状态的异步操作
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // TODO: 替换为真实的登录状态检查逻辑
    // 例如：从 SharedPreferences、Riverpod Provider 或其他状态管理中获取
    final bool isLoggedIn = await _isUserLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // 已登录，跳转到首页
      context.go('/home');
    } else {
      // 未登录，跳转到登录页
      context.go('/login');
    }
  }

  Future<bool> _isUserLoggedIn() async {
    // TODO: 实现真实的登录状态检查
    // 例如：
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString('token') != null;

    // 目前返回 false，表示未登录
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              '加载中...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
