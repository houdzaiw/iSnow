import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../membership_aux_view_model.dart';
import '../membership_models.dart';
import 'membership_settings_page.dart';
import 'membership_widgets.dart';

class MembershipHistoryPage extends ConsumerStatefulWidget {
  const MembershipHistoryPage({super.key, required this.kind});
  final MembershipKind kind;
  @override
  ConsumerState<MembershipHistoryPage> createState() =>
      _MembershipHistoryPageState();
}

class _MembershipHistoryPageState extends ConsumerState<MembershipHistoryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref
            .read(membershipAuxProvider.notifier)
            .history(widget.kind, refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipAuxProvider);
    final model = ref.read(membershipAuxProvider.notifier);
    final items = state.records[widget.kind] ?? [];
    final key = 'history:${widget.kind.name}';
    final loading = state.loading.contains(key);
    return MembershipScaffold(
      title: context.l10n.t('membership.history'),
      child: items.isEmpty
          ? MembershipErrorView(
              error: state.errors[key],
              loading: loading,
              retry: () => model.history(widget.kind, refresh: true),
            )
          : RefreshIndicator(
              onRefresh: () => model.history(widget.kind, refresh: true),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter <
                          MembershipTheme.section &&
                      !loading &&
                      !state.errors.containsKey(key)) {
                    model.history(widget.kind);
                  }
                  return false;
                },
                child: ListView.builder(
                  key: PageStorageKey(key),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return Padding(
                        padding: MembershipTheme.padding,
                        child: loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: MembershipTheme.gold,
                                ),
                              )
                            : model.hasMore(widget.kind)
                            ? MembershipButton(
                                text: context.l10n.t(
                                  state.errors.containsKey(key)
                                      ? 'membership.retry'
                                      : 'membership.more',
                                ),
                                onTap: () => model.history(widget.kind),
                              )
                            : const SizedBox.shrink(),
                      );
                    }
                    final item = items[index];
                    final title = widget.kind == MembershipKind.vip
                        ? item.title
                        : context.l10n.t(switch (item.source) {
                            0 => 'membership.purchase',
                            1 || 4 => 'membership.friendPresent',
                            2 => 'membership.rewardSource',
                            3 => 'membership.reward',
                            _ => 'membership.unknown',
                          });
                    return Padding(
                      padding: MembershipTheme.rowPadding,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (item.icon.isNotEmpty) ...[
                                MembershipImage(
                                  item.icon,
                                  size: MembershipTheme.avatar,
                                ),
                                MembershipTheme.rowGap,
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: MembershipTheme.body),
                                    MembershipTheme.gap,
                                    if (item.occurredAt != null)
                                      Text(
                                        '${item.occurredAt!.toLocal()}'
                                            .split('.')
                                            .first,
                                        style: MembershipTheme.caption,
                                      ),
                                  ],
                                ),
                              ),
                              MembershipTheme.rowGap,
                              Text(
                                widget.kind == MembershipKind.vip
                                    ? '${item.amount}'
                                    : context.l10n.t('membership.days', {
                                        'days': '${item.amount}',
                                      }),
                                style: MembershipTheme.heading,
                              ),
                            ],
                          ),
                          MembershipTheme.dialogGap,
                          const Divider(color: MembershipTheme.muted),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
