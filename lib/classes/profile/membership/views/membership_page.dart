import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../manager/locale_provider.dart';
import '../../../../theme/app_theme.dart';
import '../membership_models.dart';
import '../membership_state.dart';
import '../membership_view_model.dart';
import 'membership_flows.dart';
import 'membership_hero.dart';
import 'membership_purchase_bar.dart';
import 'membership_media.dart';
import 'membership_rewards_sheet.dart';
import 'membership_widgets.dart';

class MembershipPage extends ConsumerStatefulWidget {
  const MembershipPage({super.key, required this.kind, this.initialLevel});
  final MembershipKind kind;
  final int? initialLevel;
  @override
  ConsumerState<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends ConsumerState<MembershipPage> {
  late final MembershipFlows _flows;
  bool get vip => widget.kind == MembershipKind.vip;
  @override
  void initState() {
    super.initState();
    _flows = MembershipFlows(context, ref);
    if (widget.initialLevel != null) {
      Future.microtask(() async {
        final model = ref.read(membershipViewModelProvider.notifier);
        await model.loadVip();
        if (mounted) model.selectVip(widget.initialLevel!);
      });
    }
  }

  @override
  void dispose() {
    _flows.dispose();
    super.dispose();
  }

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) {
      await ref.read(membershipViewModelProvider.notifier).load(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipViewModelProvider);
    final model = ref.read(membershipViewModelProvider.notifier);
    final loading = vip ? state.loadingVip : state.loadingNoble;
    final error = vip ? state.vipError : state.nobleError;
    final empty = vip
        ? state.vip?.levels.isNotEmpty != true
        : state.nobles?.isNotEmpty != true;
    final level = vip ? state.selectedVip : state.selectedNoble;
    final backgrounds = vip
        ? AppAssets.membershipVipBackgrounds
        : AppAssets.membershipNobleBackgrounds;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MembershipTheme.background,
        image: DecorationImage(
          image: AssetImage(
            backgrounds[(level - 1).clamp(0, backgrounds.length - 1)],
          ),
          alignment: Alignment.topCenter,
          fit: BoxFit.fitWidth,
        ),
      ),
      child: Scaffold(
        backgroundColor: MembershipTheme.transparent,
        appBar: AppBar(
          backgroundColor: MembershipTheme.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: MembershipTheme.zero.left,
          leading: MembershipAssetButton(
            asset: AppAssets.membershipBack,
            label: context.l10n.t('app.back'),
            onTap: () => Navigator.pop(context),
          ),
          title: Text(
            context.l10n.t(vip ? 'membership.vip' : 'membership.noble'),
            style: MembershipTheme.heading,
          ),
          actions: [
            if (vip)
              MembershipAssetButton(
                asset: AppAssets.membershipSettings,
                label: context.l10n.t('membership.settings'),
                onTap: () => _open('/vip/settings'),
              ),
            MembershipAssetButton(
              asset: AppAssets.membershipHistory,
              label: context.l10n.t('membership.history'),
              onTap: () => _open(vip ? '/vip/history' : '/noble/history'),
            ),
            if (vip)
              MembershipAssetButton(
                asset: AppAssets.membershipRules,
                label: context.l10n.t('membership.rules'),
                onTap: () {
                  final language = ref.read(appLocaleProvider).languageCode;
                  final uri = Uri.https(
                    'www.simisoul.com',
                    '/h5-statics/vipRules.html',
                    {'language': language},
                  );
                  context.push(
                    Uri(
                      path: '/web-view',
                      queryParameters: {
                        'title': context.l10n.t('membership.rules'),
                        'uri': '$uri',
                      },
                    ).toString(),
                  );
                },
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: empty
                    ? MembershipErrorView(
                        loading: loading,
                        error: error,
                        retry: () => model.load(force: true),
                      )
                    : RefreshIndicator(
                        onRefresh: () => model.load(force: true),
                        child: SingleChildScrollView(
                          key: PageStorageKey('membership-${widget.kind.name}'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              if (error != null)
                                Text(
                                  membershipError(context, error),
                                  style: MembershipTheme.caption,
                                ),
                              MembershipTierTabs(kind: widget.kind),
                              MembershipHero(kind: widget.kind),
                              Padding(
                                padding: MembershipTheme.rowPadding,
                                child: Column(
                                  children: [
                                    Text(
                                      vip
                                          ? vipMembershipStatus(context, state)
                                          : _selectedNobleStatus(
                                              context,
                                              state,
                                            ),
                                      style: MembershipTheme.caption,
                                    ),
                                    if (vip) ...[
                                      MembershipTheme.dialogGap,
                                      Text(
                                        context.l10n.t('membership.experience', {
                                          'value':
                                              '${state.vip?.experience ?? 0}',
                                          'max':
                                              '${state.vip?.maxExperience ?? 0}',
                                        }),
                                        style: MembershipTheme.caption,
                                      ),
                                      MembershipTheme.gap,
                                      LinearProgressIndicator(
                                        value: state.vip!.maxExperience <= 0
                                            ? 0
                                            : (state.vip!.experience /
                                                      state.vip!.maxExperience)
                                                  .clamp(0, 1),
                                        color: MembershipTheme.gold,
                                        backgroundColor: MembershipTheme.panel,
                                      ),
                                    ],
                                    MembershipTheme.dialogGap,
                                    Wrap(
                                      spacing: MembershipTheme.m,
                                      runSpacing: MembershipTheme.m,
                                      children: [
                                        if (vip &&
                                            state.vipActive &&
                                            (state.vip?.level ?? 0) >= 4)
                                          TextButton(
                                            onPressed: state.submitting
                                                ? null
                                                : () => _flows.act(
                                                    MembershipAction
                                                        .experienceCard,
                                                    chooseRecipient: true,
                                                  ),
                                            child: Text(
                                              context.l10n.t(
                                                'membership.experienceCard',
                                                {'count': '${state.cards}'},
                                              ),
                                              style: MembershipTheme.tiny,
                                            ),
                                          ),
                                        if (vip &&
                                            state.vipActive &&
                                            (state.vip?.level ?? 0) >= 6)
                                          TextButton(
                                            onPressed: state.submitting
                                                ? null
                                                : () => _flows.act(
                                                    MembershipAction.unblock,
                                                    chooseRecipient: true,
                                                  ),
                                            child: Text(
                                              context.l10n.t(
                                                'membership.unblock',
                                              ),
                                              style: MembershipTheme.tiny,
                                            ),
                                          ),
                                        if (!vip)
                                          TextButton(
                                            onPressed: () =>
                                                _open('/noble/titles'),
                                            child: Text(
                                              context.l10n.t(
                                                'membership.titles',
                                              ),
                                              style: MembershipTheme.tiny,
                                            ),
                                          ),
                                        if (!vip &&
                                            state.nobleLevel >= 5 &&
                                            state.selectedNoble >= 5)
                                          TextButton(
                                            onPressed: state.submitting
                                                ? null
                                                : () => _flows.sheet<void>(
                                                    (_) =>
                                                        MembershipRewardsSheet(
                                                          flows: _flows,
                                                        ),
                                                  ),
                                            child: Text(
                                              context.l10n.t(
                                                'membership.reward',
                                              ),
                                              style: MembershipTheme.tiny,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (vip &&
                                  state.vipLevel?.preview.isNotEmpty == true)
                                SizedBox(
                                  height: MembershipTheme.preview,
                                  child: MembershipMedia(
                                    key: ValueKey('${widget.kind}:$level'),
                                    url: (vip
                                        ? state.vipLevel?.preview
                                        : state.noble?.preview)!,
                                  ),
                                ),
                              Padding(
                                padding: MembershipTheme.padding,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    image: vip
                                        ? null
                                        : DecorationImage(
                                            image: AssetImage(
                                              AppAssets
                                                  .membershipNobleContainers[(level -
                                                      1)
                                                  .clamp(0, 5)],
                                            ),
                                            fit: BoxFit.fill,
                                          ),
                                  ),
                                  child: Padding(
                                    padding: MembershipTheme.cardPadding,
                                    child: MembershipPrivileges(
                                      items: vip
                                          ? state.vipLevel?.privileges ?? []
                                          : state.noble?.privileges ?? [],
                                      onTap: _flows.preview,
                                      active: vip
                                          ? state.vipLevel?.activeCount
                                          : null,
                                      total: vip ? state.vipLevel?.total : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              if (!empty)
                MembershipPurchaseBar(kind: widget.kind, flows: _flows),
            ],
          ),
        ),
      ),
    );
  }

  String _selectedNobleStatus(BuildContext context, MembershipState state) {
    final n = state.noble;
    if (n?.owned != true) return context.l10n.t('membership.notActivated');
    final remaining = n!.remaining(state.now ?? DateTime.now());
    return remaining == Duration.zero
        ? context.l10n.t('membership.expired')
        : membershipRemaining(context, remaining);
  }
}
