import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../membership_aux_view_model.dart';
import '../membership_models.dart';
import 'membership_flows.dart';
import 'membership_widgets.dart';

class MembershipRewardsSheet extends ConsumerStatefulWidget {
  const MembershipRewardsSheet({super.key, required this.flows});
  final MembershipFlows flows;
  @override
  ConsumerState<MembershipRewardsSheet> createState() =>
      _MembershipRewardsSheetState();
}

class _MembershipRewardsSheetState
    extends ConsumerState<MembershipRewardsSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(membershipAuxProvider.notifier).load('rewards');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipAuxProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.t('membership.reward'), style: MembershipTheme.title),
        MembershipTheme.sectionGap,
        if (state.rewards?.isNotEmpty != true)
          MembershipErrorView(
            error: state.errors['rewards'],
            loading: state.loading.contains('rewards'),
            retry: () => ref
                .read(membershipAuxProvider.notifier)
                .load('rewards', force: true),
          )
        else
          for (final reward in state.rewards!)
            Padding(
              padding: MembershipTheme.smallPadding,
              child: Row(
                children: [
                  MembershipImage(reward.icon, size: MembershipTheme.badge),
                  MembershipTheme.rowGap,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward.name, style: MembershipTheme.body),
                        Text(
                          context.l10n.t('membership.rewardRemaining', {
                            'remaining': '${reward.remaining}',
                            'total': '${reward.limit}',
                            'days': '${reward.days}',
                          }),
                          style: MembershipTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  MembershipTheme.rowGap,
                  MembershipButton(
                    text: context.l10n.t('membership.send'),
                    onTap: reward.remaining <= 0
                        ? null
                        : () => widget.flows.act(
                            MembershipAction.reward,
                            chooseRecipient: true,
                            reward: reward,
                          ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
