import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/base/base_bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text(
                '创建账号',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 40),
              // 邮箱输入框
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: '邮箱',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // 密码输入框
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: '密码',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              // 确认密码输入框
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: '确认密码',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              // 注册按钮
              GestureDetector(
                onTap: () {
                  // TODO: 实现真实的注册逻辑
                  // 验证邮箱格式
                  // 验证密码强度
                  // 验证两次密码是否一致
                  // 调用注册 API

                  // 注册成功后可以选择：
                  // 1. 跳转到登录页
                  // context.go('/login');
                  // 2. 自动登录并跳转到首页
                  // context.go('/home');

                  // 临时：直接跳转到首页
                  context.go('/home');
                },
                child: Container(
                  width: 280,
                  height: 56,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/base/button_bg_image.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '注册',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 已有账号？去登录
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '已有账号？',
                    style: TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 跳转到登录详情页
                      context.push('/login-detail');
                    },
                    child: const Text(
                      '去登录',
                      style: TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

