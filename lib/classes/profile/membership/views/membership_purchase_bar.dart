import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../membership_models.dart';
import '../membership_view_model.dart';
import 'membership_widgets.dart';
import 'membership_flows.dart';

class MembershipPurchaseBar extends ConsumerWidget {
  const MembershipPurchaseBar({
    super.key,
    required this.kind,
    required this.flows,
  });
  final MembershipKind kind;
  final MembershipFlows flows;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(membershipViewModelProvider);
    final model = ref.read(membershipViewModelProvider.notifier);
    final vip = kind == MembershipKind.vip;
    final grades = vip ? state.vip?.grades ?? [] : state.noble?.grades ?? [];
    final grade = vip ? state.selectedVipGrade : state.selectedNobleGrade;
    final enabled =
        !state.submitting &&
        grade != null &&
        (vip || state.noble?.enabled == true);
    final action = vip ? MembershipAction.buyVip : MembershipAction.buyNoble;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: MembershipTheme.panel,
        borderRadius: MembershipTheme.sheetRadius,
      ),
      child: Padding(
        padding: MembershipTheme.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vip)
              MembershipGradeOptions(
                grades: grades,
                selected: state.vipGrade,
                onSelected: state.submitting
                    ? null
                    : (id) => model.selectGrade(kind, id),
              )
            else
              Row(
                children: [
                  const MembershipImage(AppAssets.membershipCoin),
                  MembershipTheme.rowGap,
                  Expanded(
                    child: InkWell(
                      onTap: enabled
                          ? () => flows.sheet<void>(
                              (c) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MembershipGradeOptions(
                                    grades: grades,
                                    selected: state.nobleGrade,
                                    onSelected: (id) {
                                      model.selectGrade(kind, id);
                                      Navigator.pop(c);
                                    },
                                  ),
                                ],
                              ),
                            )
                          : null,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              grade == null
                                  ? '--'
                                  : context.l10n.t('membership.package', {
                                      'coins': '${grade.payable}',
                                      'days': '${grade.days}',
                                    }),
                              style: MembershipTheme.heading,
                            ),
                          ),
                          const MembershipImage(AppAssets.membershipArrow),
                        ],
                      ),
                    ),
                  ),
                  if (grade != null && grade.payable < grade.price)
                    Text('${grade.price}', style: MembershipTheme.strike),
                ],
              ),
            MembershipTheme.dialogGap,
            Row(
              children: [
                Expanded(
                  child: MembershipButton(
                    text: context.l10n.t('membership.send'),
                    gold: false,
                    onTap: enabled
                        ? () => flows.act(action, chooseRecipient: true)
                        : null,
                  ),
                ),
                MembershipTheme.rowGap,
                Expanded(
                  child: MembershipButton(
                    busy: state.submitting,
                    text: context.l10n.t(
                      grade == null || (!vip && state.noble?.enabled != true)
                          ? 'membership.comingSoon'
                          : (vip
                                ? state.vip?.active == true
                                : state.noble?.owned == true)
                          ? 'membership.renew'
                          : 'membership.activate',
                    ),
                    onTap: enabled ? () => flows.act(action) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
