import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: AppColors.cardBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.lanhuLoginBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () {
                // 跳转到登录详情页
                context.push('/login-detail');
              },
              child: Container(
                width: 298,
                height: 61,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppAssets.lanhuAuthButtonPrimary),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('登录', style: AppTextStyles.button),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // 跳转到注册页
                context.push('/register');
              },
              child: Container(
                width: 298,
                height: 61,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppAssets.lanhuAuthButtonSecondary),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('注册', style: AppTextStyles.button),
              ),
            ),
            SizedBox(height: 126 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
