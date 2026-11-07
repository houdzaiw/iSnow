import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../membership_aux_view_model.dart';
import '../membership_state.dart';
import '../membership_view_model.dart';
import 'membership_flows.dart';
import 'membership_settings_page.dart';
import 'membership_widgets.dart';

class MembershipTitlesPage extends ConsumerStatefulWidget {
  const MembershipTitlesPage({super.key});
  @override
  ConsumerState<MembershipTitlesPage> createState() =>
      _MembershipTitlesPageState();
}

class _MembershipTitlesPageState extends ConsumerState<MembershipTitlesPage> {
  late final MembershipFlows _flows;
  @override
  void initState() {
    super.initState();
    _flows = MembershipFlows(context, ref);
    Future.microtask(() {
      if (mounted) {
        ref.read(membershipAuxProvider.notifier).load('titles', force: true);
      }
    });
  }

  @override
  void dispose() {
    _flows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipAuxProvider);
    final membership = ref.watch(membershipViewModelProvider);
    final model = ref.read(membershipAuxProvider.notifier);
    return MembershipScaffold(
      title: context.l10n.t('membership.titles'),
      child: state.titles?.isNotEmpty != true
          ? MembershipErrorView(
              error: state.errors['titles'],
              loading: state.loading.contains('titles'),
              retry: () => model.load('titles', force: true),
            )
          : RefreshIndicator(
              onRefresh: () => model.load('titles', force: true),
              child: ListView.builder(
                itemCount: state.titles!.length,
                itemBuilder: (context, index) {
                  final title = state.titles![index];
                  final mine = state.titles!.any(
                    (t) =>
                        t.owner?.uid == membership.account?.uid &&
                        t.owner != null,
                  );
                  return Padding(
                    padding: MembershipTheme.padding,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: MembershipTheme.panel,
                        borderRadius: MembershipTheme.radius,
                      ),
                      child: Padding(
                        padding: MembershipTheme.padding,
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: MembershipTheme.titleRatio,
                              child: MembershipImage(
                                title.image,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Text(title.name, style: MembershipTheme.heading),
                            MembershipTheme.dialogGap,
                            if (title.owner != null)
                              InkWell(
                                onTap: () => context.push(
                                  '/profile-homepage/${title.owner!.uid}',
                                ),
                                child: Text(
                                  context.l10n.t('membership.ownedBy', {
                                    'name': title.owner!.nick ?? '',
                                  }),
                                  style: MembershipTheme.caption,
                                ),
                              )
                            else
                              MembershipButton(
                                text: context.l10n.t('membership.claim'),
                                busy: state.saving.contains('claim'),
                                onTap: () async {
                                  if (membership.nobleLevel < 6 ||
                                      membership.account == null) {
                                    _flows.notice(
                                      context.l10n.t(
                                        'membership.titleUnavailable',
                                      ),
                                    );
                                    return;
                                  }
                                  if (!await _flows.confirm(
                                        context.l10n.t(
                                          mine
                                              ? 'membership.replaceTitle'
                                              : 'membership.claimTitle',
                                        ),
                                      ) ||
                                      !context.mounted) {
                                    return;
                                  }
                                  final result = await model.claim(
                                    title,
                                    nobleLevel: membership.nobleLevel,
                                    account: membership.account!,
                                  );
                                  if (!context.mounted ||
                                      result == MembershipSubmitResult.stale) {
                                    return;
                                  }
                                  if (result == MembershipSubmitResult.failed) {
                                    _flows.notice(
                                      membershipError(
                                        context,
                                        ref
                                            .read(membershipAuxProvider)
                                            .errors['claim'],
                                      ),
                                    );
                                  } else {
                                    ref
                                        .read(
                                          membershipRevisionProvider.notifier,
                                        )
                                        .state++;
                                    await ref
                                        .read(
                                          membershipViewModelProvider.notifier,
                                        )
                                        .load(force: true);
                                    if (context.mounted) {
                                      _flows.notice(
                                        context.l10n.t(
                                          result ==
                                                  MembershipSubmitResult.success
                                              ? 'membership.success'
                                              : 'membership.refreshFailed',
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
