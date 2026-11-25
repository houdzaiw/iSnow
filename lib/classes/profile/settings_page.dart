import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../party/friends_activity/home_activity_navigation.dart';
import 'mine/profile_view_model.dart';
import 'settings/profile_account_actions.dart';
import 'tools/profile_tools_config.dart';
import 'tools/profile_tools_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    final locale = ref.watch(appLocaleProvider);
    final busy = ref.watch(
      profileViewModelProvider.select((s) => s.isSubmitting),
    );
    Widget row(String title, String route, String image) => ListTile(
      enabled: !busy,
      leading: MembershipImage(image, size: ProfileToolsTheme.icon),
      title: Text(context.l10n.t(title), style: ProfileToolsTheme.label),
      trailing: const MembershipImage(
        AppAssets.roomProfileChevron,
        size: ProfileToolsTheme.icon,
      ),
      onTap: () => context.push(route),
    );
    String web(String key, String url) => Uri(
      path: '/web-view',
      queryParameters: {'title': context.l10n.t(key), 'uri': url},
    ).toString();
    return ProfileToolsScaffold(
      title: context.l10n.t('profile.settings'),
      child: AbsorbPointer(
        absorbing: busy,
        child: ListView(
          padding: ProfileToolsTheme.padding,
          children: [
            if (busy) const LinearProgressIndicator(),
            row(
              'menu.accountSecurity',
              '/settings/account-security',
              AppAssets.profileMenuSettings,
            ),
            row(
              'menu.vipSettings',
              '/vip/settings',
              AppAssets.membershipVipBadge,
            ),
            row(
              'profile.blockList',
              '/block-list',
              AppAssets.profileMenuBlockList,
            ),
            ListTile(
              leading: const MembershipImage(
                AppAssets.profileMenuSettings,
                size: ProfileToolsTheme.icon,
              ),
              title: Text(
                context.l10n.t('app.language'),
                style: ProfileToolsTheme.label,
              ),
              subtitle: Text(
                context.l10n.t(
                  locale.languageCode == 'zh' ? 'app.chinese' : 'app.english',
                ),
                style: ProfileToolsTheme.caption,
              ),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                useRootNavigator: true,
                builder: (c) => SafeArea(
                  child: RadioGroup<String>(
                    groupValue: locale.languageCode,
                    onChanged: (code) async {
                      if (code == null) return;
                      try {
                        await ref
                            .read(appLocaleProvider.notifier)
                            .setLanguage(code);
                        if (c.mounted) Navigator.pop(c);
                      } catch (e) {
                        if (c.mounted) profileToolsNotice(c, e);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final code in ['en', 'zh'])
                          RadioListTile<String>(
                            value: code,
                            title: Text(
                              c.l10n.t(
                                code == 'zh' ? 'app.chinese' : 'app.english',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            row(
              'settings.termsOfUse',
              web('settings.termsOfUse', ProfileToolsConfig.terms),
              AppAssets.lanhuProfileMenuTerms,
            ),
            row(
              'settings.privacyPolicy',
              web('settings.privacyPolicy', ProfileToolsConfig.privacy),
              AppAssets.lanhuProfileMenuPrivacy,
            ),
            row(
              'profile.aboutUs',
              '/about-us',
              AppAssets.lanhuProfileMenuAbout,
            ),
            ProfileToolsTheme.gap,
            ListTile(
              title: Text(
                context.l10n.t('profile.deleteAccount'),
                style: ProfileToolsTheme.label,
              ),
              onTap: () =>
                  confirmProfileAccountAction(context, ref, delete: true),
            ),
            ListTile(
              title: Text(
                context.l10n.t('profile.logOut'),
                style: ProfileToolsTheme.label,
              ),
              onTap: () =>
                  confirmProfileAccountAction(context, ref, delete: false),
            ),
          ],
        ),
      ),
    );
  }
}
