part of '../rank_page.dart';

class _RankContentView extends StatelessWidget {
  const _RankContentView({
    required this.state,
    required this.onBack,
    required this.onSelectCategory,
    required this.onSelectPeriod,
    required this.onRefresh,
  });

  final _RankState state;
  final VoidCallback onBack;
  final ValueChanged<_RankCategory> onSelectCategory;
  final ValueChanged<_RankPeriod> onSelectPeriod;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final entries = state.board.entries;
    final topEntries = entries.take(3).toList(growable: false);
    final listEntries = entries.skip(3).toList(growable: false);

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _RankHeader(
                category: state.category,
                onBack: onBack,
                onSelectCategory: onSelectCategory,
              ),
              const SizedBox(height: 15),
              _RankPeriodTabs(
                selectedPeriod: state.period,
                onSelect: onSelectPeriod,
              ),
              const SizedBox(height: 17),
              _RankCountdown(seconds: state.board.countdown),
              Expanded(
                child: RefreshIndicator(
                  color: const Color.fromRGBO(254, 229, 190, 1),
                  backgroundColor: const Color.fromRGBO(32, 18, 6, 1),
                  onRefresh: onRefresh,
                  child: entries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 100),
                          children: [
                            _RankStateMessage(
                              text: context.l10n.t('rank.empty'),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: 8,
                            bottom: state.board.me == null ? 32 : 104,
                          ),
                          children: [
                            _RankPodiumView(
                              entries: topEntries,
                              category: state.category,
                            ),
                            const SizedBox(height: 8),
                            _RankListView(
                              entries: listEntries,
                              category: state.category,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        if (state.board.me != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RankMeBar(entry: state.board.me!, category: state.category),
          ),
      ],
    );
  }
}

class _RankHeader extends StatelessWidget {
  const _RankHeader({
    required this.category,
    required this.onBack,
    required this.onSelectCategory,
  });

  final _RankCategory category;
  final VoidCallback onBack;
  final ValueChanged<_RankCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 21,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded),
              color: Colors.white,
              iconSize: 34,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          SizedBox(
            width: 228,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final item in _RankCategory.values)
                  _RankCategoryTab(
                    category: item,
                    selected: item == category,
                    onTap: () => onSelectCategory(item),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 28,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.help_outline_rounded),
              color: Colors.white.withValues(alpha: 0.75),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              tooltip: context.l10n.t('rank.help'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCategoryTab extends StatelessWidget {
  const _RankCategoryTab({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _RankCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 58,
        height: 27,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (selected)
              Positioned(
                top: 14,
                child: Image.asset(
                  AppAssets.lanhuRankTabUnderline,
                  width: 56,
                  height: 13,
                ),
              ),
            Text(
              category.label(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: selected ? 1 : 0.4),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankPeriodTabs extends StatelessWidget {
  const _RankPeriodTabs({required this.selectedPeriod, required this.onSelect});

  final _RankPeriod selectedPeriod;
  final ValueChanged<_RankPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 228,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        children: [
          for (final period in _RankPeriod.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(period),
                child: _RankPeriodTab(
                  period: period,
                  selected: period == selectedPeriod,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RankPeriodTab extends StatelessWidget {
  const _RankPeriodTab({required this.period, required this.selected});

  final _RankPeriod period;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(254, 240, 215, 1),
                  Color.fromRGBO(254, 229, 190, 1),
                ],
              )
            : null,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        period.label(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected
              ? const Color.fromRGBO(152, 102, 27, 1)
              : Colors.white.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RankCountdown extends StatelessWidget {
  const _RankCountdown({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final normalizedSeconds = seconds > 1000000000 ? seconds ~/ 1000 : seconds;
    final duration = Duration(
      seconds: normalizedSeconds < 0 ? 0 : normalizedSeconds,
    );
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    final parts = [
      _CountdownPart(value: days, label: context.l10n.t('rank.day')),
      _CountdownPart(value: hours, label: context.l10n.t('rank.hour')),
      _CountdownPart(value: minutes, label: context.l10n.t('rank.min')),
      _CountdownPart(value: secs, label: context.l10n.t('rank.sec')),
    ];

    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < parts.length; index++) ...[
            parts[index],
            if (index != parts.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _CountdownPart extends StatelessWidget {
  const _CountdownPart({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(99, 75, 51, 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
      ],
    );
  }
}
