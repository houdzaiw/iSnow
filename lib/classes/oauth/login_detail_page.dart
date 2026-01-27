import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'provider/login_provider.dart';

class LoginDetailPage extends HookConsumerWidget {
  const LoginDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final loginProvider = useMemoized(() => LoginProvider());
    final isLoading = useState(false);

    Future<void> handleLogin() async {
      final account = emailController.text.trim();
      final password = passwordController.text.trim();

      // 验证输入
      if (account.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email or phone')),
        );
        return;
      }

      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password')),
        );
        return;
      }

      // 开始加载
      isLoading.value = true;

      try {
        // 调用登录接口
        final response = await loginProvider.login(
          account: account,
          password: password,
          loginType: 5,
          areaCode: '1',
          countryCode: 'us',
        );

        if (!context.mounted) return;

        if (response.success) {
          // 登录成功，保存token和用户信息
          if (response.token != null) {
            // TODO: 保存token到本地存储
            print('Token: ${response.token}');
          }

          if (response.data != null) {
            // TODO: 保存用户信息到本地存储
            print('User: ${response.data?.email}');
          }

          // 跳转到首页
          if (context.mounted) {
            context.go('/home');
          }
        } else {
          // 登录失败，显示错误信息
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message ?? 'Login failed')),
            );
          }
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: null,
      backgroundColor: const Color(0xFFFDF5EB),
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
                        controller: emailController,
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
                        controller: passwordController,
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
                      onTap: isLoading.value ? null : handleLogin,
                      child: Container(
                        width: 280,
                        height: 53,
                        decoration: const BoxDecoration(
                          //背景色#F9E707
                          color: Color(0xFFF9E707),
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                        ),
                        alignment: Alignment.center,
                        child: isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF212121),
                                ),
                              )
                            : const Text(
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

