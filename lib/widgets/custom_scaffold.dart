import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String? rightIconPath;
  final String? rightText;
  final VoidCallback? onRightIconTap;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool extendBodyBehindAppBar;

  const CustomScaffold({
    super.key,
    required this.title,
    required this.body,
    this.rightIconPath,
    this.rightText,
    this.onRightIconTap,
    this.showBackButton = true,
    this.onBackPressed,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: Image.asset(
                  AppAssets.lanhuNavBack,
                  width: 20,
                  height: 20,
                ),
                onPressed: onBackPressed ?? () => context.pop(),
              )
            : null,
        title: Text(title, style: AppTextStyles.navTitle),
        centerTitle: true,
        actions: rightIconPath != null || rightText != null
            ? [
                if (rightText != null)
                  TextButton(
                    onPressed: onRightIconTap,
                    child: Text(rightText!, style: AppTextStyles.bodyStrong),
                  )
                else if (rightIconPath != null)
                  IconButton(
                    icon: Image.asset(rightIconPath!, width: 24, height: 24),
                    onPressed: onRightIconTap,
                  ),
              ]
            : null,
      ),
      body: body,
    );
  }
}
