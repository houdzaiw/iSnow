import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../membership_models.dart';
import '../membership_view_model.dart';
import 'membership_widgets.dart';
import 'membership_media.dart';

class MembershipHero extends ConsumerWidget {
  const MembershipHero({super.key, required this.kind});
  final MembershipKind kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(membershipViewModelProvider);
    final model = ref.read(membershipViewModelProvider.notifier);
    final vip = kind == MembershipKind.vip;
    final count = vip ? state.vip!.levels.length : state.nobles!.length;
    final selected = vip
        ? state.vip!.levels.indexWhere((v) => v.level == state.selectedVip)
        : state.nobles!.indexWhere((v) => v.id == state.selectedNoble);
    return SizedBox(
      height: MembershipTheme.heroHeight,
      child: Swiper(
        key: ValueKey(kind),
        itemCount: count,
        loop: false,
        index: selected.clamp(0, count - 1),
        viewportFraction: MembershipTheme.heroViewport,
        scale: MembershipTheme.heroScale,
        onIndexChanged: (index) => vip
            ? model.selectVip(state.vip!.levels[index].level)
            : model.selectNoble(state.nobles![index].id),
        itemBuilder: (context, index) {
          final level = vip
              ? state.vip!.levels[index].level
              : state.nobles![index].id;
          final icon = vip
              ? state.vip!.levels[index].icon
              : state.nobles![index].icon;
          final name = vip ? 'VIP $level' : state.nobles![index].name;
          final cards = AppAssets.membershipVipCards;
          return Center(
            child: Container(
              width: double.infinity,
              height: MembershipTheme.heroCardHeight,
              decoration: BoxDecoration(
                borderRadius: MembershipTheme.radius,
                image: vip
                    ? DecorationImage(
                        image: AssetImage(
                          cards[(level - 1).clamp(0, cards.length - 1)],
                        ),
                        fit: BoxFit.fill,
                      )
                    : null,
              ),
              padding: MembershipTheme.padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!vip && state.nobles![index].preview.isNotEmpty)
                    Expanded(
                      child: MembershipMedia(url: state.nobles![index].preview),
                    )
                  else if (!vip)
                    Expanded(
                      child: MembershipImage(
                        icon,
                        size: MembershipTheme.preview,
                      ),
                    )
                  else
                    MembershipImage(icon, size: MembershipTheme.badge),
                  MembershipTheme.gap,
                  Text(
                    name,
                    style: MembershipTheme.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (vip) ...[
                    MembershipTheme.gap,
                    Text(
                      state.vip!.user.nick ?? '',
                      style: MembershipTheme.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MembershipTierTabs extends ConsumerStatefulWidget {
  const MembershipTierTabs({super.key, required this.kind});
  final MembershipKind kind;
  @override
  ConsumerState<MembershipTierTabs> createState() => _MembershipTierTabsState();
}

class _MembershipTierTabsState extends ConsumerState<MembershipTierTabs> {
  final _controller = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  int? _selected;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipViewModelProvider);
    final model = ref.read(membershipViewModelProvider.notifier);
    final vip = widget.kind == MembershipKind.vip;
    final selected = vip ? state.selectedVip : state.selectedNoble;
    if (_selected != selected) {
      _selected = selected;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final object = _keys[selected]?.currentContext?.findRenderObject();
        if (object != null) {
          _controller.position.ensureVisible(object, alignment: 0.5);
        }
      });
    }
    final items = vip
        ? [
            for (final level in state.vip?.levels ?? <VipMembershipLevel>[])
              (id: level.level, name: 'VIP ${level.level}'),
          ]
        : [
            for (final level in state.nobles ?? <NobleMembership>[])
              (id: level.id, name: level.name),
          ];
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: MembershipTheme.smallPadding,
      child: Row(
        children: [
          for (final item in items)
            TextButton(
              key: _keys.putIfAbsent(item.id, () => GlobalKey()),
              onPressed: state.submitting
                  ? null
                  : () => vip
                        ? model.selectVip(item.id)
                        : model.selectNoble(item.id),
              child: Opacity(
                opacity:
                    item.id == (vip ? state.selectedVip : state.selectedNoble)
                    ? 1
                    : MembershipTheme.faded,
                child: Text(item.name, style: MembershipTheme.caption),
              ),
            ),
        ],
      ),
    );
  }
}

class MembershipPrivileges extends StatelessWidget {
  const MembershipPrivileges({
    super.key,
    required this.items,
    required this.onTap,
    this.active,
    this.total,
  });
  final List<MembershipPrivilege> items;
  final ValueChanged<MembershipPrivilege> onTap;
  final int? active, total;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        context.l10n.t('membership.privileges', {
          'active': '${active ?? items.where((p) => p.active).length}',
          'total': '${total ?? items.length}',
        }),
        style: MembershipTheme.heading,
      ),
      MembershipTheme.sectionGap,
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: MembershipTheme.m,
          runSpacing: MembershipTheme.m,
          children: [
            for (final perk in items)
              SizedBox(
                width: (constraints.maxWidth - MembershipTheme.m * 2) / 3,
                height: MembershipTheme.perkHeight,
                child: InkWell(
                  onTap: () => onTap(perk),
                  child: Opacity(
                    opacity: perk.active ? 1 : MembershipTheme.faded,
                    child: Column(
                      children: [
                        MembershipImage(
                          perk.icon,
                          size: MembershipTheme.perkImage,
                        ),
                        MembershipTheme.gap,
                        Text(
                          perk.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: MembershipTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
