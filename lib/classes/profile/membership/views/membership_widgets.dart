import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../manager/api_error_message.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_network_image.dart';
import '../membership_models.dart';
import '../membership_state.dart';

String membershipError(BuildContext context, Object? error) =>
    error is MembershipFailure
    ? context.l10n.t(error.key)
    : userFacingErrorMessage(
        error,
        fallback: context.l10n.t('membership.failed'),
      );
String membershipRemaining(BuildContext context, Duration value) {
  String digits(int n) => n.toString().padLeft(2, '0');
  return context.l10n.t('membership.remaining', {
    'days': '${value.inDays}',
    'time':
        '${digits(value.inHours % 24)}:${digits(value.inMinutes % 60)}:${digits(value.inSeconds % 60)}',
  });
}

String vipMembershipStatus(BuildContext context, MembershipState state) {
  final vip = state.vip;
  if (vip == null) {
    return context.l10n.t(
      state.loadingVip ? 'membership.loading' : 'membership.statusUnknown',
    );
  }
  if (vip.status == 0) return context.l10n.t('membership.notActivated');
  if (!vip.active) return context.l10n.t('membership.expired');
  if (vip.timeProtection) return context.l10n.t('membership.longTerm');
  final remaining = vip.remaining(state.now ?? DateTime.now());
  return remaining == Duration.zero
      ? context.l10n.t('membership.expired')
      : membershipRemaining(context, remaining);
}

String nobleMembershipStatus(BuildContext context, MembershipState state) {
  final nobles = state.nobles;
  if (nobles == null) {
    return context.l10n.t(
      state.loadingNoble ? 'membership.loading' : 'membership.statusUnknown',
    );
  }
  final owned = nobles.where((n) => n.owned).lastOrNull;
  if (owned == null) return context.l10n.t('membership.notActivated');
  final remaining = owned.remaining(state.now ?? DateTime.now());
  return remaining == Duration.zero
      ? context.l10n.t('membership.expired')
      : membershipRemaining(context, remaining);
}

class MembershipImage extends StatelessWidget {
  const MembershipImage(
    this.source, {
    super.key,
    this.size = MembershipTheme.icon,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
  final String source;
  final double size;
  final double? width, height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final missing = Image.asset(
      AppAssets.iconMissing,
      width: width ?? size,
      height: height ?? size,
      fit: BoxFit.contain,
    );
    if (source.isEmpty) return missing;
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: width ?? size,
        height: height ?? size,
        fit: fit,
        errorBuilder: (_, _, _) => missing,
      );
    }
    return AppNetworkImage(
      url: source,
      width: width ?? size,
      height: height ?? size,
      fit: fit,
      placeholder: SizedBox(
        width: width ?? size,
        height: height ?? size,
        child: const Center(
          child: CircularProgressIndicator(color: MembershipTheme.gold),
        ),
      ),
      errorWidget: missing,
    );
  }
}

class MembershipAssetButton extends StatelessWidget {
  const MembershipAssetButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
  });
  final String asset, label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      child: SizedBox.square(
        dimension: MembershipTheme.touch,
        child: InkWell(
          onTap: onTap,
          child: Center(child: MembershipImage(asset)),
        ),
      ),
    ),
  );
}

class MembershipButton extends StatelessWidget {
  const MembershipButton({
    super.key,
    required this.text,
    required this.onTap,
    this.gold = true,
    this.busy = false,
  });
  final String text;
  final VoidCallback? onTap;
  final bool gold, busy;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null && !busy ? MembershipTheme.faded : 1,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: gold ? MembershipTheme.gradient : null,
        border: MembershipTheme.border,
        borderRadius: MembershipTheme.pill,
      ),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: MembershipTheme.pill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MembershipTheme.touch),
          child: Padding(
            padding: MembershipTheme.smallPadding,
            child: Center(
              child: busy
                  ? const SizedBox.square(
                      dimension: MembershipTheme.icon,
                      child: CircularProgressIndicator(
                        color: MembershipTheme.brown,
                      ),
                    )
                  : Text(
                      text,
                      style: gold
                          ? MembershipTheme.button
                          : MembershipTheme.body,
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

class MembershipErrorView extends StatelessWidget {
  const MembershipErrorView({
    super.key,
    this.error,
    required this.retry,
    this.loading = false,
  });
  final Object? error;
  final VoidCallback retry;
  final bool loading;
  @override
  Widget build(BuildContext context) => Padding(
    padding: MembershipTheme.padding,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const CircularProgressIndicator(color: MembershipTheme.gold)
          else ...[
            Text(
              error == null
                  ? context.l10n.t('membership.noData')
                  : membershipError(context, error),
              style: MembershipTheme.caption,
              textAlign: TextAlign.center,
            ),
            MembershipTheme.dialogGap,
            MembershipButton(
              text: context.l10n.t('membership.retry'),
              onTap: retry,
            ),
          ],
        ],
      ),
    ),
  );
}

class MembershipGradeOptions extends StatelessWidget {
  const MembershipGradeOptions({
    super.key,
    required this.grades,
    required this.selected,
    required this.onSelected,
  });
  final List<MembershipGrade> grades;
  final int selected;
  final ValueChanged<int>? onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: MembershipTheme.m,
      runSpacing: MembershipTheme.m,
      children: [
        for (final grade in grades)
          SizedBox(
            width: (constraints.maxWidth - MembershipTheme.m * 2) / 3,
            child: InkWell(
              onTap: onSelected == null ? null : () => onSelected!(grade.id),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: MembershipTheme.radius,
                  border: MembershipTheme.border,
                  gradient: grade.id == selected
                      ? MembershipTheme.gradient
                      : null,
                ),
                child: Padding(
                  padding: MembershipTheme.smallPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const MembershipImage(AppAssets.membershipCoin),
                          MembershipTheme.rowGap,
                          Flexible(
                            child: Text(
                              '${grade.payable}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: grade.id == selected
                                  ? MembershipTheme.button
                                  : MembershipTheme.body,
                            ),
                          ),
                        ],
                      ),
                      if (grade.payable < grade.price)
                        Text('${grade.price}', style: MembershipTheme.strike),
                      Text(
                        context.l10n.t('membership.days', {
                          'days': '${grade.days}',
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: grade.id == selected
                            ? MembershipTheme.button
                            : MembershipTheme.tiny,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
