part of '../rank_page.dart';

class _RankContentView extends ConsumerStatefulWidget {
  const _RankContentView({required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<_RankContentView> createState() => _RankContentViewState();
}

class _RankContentViewState extends ConsumerState<_RankContentView>
    with TickerProviderStateMixin {
  late final TabController _categoryController;
  late final Map<_RankCategory, TabController> _periodControllers;
  _RankCategory? _requestedCategory;
  final Map<_RankCategory, _RankPeriod> _requestedPeriods =
      <_RankCategory, _RankPeriod>{};

  @override
  void initState() {
    super.initState();
    _categoryController = TabController(
      length: _RankCategory.values.length,
      initialIndex: _categoryIndex(_RankCategory.wealth),
      vsync: this,
    );
    _periodControllers = {
      for (final category in _RankCategory.values)
        category: TabController(
          length: _RankPeriod.values.length,
          initialIndex: _periodIndex(_RankPeriod.daily),
          vsync: this,
        ),
    };
    _categoryController.addListener(_handleCategoryChanged);
    for (final entry in _periodControllers.entries) {
      entry.value.addListener(() => _handlePeriodChanged(entry.key));
    }
  }

  @override
  void dispose() {
    for (final controller in _periodControllers.values) {
      controller.dispose();
    }
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
    final requestedPeriod = _requestedPeriods[state.category];
    if (requestedPeriod == state.periodFor(state.category)) {
      _requestedPeriods.remove(state.category);
    }
    _syncCategoryController(state.category);
    for (final category in _RankCategory.values) {
      _syncPeriodController(category, state.periodFor(category));
    }
    final currentBoard = state.boardFor(state.category, state.period);

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
    return Expanded(
      child: ExtendedTabBarView(
        controller: _categoryController,
        cacheExtent: 1,
        children: [
          for (final category in _RankCategory.values)
            _RankCategoryBoardView(
              category: category,
              state: state,
              periodController: _periodControllers[category]!,
              onSelectPeriod: (period) =>
                  _handlePeriodSelected(category, period),
              onRefresh: (period) => ref
                  .read(_rankViewModelProvider.notifier)
                  .refresh(category, period),
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

  int _periodIndex(_RankPeriod period) {
    final index = _RankPeriod.values.indexOf(period);
    return index < 0 ? 0 : index;
  }

  void _syncPeriodController(_RankCategory category, _RankPeriod period) {
    final controller = _periodControllers[category]!;
    final targetIndex = _periodIndex(period);
    if (controller.index == targetIndex || controller.indexIsChanging) {
      return;
    }
    controller.index = targetIndex;
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

  void _handlePeriodSelected(_RankCategory category, _RankPeriod period) {
    final controller = _periodControllers[category]!;
    final targetIndex = _periodIndex(period);
    if (controller.index != targetIndex) {
      controller.animateTo(targetIndex);
    }

    final state = ref.read(_rankViewModelProvider);
    if (period == state.periodFor(category)) return;

    _requestedPeriods[category] = period;
    ref
        .read(_rankViewModelProvider.notifier)
        .selectPeriod(period, category: category);
  }

  void _handlePeriodChanged(_RankCategory category) {
    final controller = _periodControllers[category]!;
    if (controller.indexIsChanging) return;

    final animationValue = controller.animation?.value ?? controller.index;
    if ((animationValue - controller.index).abs() > 0.01) return;

    final period = _RankPeriod.values[controller.index];
    final state = ref.read(_rankViewModelProvider);
    if (category != state.category ||
        period == state.periodFor(category) ||
        period == _requestedPeriods[category]) {
      return;
    }

    _requestedPeriods[category] = period;
    ref
        .read(_rankViewModelProvider.notifier)
        .selectPeriod(period, category: category);
  }
}

class _RankCategoryBoardView extends StatelessWidget {
  const _RankCategoryBoardView({
    required this.category,
    required this.state,
    required this.periodController,
    required this.onSelectPeriod,
    required this.onRefresh,
  });

  final _RankCategory category;
  final _RankState state;
  final TabController periodController;
  final ValueChanged<_RankPeriod> onSelectPeriod;
  final Future<void> Function(_RankPeriod period) onRefresh;

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = state.periodFor(category);
    final currentBoard = state.boardFor(category, selectedPeriod);

    return Column(
      children: [
        _RankPeriodTabs(
          tabController: periodController,
          selectedPeriod: selectedPeriod,
          onSelect: onSelectPeriod,
        ),
        const SizedBox(height: 17),
        Expanded(
          child: Column(
            children: [
              _RankCountdown(seconds: currentBoard?.countdown ?? 0),
              Expanded(
                child: ExtendedTabBarView(
                  controller: periodController,
                  cacheExtent: 1,
                  link: true,
                  children: [
                    for (final period in _RankPeriod.values)
                      _RankBoardTabView(
                        category: category,
                        board: state.boardFor(category, period),
                        error: state.errorFor(category, period),
                        onRefresh: () => onRefresh(period),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
  const _RankPeriodTabs({
    required this.tabController,
    required this.selectedPeriod,
    required this.onSelect,
  });

  final TabController tabController;
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
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          final periods = _RankPeriod.values;
          final fallbackIndex = periods.indexOf(selectedPeriod);
          final currentIndex = tabController.index < periods.length
              ? tabController.index
              : fallbackIndex;

          return ExtendedTabBar(
            controller: tabController,
            indicator: const BoxDecoration(color: AppColors.transparent),
            indicatorColor: AppColors.transparent,
            dividerColor: AppColors.transparent,
            labelPadding: EdgeInsets.zero,
            overlayColor: WidgetStateProperty.all(AppColors.transparent),
            splashFactory: NoSplash.splashFactory,
            onTap: (index) => onSelect(periods[index]),
            tabs: [
              for (var index = 0; index < periods.length; index++)
                Tab(
                  height: 20,
                  child: _RankPeriodTab(
                    period: periods[index],
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
