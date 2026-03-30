
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/custom_scaffold.dart';

class AboutUsPage extends HookConsumerWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
      title: 'About Us',
      body: Column(
        children: [
          SizedBox(height: 30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Logo - 120 * 120
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF9E707),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset("assets/base/app_logo.png", width: 100, height: 100),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Version Info
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // 联系邮箱
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Contact email: moodenote666@163.com',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF666666),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Description 固定在底部
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
            child: Text(
              'A simple and elegant diary app to record your daily emotions and moments.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF666666),
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}