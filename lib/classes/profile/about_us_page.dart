import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/custom_scaffold.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';

class AboutUsPage extends HookConsumerWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
      title: context.l10n.t('profile.aboutUs'),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxxl,
              vertical: 60,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                    boxShadow: AppShadows.soft,
                  ),
                  child: Center(
                    child: Text(
                      'IS',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const Text('iSnow', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.t('about.version'),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.section),
                Text(
                  context.l10n.t('about.description'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
