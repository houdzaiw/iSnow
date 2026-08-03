import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final selectedLanguage = locale.languageCode == 'zh'
        ? context.l10n.t('app.chinese')
        : context.l10n.t('app.english');

    return CustomScaffold(
      title: context.l10n.t('profile.settings'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.cardBorder,
                boxShadow: AppShadows.soft,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.language_rounded,
                  color: AppColors.primaryPink,
                ),
                title: Text(
                  context.l10n.t('app.language'),
                  style: AppTextStyles.bodyStrong,
                ),
                subtitle: Text(
                  '${context.l10n.t('app.currentLanguage')}: $selectedLanguage',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryPink,
                  size: 16,
                ),
                onTap: () {
                  _showLanguageSheet(context, ref, locale.languageCode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    String currentLanguageCode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      builder: (sheetContext) {
        Widget languageTile(String languageCode, String label) {
          final selected = currentLanguageCode == languageCode;
          return ListTile(
            title: Text(label, style: AppTextStyles.bodyStrong),
            trailing: selected
                ? const Icon(Icons.check, color: AppColors.primaryPink)
                : null,
            onTap: () async {
              await ref
                  .read(appLocaleProvider.notifier)
                  .setLanguage(languageCode);
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutralLight,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                languageTile('en', context.l10n.t('app.english')),
                languageTile('zh', context.l10n.t('app.chinese')),
              ],
            ),
          ),
        );
      },
    );
  }
}
