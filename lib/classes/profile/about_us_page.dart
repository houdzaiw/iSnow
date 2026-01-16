
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/custom_scaffold.dart';

class AboutUsPage extends HookConsumerWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
      title: 'About Us',
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo - 120 * 120
                Container(
                  width: 120,
                  height: 120,
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
                    child: Text(
                      'IS',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Version Info
                Column(
                  children: [
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF999999),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build 1',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFCCCCCC),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
          ),
        ),
      ),
    );
  }
}