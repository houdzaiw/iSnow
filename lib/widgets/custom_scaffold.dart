import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String? rightIconPath;
  final String? rightText;
  final VoidCallback? onRightIconTap;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomScaffold({
    super.key,
    required this.title,
    required this.body,
    this.rightIconPath,
    this.rightText,
    this.onRightIconTap,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9E707),
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: Image.asset(
                  'assets/base/back_button.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: onBackPressed ?? () => context.pop(),
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: rightIconPath != null || rightText != null
            ? [
                if (rightText != null)
                  TextButton(
                    onPressed: onRightIconTap,
                    child: Text(
                      rightText!,
                      style: const TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (rightIconPath != null)
                  IconButton(
                    icon: Image.asset(
                      rightIconPath!,
                      width: 24,
                      height: 24,
                    ),
                    onPressed: onRightIconTap,
                  ),
              ]
            : null,
      ),
      body: body,
    );
  }
}

