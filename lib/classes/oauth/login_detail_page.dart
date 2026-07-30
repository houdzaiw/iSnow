import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../theme/app_theme.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入邮箱或手机号')));
        return;
      }

      if (password.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入密码')));
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
            debugPrint('Token: ${response.token}');
          }

          if (response.data != null) {
            // TODO: 保存用户信息到本地存储
            debugPrint('User: ${response.data?.email}');
          }

          // 跳转到首页
          if (context.mounted) {
            context.go('/home');
          }
        } else {
          // 登录失败，显示错误信息
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(response.message ?? '登录失败')));
          }
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录异常：$e')));
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: null,
      backgroundColor: AppColors.creamBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.authBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: AppRadius.dialogBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    const Text('请输入邮箱', style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.sm),
                    // 邮箱输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: '请输入邮箱地址',
                          filled: true,
                          fillColor: AppColors.fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.fieldBorder,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    const Text('请输入密码', style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.sm),
                    // 密码输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText: '请输入密码',
                          filled: true,
                          fillColor: AppColors.fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.fieldBorder,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          isDense: true,
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    // 登录按钮
                    GestureDetector(
                      onTap: isLoading.value ? null : handleLogin,
                      child: Container(
                        width: 280,
                        height: 53,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        alignment: Alignment.center,
                        child: isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textInverse,
                                ),
                              )
                            : Text(
                                '登录',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.textInverse,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
                    AppAssets.lanhuCloseCircle,
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
