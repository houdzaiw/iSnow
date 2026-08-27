import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../configs/app_configs.dart';
import '../../../localization/app_localizations.dart';
import 'profile_menu_item.dart';
import 'profile_state.dart';
import 'profile_view_model.dart';
import '../views/profile_content_view.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const _userAgreementUrl = 'https://www.simisoul.com/protocol.html';
  static const _privacyPolicyUrl = 'https://www.simisoul.com/policy.html';
  static const _walletWebPath = '/h5/wallet/index.html';
  static const _walletRechargeTab = '1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);

    return Scaffold(
      body: ProfileContentView(
        state: state,
        onRefresh: () =>
            ref.read(profileViewModelProvider.notifier).loadProfile(),
        onEditProfile: () => context.push('/edit-profile'),
        onAvatarAction: () => _openHomepage(context, state),
        onMetricAction: (item) =>
            context.push('/profile-relations/${item.routeKey}'),
        onBadgeAction: (item) => _openBadgeWebView(context, item),
        onMenuAction: (item) => _handleMenuAction(context, ref, item),
      ),
    );
  }

  void _openHomepage(BuildContext context, ProfileState state) {
    final uid = state.profile?.user.uid;
    if (uid == null || uid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('profile.loadFailed'))),
      );
      return;
    }
    context.push('/profile-homepage/$uid');
  }

  void _openBadgeWebView(BuildContext context, ProfileBadgeItem item) {
    final baseUri = Uri.parse(AppConfig.shared.appEnv.socketHost);
    final webUri = baseUri.replace(path: item.webPath).toString();

    context.push(
      Uri(
        path: '/web-view',
        queryParameters: {
          'title': context.l10n.t(item.titleKey),
          'uri': webUri,
        },
      ).toString(),
    );
  }

  void _openWalletWebView(BuildContext context) {
    final baseUri = Uri.parse(AppConfig.shared.appEnv.socketHost);
    final walletUri = baseUri.replace(
      path: _walletWebPath,
      queryParameters: {
        'language': Localizations.localeOf(context).languageCode,
        'tab': _walletRechargeTab,
      },
    );

    context.push(
      Uri(
        path: '/web-view',
        queryParameters: {
          'title': context.l10n.t('profile.wallet'),
          'uri': walletUri.toString(),
        },
      ).toString(),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    ProfileMenuItem item,
  ) async {
    switch (item.action) {
      case 'my-posts':
        context.push('/my-posts');
        break;
      case 'block-list':
        context.push('/block-list');
        break;
      case 'privacy':
      case 'privacy-policy':
        context.push(
          Uri(
            path: '/web-view',
            queryParameters: {
              'title': context.l10n.t('settings.privacyPolicy'),
              'uri': _privacyPolicyUrl,
            },
          ).toString(),
        );
        break;
      case 'terms-of-use':
        context.push(
          Uri(
            path: '/web-view',
            queryParameters: {
              'title': context.l10n.t('settings.termsOfUse'),
              'uri': _userAgreementUrl,
            },
          ).toString(),
        );
        break;
      case 'about-us':
      case 'contact-us':
        context.push('/about-us');
        break;
      case 'settings':
        context.push('/settings');
        break;
      case 'delete-account':
        await _confirmDeleteAccount(context, ref);
        break;
      case 'log-out':
        await _confirmLogout(context, ref);
        break;
      case 'wallet':
        _openWalletWebView(context);
        break;
      case 'recharge':
      case 'invite-friends':
      case 'store':
      case 'level':
      case 'backpack':
      case 'honor':
        _showComingSoon(context);
        break;
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('profile.comingSoon'))),
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
}
