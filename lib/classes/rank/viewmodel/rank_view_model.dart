part of '../rank_page.dart';

final _rankViewModelProvider =
    AsyncNotifierProvider<_RankViewModel, _RankState>(_RankViewModel.new);

class _RankViewModel extends AsyncNotifier<_RankState> {
  _RankCategory _category = _RankCategory.wealth;
  _RankPeriod _period = _RankPeriod.daily;

  @override
  Future<_RankState> build() {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null) {
      await reload();
      return;
    }

    final board = await ref
        .read(_rankRepositoryProvider)
        .fetchRank(category: current.category, period: current.period);
    state = AsyncValue.data(current.copyWith(board: board));
  }

  Future<void> selectCategory(_RankCategory category) async {
    if (_category == category && state.hasValue) return;
    _category = category;
    await reload();
  }

  Future<void> selectPeriod(_RankPeriod period) async {
    if (_period == period && state.hasValue) return;
    _period = period;
    await reload();
  }

  Future<_RankState> _load() async {
    final board = await ref
        .read(_rankRepositoryProvider)
        .fetchRank(category: _category, period: _period);
    return _RankState(category: _category, period: _period, board: board);
  }
}
