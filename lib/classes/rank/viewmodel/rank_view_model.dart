part of '../rank_page.dart';

final _rankViewModelProvider = NotifierProvider<_RankViewModel, _RankState>(
  _RankViewModel.new,
);

class _RankViewModel extends Notifier<_RankState> {
  @override
  _RankState build() {
    const initial = _RankState.initial();
    Future.microtask(() => ensureLoaded(initial.category));
    return initial;
  }

  Future<void> reload() async {
    await refresh(state.category);
  }

  Future<void> refresh([_RankCategory? category]) async {
    final targetCategory = category ?? state.category;
    await _load(
      _RankQuery(category: targetCategory, period: state.period),
      force: true,
    );
  }

  Future<void> selectCategory(_RankCategory category) async {
    if (state.category != category) {
      state = state.copyWith(category: category);
    }
    await ensureLoaded(category);
  }

  Future<void> selectPeriod(_RankPeriod period) async {
    if (state.period != period) {
      state = state.copyWith(period: period);
    }
    await ensureLoaded(state.category);
  }

  Future<void> ensureLoaded(_RankCategory category) async {
    final query = _RankQuery(category: category, period: state.period);
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
