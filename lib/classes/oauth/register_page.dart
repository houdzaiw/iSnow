import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
      extendBodyBehindAppBar: true,
      appBar: null,
      backgroundColor: AppColors.creamBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: AppGradients.authBackground),
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
                    Text(
                      context.l10n.t('auth.registerEmailLabel'),
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 邮箱输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'example@gmail.com',
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
                    Text(
                      context.l10n.t('auth.passwordLabel'),
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 密码输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: context.l10n.t('auth.passwordHint'),
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
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      context.l10n.t('auth.confirmPasswordLabel'),
                      style: AppTextStyles.bodyStrong,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 密码输入框
                    SizedBox(
                      height: 43,
                      child: TextField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          hintText: context.l10n.t('auth.confirmPasswordHint'),
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
                      onTap: () {
                        context.go('/home');
                      },
                      child: Container(
                        width: 280,
                        height: 53,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          context.l10n.t('auth.register'),
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
