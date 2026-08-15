import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import 'mine/profile_view_model.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _userAgreementUrl = 'https://www.simisoul.com/protocol.html';
  static const _privacyPolicyUrl = 'https://www.simisoul.com/policy.html';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final profileState = ref.watch(profileViewModelProvider);
    final selectedLanguage = locale.languageCode == 'zh'
        ? context.l10n.t('app.chinese')
        : context.l10n.t('app.english');

    return CustomScaffold(
      title: context.l10n.t('profile.settings'),
      body: Stack(
        children: [
          Padding(
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
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: AppRadius.cardBorder,
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        leading: Icons.person_remove_alt_1_rounded,
                        title: context.l10n.t('profile.deleteAccount'),
                        titleColor: AppColors.textPrimary,
                        onTap: () => _confirmDeleteAccount(context, ref),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
                        indent: AppSpacing.xl,
                        endIndent: AppSpacing.xl,
                      ),
                      _SettingsTile(
                        leading: Icons.logout_rounded,
                        title: context.l10n.t('profile.logOut'),
                        titleColor: AppColors.primaryPinkDeep,
                        iconColor: AppColors.primaryPinkDeep,
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (profileState.isSubmitting)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x33000000),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: context.l10n.t('profile.logOut'),
      message: context.l10n.t('profile.logOutMessage'),
      confirmLabel: context.l10n.t('profile.logOut'),
    );
    if (!confirmed) return;

    final success = await ref.read(profileViewModelProvider.notifier).logout();
    if (!context.mounted) return;
    if (success) {
      context.go('/login');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('profile.logoutFailed'))),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: context.l10n.t('profile.deleteAccount'),
      message: context.l10n.t('profile.deleteAccountMessage'),
      confirmLabel: context.l10n.t('app.delete'),
      destructive: true,
    );
    if (!confirmed) return;

    final success = await ref
        .read(profileViewModelProvider.notifier)
        .deleteAccount();
    if (!context.mounted) return;
    if (success) {
      context.go('/login');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('profile.deleteAccountFailed'))),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.t('app.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: destructive ? Colors.red : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
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
    this.titleColor,
    this.iconColor,
  });

  final IconData leading;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(leading, color: iconColor ?? AppColors.primaryPink),
      title: Text(
        title,
        style: AppTextStyles.bodyStrong.copyWith(color: titleColor),
      ),
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
