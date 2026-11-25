import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../manager/api_error_message.dart';
import 'profile_menu_item.dart';
import 'profile_state.dart';
import 'profile_view_model.dart';
import '../views/profile_content_view.dart';
import '../membership/membership_view_model.dart';
import '../tools/profile_menu_repository.dart';
import '../tools/profile_tools_config.dart';
import '../../../manager/locale_provider.dart';
import '../honor/honor_repository.dart';
import '../settings/profile_account_actions.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const _userAgreementUrl = ProfileToolsConfig.terms;
  static const _privacyPolicyUrl = ProfileToolsConfig.privacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final membership = ref.watch(membershipViewModelProvider);
    final menu = ref.watch(profileMenuProvider);

    return Scaffold(
      body: ProfileContentView(
        state: state.copyWith(
          badgeItems: menu.valueOrNull?.items ?? const [],
          honorCount: ref.watch(honorCountProvider).asData?.value,
        ),
        membership: membership,
        toolsError: menu.valueOrNull?.error ?? menu.error,
        onRetryTools: () => ref.invalidate(profileMenuProvider),
        onVipTap: () => _openMembership(context, ref, '/vip'),
        onNobleTap: () => _openMembership(context, ref, '/noble'),
        onRefresh: () async {
          ref.invalidate(honorCountProvider);
          ref.invalidate(profileMenuProvider);
          await Future.wait([
            ref.read(profileViewModelProvider.notifier).loadProfile(),
            ref.read(membershipViewModelProvider.notifier).load(force: true),
          ]);
        },
        onEditProfile: () => context.push('/edit-profile'),
        onAvatarAction: () => _openHomepage(context, state),
        onMetricAction: (item) =>
            context.push('/profile-relations/${item.routeKey}'),
        onBadgeAction: (item) => _openBadgeWebView(context, ref, item),
        onMenuAction: (item) => _handleMenuAction(context, ref, item),
      ),
    );
  }

  Future<void> _openMembership(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    await context.push(path);
    if (!context.mounted) return;
    await ref.read(membershipViewModelProvider.notifier).load(force: true);
    if (context.mounted) {
      await ref.read(profileViewModelProvider.notifier).loadProfile();
    }
  }

  void _openHomepage(BuildContext context, ProfileState state) {
    final uid = state.profile?.user.uid;
    if (uid == null || uid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingErrorMessage(
              state.loadError,
              fallback: context.l10n.t('profile.loadFailed'),
            ),
          ),
        ),
      );
      return;
    }
    context.push('/profile-homepage/$uid');
  }

  Future<void> _refreshTools(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    await ref.read(profileViewModelProvider.notifier).loadProfile();
    if (context.mounted) ref.invalidate(profileMenuProvider);
  }

  Future<void> _openBadgeWebView(
    BuildContext context,
    WidgetRef ref,
    ProfileBadgeItem item,
  ) async {
    final destination = item.destination;
    if (destination == null) return;
    if (destination.kind != ProfileDestinationKind.web) {
      await context.push(destination.target);
      if (context.mounted) await _refreshTools(context, ref);
      return;
    }
    final webUri = destination.target;

    await context.push(
      Uri(
        path: '/web-view',
        queryParameters: {
          'title': item.title.isNotEmpty
              ? item.title
              : context.l10n.t(item.titleKey),
          'uri': webUri,
          'hiddenAppBar': 'true',
        },
      ).toString(),
    );
    if (context.mounted) await _refreshTools(context, ref);
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
        await confirmProfileAccountAction(context, ref, delete: true);
        break;
      case 'log-out':
        await confirmProfileAccountAction(context, ref, delete: false);
        break;
      case 'wallet':
        await context.push('/wallet');
        if (context.mounted) await _refreshTools(context, ref);
        break;
      case 'invite-friends':
        await context.push(
          Uri(
            path: '/web-view',
            queryParameters: {
              'title': context.l10n.t('profile.inviteFriends'),
              'uri': const ProfileToolsConfig()
                  .page(
                    '/h5/agent/invite.html',
                    ref.read(appLocaleProvider).languageCode,
                  )
                  .toString(),
              'hiddenAppBar': 'true',
            },
          ).toString(),
        );
        if (context.mounted) await _refreshTools(context, ref);
        break;
      case 'store':
        await context.push('/store');
        if (context.mounted) await _refreshTools(context, ref);
        break;
      case 'backpack':
        await context.push('/backpack');
        if (context.mounted) await _refreshTools(context, ref);
        break;
      case 'level':
        await context.push(
          Uri(
            path: '/web-view',
            queryParameters: {
              'title': context.l10n.t('profile.level'),
              'uri': const ProfileToolsConfig()
                  .level(ref.read(appLocaleProvider).languageCode)
                  .toString(),
              'hiddenAppBar': 'true',
            },
          ).toString(),
        );
        if (context.mounted) await _refreshTools(context, ref);
        break;
      case 'honor':
        await context.push('/honor');
        if (context.mounted) {
          ref.invalidate(honorCountProvider);
          await _refreshTools(context, ref);
        }
        break;
    }
  }
}
