import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../party/friends_activity/home_activity_navigation.dart';
import '../tools/profile_tools_widgets.dart';
import 'backpack_view_model.dart';
import 'store_models.dart';
import 'store_preview.dart';
import 'backpack_gifts_view.dart';
import 'store_recipient_sheet.dart';
import 'store_repository.dart';
import '../../../model/user_profile.dart';

final backpackUserProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(storeRepositoryProvider).currentUser(),
);

class BackpackPage extends ConsumerWidget {
  const BackpackPage({super.key, this.initialGifts = false});
  final bool initialGifts;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    return DefaultTabController(
      length: StoreCategory.values.length + 1,
      initialIndex: initialGifts ? 0 : 1,
      child: ProfileToolsScaffold(
        title: context.l10n.t(
          initialGifts ? 'profile.backpack' : 'tools.backpack',
        ),
        child: Column(
          children: [
            ExtendedTabBar(
              labelColor: ProfileToolsTheme.tabActive,
              unselectedLabelColor: ProfileToolsTheme.tabInactive,
              indicatorColor: ProfileToolsTheme.tabIndicator,
              isScrollable: true,
              tabs: [
                Tab(text: context.l10n.t('menu.gifts')),
                for (final category in StoreCategory.values)
                  Tab(text: context.l10n.t('tools.${category.label}')),
              ],
            ),
            Expanded(
              child: ExtendedTabBarView(
                children: [
                  const BackpackGiftsView(),
                  for (final category in StoreCategory.values)
                    _PropList(category: category),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropList extends ConsumerWidget {
  const _PropList({required this.category});
  final StoreCategory category;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backpackProvider(category));
    final model = ref.read(backpackProvider(category).notifier);
    final prop = state.selected;
    final user = ref.watch(backpackUserProvider);
    final vip = user.asData?.value.userLevel?.vipLevel ?? 0;
    return RefreshIndicator(
      onRefresh: model.load,
      child: ListView(
        key: PageStorageKey('props-${category.name}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ProfileToolsTheme.padding,
        children: [
          if (user.hasError)
            ProfileToolsError(
              error: user.error,
              retry: () => ref.invalidate(backpackUserProvider),
            ),
          if (prop != null) ...[
            SizedBox(
              height: ProfileToolsTheme.preview,
              child: StorePreview(
                key: ValueKey(prop.id),
                product: prop.preview,
              ),
            ),
            Text(
              prop.name,
              style: ProfileToolsTheme.title,
              textAlign: TextAlign.center,
            ),
            Text(
              prop.permanent
                  ? context.l10n.t('tools.permanent')
                  : prop.expiresAt == null
                  ? context.l10n.t('tools.unavailable')
                  : context.l10n.t('tools.expires', {
                      'time': DateFormat.yMd().add_Hm().format(prop.expiresAt!),
                    }),
              style: ProfileToolsTheme.caption,
            ),
            ElevatedButton(
              onPressed: state.busy || prop.expired(DateTime.now())
                  ? null
                  : () async {
                      try {
                        final result = await model.use();
                        if (context.mounted && result != null) {
                          profileToolsNotice(
                            context,
                            null,
                            key: result
                                ? 'tools.success'
                                : 'tools.refreshFailed',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) profileToolsNotice(context, e);
                      }
                    },
              child: Text(
                context.l10n.t(
                  prop.expired(DateTime.now())
                      ? 'tools.expired'
                      : prop.state == 2
                      ? 'tools.remove'
                      : 'tools.use',
                ),
              ),
            ),
            if (vip >= 5)
              TextButton(
                onPressed:
                    state.busy || state.loading || prop.expired(DateTime.now())
                    ? null
                    : () async {
                        try {
                          if (!await model.beginTransfer() ||
                              !context.mounted) {
                            return;
                          }
                          final target = await showModalBottomSheet<UserData>(
                            context: context,
                            useRootNavigator: true,
                            isScrollControlled: true,
                            builder: (_) => const StoreRecipientSheet(),
                          );
                          if (target == null || !context.mounted) return;
                          final order = await model.prepareTransfer(
                            target.uid!,
                          );
                          if (!context.mounted) return;
                          final confirmed = await profileToolsConfirm(
                            context,
                            context.l10n.t('menu.confirmTransfer', {
                              'name': order.prop.name,
                              'target':
                                  '${order.targetName} (${order.targetUid})',
                            }),
                          );
                          if (!confirmed || !context.mounted) return;
                          final result = await model.transfer(order);
                          if (!context.mounted || result == null) return;
                          profileToolsNotice(
                            context,
                            null,
                            key: result
                                ? 'tools.success'
                                : 'tools.refreshFailed',
                          );
                          ref.invalidate(backpackUserProvider);
                        } catch (e) {
                          if (context.mounted) profileToolsNotice(context, e);
                        } finally {
                          model.endTransfer();
                        }
                      },
                child: Text(context.l10n.t('menu.transfer')),
              ),
          ],
          if (state.error != null)
            ProfileToolsError(error: state.error, retry: model.load),
          if (state.items.isEmpty && !state.loading && state.error == null)
            Center(child: Text(context.l10n.t('tools.empty'))),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ProfileToolsTheme.gridColumns,
              mainAxisExtent: ProfileToolsTheme.itemExtent,
              crossAxisSpacing: ProfileToolsTheme.gridSpacing,
              mainAxisSpacing: ProfileToolsTheme.gridSpacing,
            ),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return InkWell(
                onTap: state.busy ? null : () => model.select(item.id),
                child: Container(
                  padding: ProfileToolsTheme.smallPadding,
                  decoration: BoxDecoration(
                    color: ProfileToolsTheme.white,
                    borderRadius: ProfileToolsTheme.radius,
                    border: Border.fromBorderSide(
                      state.selectedId == item.id
                          ? ProfileToolsTheme.selectedBorder
                          : ProfileToolsTheme.normalBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: MembershipImage(
                          item.icon,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ProfileToolsTheme.label,
                      ),
                      if (item.state == 2)
                        Text(
                          context.l10n.t('tools.using'),
                          style: ProfileToolsTheme.caption,
                        ),
                      if (item.expired(DateTime.now()))
                        Text(
                          context.l10n.t('tools.expired'),
                          style: ProfileToolsTheme.caption,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (state.loading) const Center(child: CircularProgressIndicator()),
          if (state.more && state.items.isNotEmpty)
            TextButton(
              onPressed: state.loading ? null : () => model.load(more: true),
              child: Text(context.l10n.t('tools.more')),
            ),
        ],
      ),
    );
  }
}
