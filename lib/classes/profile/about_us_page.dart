import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../party/friends_activity/home_activity_navigation.dart';
import 'settings/about_view_model.dart';
import 'tools/profile_tools_config.dart';
import 'tools/profile_tools_widgets.dart';

class AboutUsPage extends ConsumerWidget {
  const AboutUsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    final state = ref.watch(aboutProvider),
        model = ref.read(aboutProvider.notifier),
        update = state.update;
    void web(String key, String url) => context.push(
      Uri(
        path: '/web-view',
        queryParameters: {'title': context.l10n.t(key), 'uri': url},
      ).toString(),
    );
    return ProfileToolsScaffold(
      title: context.l10n.t('profile.aboutUs'),
      child: ListView(
        padding: ProfileToolsTheme.padding,
        children: [
          ProfileToolsTheme.gap,
          const Center(
            child: MembershipImage(
              AppAssets.appLogo,
              size: ProfileToolsTheme.appLogo,
            ),
          ),
          ProfileToolsTheme.gap,
          const Text(
            ProfileToolsConfig.brand,
            textAlign: TextAlign.center,
            style: ProfileToolsTheme.title,
          ),
          if (state.info != null)
            Text(
              state.info!.version,
              textAlign: TextAlign.center,
              style: ProfileToolsTheme.caption,
            ),
          if (state.busy) const LinearProgressIndicator(),
          if (state.error != null)
            ProfileToolsError(
              error: state.error,
              retry: state.info == null ? model.load : model.check,
            ),
          ProfileToolsTheme.gap,
          ElevatedButton(
            onPressed: state.busy || state.info == null ? null : model.check,
            child: Text(context.l10n.t('menu.checkUpdate')),
          ),
          if (state.checked && update != null) ...[
            Text(
              update.needUpdate
                  ? update.title.isEmpty
                        ? context.l10n.t('menu.updateAvailable')
                        : update.title
                  : context.l10n.t('menu.latest'),
              style: ProfileToolsTheme.label,
            ),
            if (update.needUpdate) ...[
              Text(update.description, style: ProfileToolsTheme.body),
              if (update.url != null)
                TextButton(
                  onPressed: state.busy ? null : model.open,
                  child: Text(context.l10n.t('menu.openUpdate')),
                )
              else
                Text(
                  context.l10n.t('menu.invalidUpdate'),
                  style: ProfileToolsTheme.caption,
                ),
            ],
          ],
          ListTile(
            title: Text(context.l10n.t('settings.termsOfUse')),
            onTap: () => web('settings.termsOfUse', ProfileToolsConfig.terms),
          ),
          ListTile(
            title: Text(context.l10n.t('settings.privacyPolicy')),
            onTap: () =>
                web('settings.privacyPolicy', ProfileToolsConfig.privacy),
          ),
        ],
      ),
    );
  }
}
