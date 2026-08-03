import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _userAgreementUrl = 'https://www.simisoul.com/protocol.html';
  static const _privacyPolicyUrl = 'https://www.simisoul.com/policy.html';

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
              child: Column(
                children: [
                  _SettingsTile(
                    leading: Icons.language_rounded,
                    title: context.l10n.t('app.language'),
                    subtitle:
                        '${context.l10n.t('app.currentLanguage')}: $selectedLanguage',
                    onTap: () {
                      _showLanguageSheet(context, ref, locale.languageCode);
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                    indent: AppSpacing.xl,
                    endIndent: AppSpacing.xl,
                  ),
                  _SettingsTile(
                    leading: Icons.description_rounded,
                    title: context.l10n.t('settings.userAgreement'),
                    onTap: () {
                      _openWebView(
                        context,
                        title: context.l10n.t('settings.userAgreement'),
                        uri: _userAgreementUrl,
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                    indent: AppSpacing.xl,
                    endIndent: AppSpacing.xl,
                  ),
                  _SettingsTile(
                    leading: Icons.privacy_tip_rounded,
                    title: context.l10n.t('settings.privacyPolicy'),
                    onTap: () {
                      _openWebView(
                        context,
                        title: context.l10n.t('settings.privacyPolicy'),
                        uri: _privacyPolicyUrl,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWebView(
    BuildContext context, {
    required String title,
    required String uri,
  }) {
    context.push(
      Uri(
        path: '/web-view',
        queryParameters: {'title': title, 'uri': uri},
      ).toString(),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(leading, color: AppColors.primaryPink),
      title: Text(title, style: AppTextStyles.bodyStrong),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppTextStyles.caption),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppColors.primaryPink,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
