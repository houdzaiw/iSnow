part of '../rank_page.dart';

final _rankViewModelProvider = NotifierProvider<_RankViewModel, _RankState>(
  _RankViewModel.new,
);

class _RankViewModel extends Notifier<_RankState> {
  @override
  _RankState build() {
    const initial = _RankState.initial();
    Future.microtask(() => ensureLoaded(initial.category, initial.period));
    return initial;
  }

  Future<void> reload() async {
    await refresh(state.category, state.period);
  }

  Future<void> refresh([_RankCategory? category, _RankPeriod? period]) async {
    final targetCategory = category ?? state.category;
    final targetPeriod = period ?? state.period;
    await _load(
      _RankQuery(category: targetCategory, period: targetPeriod),
      force: true,
    );
  }

  Future<void> selectCategory(_RankCategory category) async {
    final targetPeriod = state.periodFor(category);
    if (state.category != category || state.period != targetPeriod) {
      state = state.copyWith(category: category, period: targetPeriod);
    }
    await ensureLoaded(category, targetPeriod);
  }

  Future<void> selectPeriod(
    _RankPeriod period, {
    _RankCategory? category,
  }) async {
    final targetCategory = category ?? state.category;
    final nextPeriods = Map<_RankCategory, _RankPeriod>.of(
      state.periodsByCategory,
    )..[targetCategory] = period;

    if (state.category == targetCategory) {
      state = state.copyWith(period: period, periodsByCategory: nextPeriods);
    } else {
      state = state.copyWith(periodsByCategory: nextPeriods);
    }
    await ensureLoaded(targetCategory, period);
  }

  Future<void> ensureLoaded(
    _RankCategory category, [
    _RankPeriod? period,
  ]) async {
    final query = _RankQuery(
      category: category,
      period: period ?? state.period,
    );
    if (state.hasLoaded(query) || state.isLoadingQuery(query)) return;
    await _load(query);
  }

  Future<void> _load(_RankQuery query, {bool force = false}) async {
    if (!force && (state.hasLoaded(query) || state.isLoadingQuery(query))) {
      return;
    }

    state = state.startLoading(query);

    try {
      final board = await ref
          .read(_rankRepositoryProvider)
          .fetchRank(category: query.category, period: query.period);
      state = state.putBoard(query, board);
    } catch (error) {
      state = state.putError(query, error);
    }
  }
}
