import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/base/launch_bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            // Login 按钮
            GestureDetector(
              onTap: () {
                // 跳转到登录详情页
                context.push('/login-detail');
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
                  'Login',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF212121),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Register 按钮
            GestureDetector(
              onTap: () {
                // 跳转到注册页
                context.push('/register');
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
                  'Register',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF212121),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 126 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

