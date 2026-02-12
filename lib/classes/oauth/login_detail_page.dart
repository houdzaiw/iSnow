import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'provider/login_provider.dart';

class LoginDetailPage extends HookConsumerWidget {
  const LoginDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController(text: "13104889693");
    final passwordController = useTextEditingController(text: "123456");
    final isLoading = useState(false);
    final agreeToTerms = useState(false);
    final loginProvider = ref.watch(loginProviderProvider);

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

      // 验证是否同意协议
      if (!agreeToTerms.value) {
        context.push('/agree_policy-view');
        return;
      }

      // 开始加载
      isLoading.value = true;

      try {
        // 使用 LoginProvider 登录
        final response = await loginProvider.login(
          account: account,
          password: password,
          smsCode: "",
          areaCode: '966',
          countryCode: 'us',
        );

        if (!context.mounted) return;

        if (response.success) {
          // 登录成功
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Login successful')),
          );

          // TODO: 保存 token 和用户信息到本地存储
          final token = response.token;
          print('Login Token: $token');

          // 跳转到首页
          if (context.mounted) {
            context.go('/home');
          }
        } else {
          // 登录失败
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
                      'Please enter your phone number',
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
                          hintText: 'Your phone number',
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
                    // 隐私协议和用户协议
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            agreeToTerms.value = !agreeToTerms.value;
                          },
                          child: Container(
                            width: 15,
                            height: 15,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFFF7F00),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(9),
                              color: agreeToTerms.value
                                  ? const Color(0xFFF9E707)
                                  : Colors.white,
                            ),
                            child: agreeToTerms.value
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Color(0xFF212121),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF212121),
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Logging in means you agree to the ',
                                ),
                                TextSpan(
                                  text: 'user service agreement',
                                  style: const TextStyle(
                                    color: Color(0xFFFF8000),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      context.push(
                                        '/web-view?title=User Privacy&uri=https://www.example.com/user-privacy',
                                      );
                                    },
                                ),
                                const TextSpan(
                                  text: ' and ',
                                ),
                                TextSpan(
                                  text: 'private policy',
                                  style: const TextStyle(
                                    color: Color(0xFFFF8000),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      context.push(
                                        '/web-view?title=User Privacy&uri=https://www.example.com/user-privacy',
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
