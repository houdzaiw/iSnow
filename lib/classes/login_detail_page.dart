import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginDetailPage extends StatefulWidget {
  const LoginDetailPage({super.key});

  @override
  State<LoginDetailPage> createState() => _LoginDetailPageState();
}

class _LoginDetailPageState extends State<LoginDetailPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/base/base_bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    //Please enter your email
                    const Text(
                      'Please enter your email',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 邮箱输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Your Email address',
                          filled: true,
                          fillColor: const Color(0xFFFDF5EB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Please enter your password
                    const Text(
                      'Please enter your password',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 密码输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Your password',
                          filled: true,
                          fillColor: const Color(0xFFFDF5EB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          isDense: true,
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 登录按钮
                    GestureDetector(
                      onTap: () {
                        context.go('/home');
                      },
                      child: Container(
                        width: 280,
                        height: 53,
                        decoration: const BoxDecoration(
                          //背景色#F9E707
                          color: Color(0xFFF9E707),
                          borderRadius: BorderRadius.all(Radius.circular(28)),
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // 关闭按钮
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    context.pop();
                  },
                  child: Image.asset(
                    'assets/base/close_button_image.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

