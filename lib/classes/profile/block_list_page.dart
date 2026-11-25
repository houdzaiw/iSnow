import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../party/friends_activity/home_activity_navigation.dart';
import 'settings/blacklist_view_model.dart';
import 'tools/profile_tools_widgets.dart';

class BlockListPage extends ConsumerWidget {
  const BlockListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    final state = ref.watch(blacklistProvider),
        model = ref.read(blacklistProvider.notifier);
    return ProfileToolsScaffold(
      title: context.l10n.t('profile.blockList'),
      child: RefreshIndicator(
        onRefresh: model.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ProfileToolsTheme.padding,
          children: [
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null)
              ProfileToolsError(error: state.error, retry: model.load),
            if (!state.loading && state.error == null && state.items.isEmpty)
              Text(context.l10n.t('tools.empty')),
            for (final user in state.items)
              ListTile(
                leading: MembershipImage(
                  user.avatar,
                  size: ProfileToolsTheme.badge,
                ),
                title: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ProfileToolsTheme.label,
                ),
                subtitle: Text(
                  'ID: ${user.userNo > 0 ? user.userNo : user.uid}',
                  style: ProfileToolsTheme.caption,
                ),
                onTap: () => context.push('/profile-homepage/${user.uid}'),
                trailing: TextButton(
                  onPressed: state.removing != null || state.loading
                      ? null
                      : () async {
                          final confirmed = await profileToolsConfirm(
                            context,
                            context.l10n.t('menu.unblockConfirm', {
                              'name': user.name,
                            }),
                          );
                          if (!confirmed || !context.mounted) return;
                          final result = await model.remove(user.uid);
                          if (context.mounted && result) {
                            profileToolsNotice(
                              context,
                              null,
                              key: 'tools.success',
                            );
                          }
                        },
                  child: Text(context.l10n.t('menu.unblock')),
                ),
              ),
            if (state.more && state.items.isNotEmpty)
              TextButton(
                onPressed: state.loading || state.removing != null
                    ? null
                    : () => model.load(more: true),
                child: Text(context.l10n.t('tools.more')),
              ),
          ],
        ),
      ),
    );
  }
}
