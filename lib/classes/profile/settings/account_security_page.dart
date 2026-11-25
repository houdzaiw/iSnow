import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../party/friends_activity/home_activity_navigation.dart';
import '../binding/account_binding_repository.dart';
import '../mine/profile_view_model.dart';
import '../tools/profile_tools_widgets.dart';
import 'profile_account_actions.dart';

final profileAccountsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(accountBindingRepositoryProvider).accounts(),
);

class AccountSecurityPage extends ConsumerWidget {
  const AccountSecurityPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    final accounts = ref.watch(profileAccountsProvider);
    final busy = ref.watch(
      profileViewModelProvider.select((s) => s.isSubmitting),
    );
    return ProfileToolsScaffold(
      title: context.l10n.t('menu.accountSecurity'),
      child: ListView(
        padding: ProfileToolsTheme.padding,
        children: [
          accounts.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ProfileToolsError(
              error: e,
              retry: () => ref.invalidate(profileAccountsProvider),
            ),
            data: (items) => Column(
              children: [
                for (final item in items.where((a) => a.type == 5 || a.bound))
                  ListTile(
                    title: Text(
                      context.l10n.t(
                        'menu.account${{0, 1, 5, 6, 7}.contains(item.type) ? item.type : 2}',
                      ),
                      style: ProfileToolsTheme.label,
                    ),
                    subtitle: Text(
                      item.bound
                          ? item.account
                          : context.l10n.t('menu.notBound'),
                      style: ProfileToolsTheme.caption,
                    ),
                    trailing: item.type == 5
                        ? TextButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    await context.push('/account-binding');
                                    if (context.mounted) {
                                      ref.invalidate(profileAccountsProvider);
                                    }
                                  },
                            child: Text(
                              context.l10n.t(
                                item.bound ? 'menu.change' : 'menu.bind',
                              ),
                            ),
                          )
                        : Text(
                            context.l10n.t('menu.bound'),
                            style: ProfileToolsTheme.caption,
                          ),
                  ),
              ],
            ),
          ),
          ProfileToolsTheme.gap,
          TextButton(
            onPressed: busy
                ? null
                : () => confirmProfileAccountAction(context, ref, delete: true),
            child: Text(context.l10n.t('profile.deleteAccount')),
          ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
