part of '../rank_page.dart';

class _RankContentView extends ConsumerStatefulWidget {
  const _RankContentView({required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<_RankContentView> createState() => _RankContentViewState();
}

class _RankContentViewState extends ConsumerState<_RankContentView>
    with SingleTickerProviderStateMixin {
  late final TabController _categoryController;
  _RankCategory? _requestedCategory;

  @override
  void initState() {
    super.initState();
    _categoryController = TabController(
      length: _RankCategory.values.length,
      initialIndex: _categoryIndex(_RankCategory.wealth),
      vsync: this,
    );
    _categoryController.addListener(_handleCategoryChanged);
  }

  @override
  void dispose() {
    _categoryController.removeListener(_handleCategoryChanged);
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_rankViewModelProvider);
    if (_requestedCategory == state.category) {
      _requestedCategory = null;
    }
    _syncCategoryController(state.category);
    final currentBoard = state.boardFor(state.category);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(state.category.backgroundAsset, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _RankHeader(
                  tabController: _categoryController,
                  onBack: widget.onBack,
                ),
                const SizedBox(height: 15),
                _buildContainerView(state),
              ],
            ),
          ),
        ),
        if (currentBoard?.me != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RankMeBar(
              entry: currentBoard!.me!,
              category: state.category,
            ),
          ),
      ],
    );
  }

  Widget _buildContainerView(_RankState state) {
    final currentBoard = state.boardFor(state.category);

    return Expanded(
      child: Column(
        children: [
          _RankPeriodTabs(
            selectedPeriod: state.period,
            onSelect: (period) =>
                ref.read(_rankViewModelProvider.notifier).selectPeriod(period),
          ),
          const SizedBox(height: 17),
          _RankCountdown(seconds: currentBoard?.countdown ?? 0),
          Expanded(
            child: ExtendedTabBarView(
              controller: _categoryController,
              cacheExtent: 1,
              children: [
                for (final category in _RankCategory.values)
                  _RankBoardTabView(
                    category: category,
                    board: state.boardFor(category),
                    error: state.errorFor(category),
                    onRefresh: () => ref
                        .read(_rankViewModelProvider.notifier)
                        .refresh(category),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _categoryIndex(_RankCategory category) {
    final index = _RankCategory.values.indexOf(category);
    return index < 0 ? 0 : index;
  }

  void _syncCategoryController(_RankCategory category) {
    final targetIndex = _categoryIndex(category);
    if (_categoryController.index == targetIndex ||
        _categoryController.indexIsChanging) {
      return;
    }
    _categoryController.index = targetIndex;
  }

  void _handleCategoryChanged() {
    if (_categoryController.indexIsChanging) return;

    final animationValue =
        _categoryController.animation?.value ?? _categoryController.index;
    if ((animationValue - _categoryController.index).abs() > 0.01) return;

    final category = _RankCategory.values[_categoryController.index];
    final state = ref.read(_rankViewModelProvider);
    if (category == state.category || category == _requestedCategory) {
      return;
    }

    _requestedCategory = category;
    ref.read(_rankViewModelProvider.notifier).selectCategory(category);
  }
}

class _RankBoardTabView extends StatelessWidget {
  const _RankBoardTabView({
    required this.category,
    required this.board,
    required this.error,
    required this.onRefresh,
  });

  final _RankCategory category;
  final _RankBoard? board;
  final Object? error;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final board = this.board;
    final entries = board?.entries ?? const <_RankEntry>[];
    final topEntries = entries.take(3).toList(growable: false);
    final listEntries = entries.skip(3).toList(growable: false);

    return RefreshIndicator(
      color: const Color.fromRGBO(254, 229, 190, 1),
      backgroundColor: const Color.fromRGBO(32, 18, 6, 1),
      onRefresh: onRefresh,
      child: board == null
          ? _RankBoardStateList(error: error, onRetry: onRefresh)
          : entries.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 100),
              children: [_RankStateMessage(text: context.l10n.t('rank.empty'))],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: 8,
                bottom: board.me == null ? 32 : 104,
              ),
              children: [
                _RankPodiumView(entries: topEntries, category: category),
                const SizedBox(height: 8),
                _RankListView(entries: listEntries, category: category),
              ],
            ),
    );
  }
}

class _RankBoardStateList extends StatelessWidget {
  const _RankBoardStateList({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 100),
      children: [
        if (error != null)
          _RankStateMessage(
            text: context.l10n.t('rank.loadFailed'),
            actionLabel: context.l10n.t('app.retry'),
            onAction: () => onRetry(),
          )
        else
          Center(child: const CircularProgressIndicator()),
      ],
    );
  }
}

class _RankHeader extends StatelessWidget {
  const _RankHeader({required this.tabController, required this.onBack});

  final TabController tabController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 40,
            height: 36,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: Image.asset(
                AppAssets.backWhiteButton,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),
          _RankCategoryTabs(tabController: tabController),
          SizedBox(
            width: 40,
            height: 36,
            child: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              tooltip: context.l10n.t('rank.help'),
              icon: Image.asset(
                AppAssets.lanhuRankHelp,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCategoryTabs extends StatelessWidget {
  const _RankCategoryTabs({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final categories = _RankCategory.values;

    return SizedBox(
      width: 228,
      height: 27,
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          final currentIndex = tabController.index;

          return ExtendedTabBar(
            controller: tabController,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            indicator: const BoxDecoration(color: AppColors.transparent),
            indicatorColor: AppColors.transparent,
            dividerColor: AppColors.transparent,
            labelPadding: EdgeInsets.zero,
            overlayColor: WidgetStateProperty.all(AppColors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: [
              for (var index = 0; index < categories.length; index++)
                Tab(
                  height: 27,
                  child: _RankCategoryTab(
                    category: categories[index],
                    selected: index == currentIndex,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RankCategoryTab extends StatelessWidget {
  const _RankCategoryTab({required this.category, required this.selected});

  final _RankCategory category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
