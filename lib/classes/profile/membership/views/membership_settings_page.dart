import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../membership_aux_view_model.dart';
import '../membership_view_model.dart';
import 'membership_widgets.dart';

class MembershipSettingsPage extends ConsumerStatefulWidget {
  const MembershipSettingsPage({super.key});
  @override
  ConsumerState<MembershipSettingsPage> createState() =>
      _MembershipSettingsPageState();
}

class _MembershipSettingsPageState
    extends ConsumerState<MembershipSettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(membershipAuxProvider.notifier).load('settings', force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipAuxProvider);
    final level = ref.watch(
      membershipViewModelProvider.select((s) => s.vip?.level ?? 0),
    );
    final model = ref.read(membershipAuxProvider.notifier);
    return MembershipScaffold(
      title: context.l10n.t('membership.settings'),
      child: state.settings?.isNotEmpty != true
          ? MembershipErrorView(
              error: state.errors['settings'],
              loading: state.loading.contains('settings'),
              retry: () => model.load('settings', force: true),
            )
          : RefreshIndicator(
              onRefresh: () => model.load('settings', force: true),
              child: ListView(
                children: [
                  for (final setting in state.settings!)
                    Padding(
                      padding: MembershipTheme.rowPadding,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: level < setting.limit
                                      ? () => context.push(
                                          '/vip?level=${setting.limit}',
                                        )
                                      : null,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        setting.type == 'invisibleEnter'
                                            ? context.l10n.t(
                                                'membership.enterInvisible',
                                              )
                                            : setting.type == 'invisibleVisitor'
                                            ? context.l10n.t(
                                                'membership.visitInvisible',
                                              )
                                            : setting.name,
                                        style: MembershipTheme.body,
                                      ),
                                      MembershipTheme.gap,
                                      Text(
                                        context.l10n.t('membership.unlock', {
                                          'level': '${setting.limit}',
                                        }),
                                        style: MembershipTheme.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (level < setting.limit)
                                MembershipAssetButton(
                                  asset: AppAssets.membershipArrow,
                                  label: context.l10n.t('membership.unlock', {
                                    'level': '${setting.limit}',
                                  }),
                                  onTap: () => context.push(
                                    '/vip?level=${setting.limit}',
                                  ),
                                )
                              else
                                Switch(
                                  value: setting.open,
                                  activeTrackColor: MembershipTheme.goldDeep,
                                  onChanged:
                                      state.saving.contains(
                                            'setting:${setting.id}',
                                          ) ||
                                          state.loading.contains('settings')
                                      ? null
                                      : (value) async {
                                          final success = await model
                                              .saveSetting(
                                                setting,
                                                value,
                                                level,
                                              );
                                          if (!context.mounted || success) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                membershipError(
                                                  context,
                                                  ref
                                                      .read(
                                                        membershipAuxProvider,
                                                      )
                                                      .errors['setting:${setting.id}'],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                ),
                            ],
                          ),
                          if (state.saving.contains('setting:${setting.id}'))
                            const LinearProgressIndicator(
                              color: MembershipTheme.gold,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class MembershipScaffold extends StatelessWidget {
  const MembershipScaffold({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MembershipTheme.background,
    appBar: AppBar(
      backgroundColor: MembershipTheme.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: MembershipAssetButton(
        asset: AppAssets.membershipBack,
        label: context.l10n.t('app.back'),
        onTap: () => Navigator.pop(context),
      ),
      title: Text(title, style: MembershipTheme.heading),
    ),
    body: SafeArea(top: false, child: child),
  );
}
