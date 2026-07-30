import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: '设置',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.primaryPink,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('暂无更多设置', style: AppTextStyles.bodyStrong),
          ],
        ),
      ),
    );
  }
}
