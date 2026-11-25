import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../localization/app_localizations.dart';
import '../../../manager/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../../party/friends_activity/home_activity_navigation.dart';
import '../store/store_models.dart';
import '../store/store_preview.dart';
import '../tools/profile_tools_widgets.dart';
import 'honor_models.dart';
import 'honor_repository.dart';
import 'honor_view_model.dart';

class HonorPage extends ConsumerWidget {
  const HonorPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    final state = ref.watch(honorProvider),
        model = ref.read(honorProvider.notifier);
    final language = ref.watch(appLocaleProvider).languageCode;
    void back() {
      if (state.editing) {
        model.cancel();
      } else {
        Navigator.maybePop(context);
      }
    }

    return PopScope(
      canPop: !state.editing && !state.busy,
      onPopInvokedWithResult: (popped, _) {
        if (!popped && state.editing) model.cancel();
      },
      child: DefaultTabController(
        length: 3,
        child: ProfileToolsScaffold(
          title: context.l10n.t('profile.honor'),
          onBack: state.busy ? () {} : back,
          actions: [
            TextButton(
              onPressed: state.busy || state.loading
                  ? null
                  : state.editing
                  ? model.cancel
                  : model.edit,
              child: Text(
                context.l10n.t(state.editing ? 'tools.cancel' : 'menu.edit'),
              ),
            ),
          ],
          bottom: state.editing
              ? ElevatedButton(
                  onPressed: state.busy
                      ? null
                      : () async {
                          final result = await model.save();
                          if (!context.mounted) return;
                          if (result != null) {
                            ref.invalidate(honorCountProvider);
                            profileToolsNotice(
                              context,
                              null,
                              key: result
                                  ? 'tools.success'
                                  : 'tools.refreshFailed',
                            );
                          }
                        },
                  child: Text(context.l10n.t('menu.save')),
                )
              : null,
          child: Column(
            children: [
              if (state.equipment != null)
                Padding(
                  padding: ProfileToolsTheme.rowPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.l10n.t('menu.worn')}: ${state.draft.length}/${state.equipment!.limit}',
                        style: ProfileToolsTheme.label,
                      ),
                      if (state.editing)
                        Text(
                          context.l10n.t('menu.reorder'),
                          style: ProfileToolsTheme.caption,
                        ),
                      SizedBox(
                        height: ProfileToolsTheme.badgeSlot,
                        child: ReorderableListView(
                          scrollDirection: Axis.horizontal,
                          buildDefaultDragHandles: false,
                          onReorder: model.move,
                          children: [
                            for (var i = 0; i < state.draft.length; i++)
                              ReorderableDelayedDragStartListener(
                                key: ValueKey(state.draft[i]),
                                index: i,
                                enabled: state.editing && !state.busy,
                                child: InkWell(
                                  onTap: state.editing && !state.busy
                                      ? () => model.remove(state.draft[i])
                                      : null,
                                  child: Padding(
                                    padding: ProfileToolsTheme.smallPadding,
                                    child: MembershipImage(
                                      _icon(state, state.draft[i]),
                                      size: ProfileToolsTheme.badge,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ExtendedTabBar(
                isScrollable: true,
                labelColor: ProfileToolsTheme.tabActive,
                unselectedLabelColor: ProfileToolsTheme.tabInactive,
                indicatorColor: ProfileToolsTheme.tabIndicator,
                tabs: [
                  for (final key in ['achievement', 'gifts', 'special'])
                    Tab(text: context.l10n.t('menu.$key')),
                ],
              ),
              if (state.loading || state.busy) const LinearProgressIndicator(),
              if (state.error != null)
                ProfileToolsError(
                  error: state.error,
                  retry: state.editing ? model.cancel : model.load,
                ),
              Expanded(
                child: ExtendedTabBarView(
                  children: [
                    for (final type in [1, 2, 3])
                      RefreshIndicator(
                        onRefresh: () async {
                          await model.load();
                          ref.invalidate(honorCountProvider);
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final badges = (state.catalog[type] ?? [])
                                .where(
                                  (b) => !state.editing || b.ownedStage != null,
                                )
                                .toList();
                            return GridView.builder(
                              key: PageStorageKey('honor-$type'),
                              padding: ProfileToolsTheme.padding,
                              physics: const AlwaysScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        ProfileToolsTheme.gridColumns,
                                    mainAxisExtent:
                                        ProfileToolsTheme.medalExtent,
                                    crossAxisSpacing:
                                        ProfileToolsTheme.gridSpacing,
                                  ),
                              itemCount: badges.isEmpty ? 1 : badges.length,
                              itemBuilder: (context, index) {
                                if (badges.isEmpty) {
                                  return Text(
                                    context.l10n.t('tools.empty'),
                                    style: ProfileToolsTheme.caption,
                                  );
                                }
                                final badge = badges[index];
                                return InkWell(
                                  onTap: state.busy
                                      ? null
                                      : () {
                                          if (state.editing) {
                                            model.toggle(badge);
                                          } else {
                                            showModalBottomSheet<void>(
                                              context: context,
                                              useRootNavigator: true,
                                              isScrollControlled: true,
                                              builder: (_) => HonorPreview(
                                                badge: badge,
                                                language: language,
                                              ),
                                            );
                                          }
                                        },
                                  child: Container(
                                    padding: ProfileToolsTheme.smallPadding,
                                    decoration: BoxDecoration(
                                      borderRadius: ProfileToolsTheme.radius,
                                      border: Border.fromBorderSide(
                                        state.draft.contains(badge.id)
                                            ? ProfileToolsTheme.selectedBorder
                                            : ProfileToolsTheme.normalBorder,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Opacity(
                                            opacity: badge.ownedStage == null
                                                ? ProfileToolsTheme
                                                      .disabledOpacity
                                                : 1,
                                            child: MembershipImage(
                                              badge.displayStage?.icon ?? '',
                                              size:
                                                  ProfileToolsTheme.largeBadge,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          badge.title(language),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: ProfileToolsTheme.label,
                                        ),
                                        Text(
                                          context.l10n.t(
                                            badge.ownedStage == null
                                                ? 'menu.unowned'
                                                : 'menu.owned',
                                          ),
                                          style: ProfileToolsTheme.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _icon(HonorState state, String id) {
    for (final list in state.catalog.values) {
      for (final badge in list) {
        if (badge.id == id) return badge.displayStage?.icon ?? '';
      }
    }
    return state.equipment?.user.wornMedals
            .where((m) => m.id == id)
            .firstOrNull
            ?.icon ??
        '';
  }
}

class HonorPreview extends HookWidget {
  const HonorPreview({super.key, required this.badge, required this.language});
  final HonorBadge badge;
  final String language;
  @override
  Widget build(BuildContext context) {
    final controller = usePageController(
      initialPage: badge.stages
          .indexWhere((s) => s.stage == badge.currentStage)
          .clamp(0, (badge.stages.length - 1).clamp(0, 10000)),
    );
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height *
            ProfileToolsTheme.previewFraction,
        child: Column(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.t('tools.close')),
            ),
            Text(badge.title(language), style: ProfileToolsTheme.title),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: badge.stages.length,
                itemBuilder: (context, i) {
                  final stage = badge.stages[i];
                  return ListView(
                    padding: ProfileToolsTheme.padding,
                    children: [
                      StorePreview(
                        product: StoreProduct(
                          id: stage.stage,
                          type: 0,
                          name: badge.title(language),
                          icon: stage.icon,
                          animation: stage.animation,
                          prices: const [],
                        ),
                      ),
                      Text(
                        '${context.l10n.t('menu.stage')} ${stage.stage}',
                        style: ProfileToolsTheme.label,
                      ),
                      Text(stage.text(language), style: ProfileToolsTheme.body),
                      if (stage.obtainTime != null)
                        Text(
                          '${context.l10n.t('menu.obtained')}: ${DateFormat.yMd().format(stage.obtainTime!)}',
                        ),
                      if (stage.expireTime != null)
                        Text(
                          context.l10n.t('tools.expires', {
                            'time': DateFormat.yMd().format(stage.expireTime!),
                          }),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
