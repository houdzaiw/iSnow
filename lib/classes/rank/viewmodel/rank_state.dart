part of '../rank_page.dart';

class _RankState {
  const _RankState({
    required this.category,
    required this.period,
    this.periodsByCategory = const <_RankCategory, _RankPeriod>{},
    this.boards = const <_RankQuery, _RankBoard>{},
    this.loadingQueries = const <_RankQuery>{},
    this.errors = const <_RankQuery, Object>{},
  });

  const _RankState.initial()
    : category = _RankCategory.wealth,
      period = _RankPeriod.daily,
      periodsByCategory = const <_RankCategory, _RankPeriod>{},
      boards = const <_RankQuery, _RankBoard>{},
      loadingQueries = const <_RankQuery>{},
      errors = const <_RankQuery, Object>{};

  final _RankCategory category;
  final _RankPeriod period;
  final Map<_RankCategory, _RankPeriod> periodsByCategory;
  final Map<_RankQuery, _RankBoard> boards;
  final Set<_RankQuery> loadingQueries;
  final Map<_RankQuery, Object> errors;

  _RankPeriod periodFor(_RankCategory category) {
    return periodsByCategory[category] ?? _RankPeriod.daily;
  }

  _RankQuery queryFor(_RankCategory category, [_RankPeriod? period]) {
    return _RankQuery(category: category, period: period ?? this.period);
  }

  _RankBoard? boardFor(_RankCategory category, [_RankPeriod? period]) {
    return boards[queryFor(category, period)];
  }

  Object? errorFor(_RankCategory category, [_RankPeriod? period]) {
    return errors[queryFor(category, period)];
  }

  bool hasLoaded(_RankQuery query) {
    return boards.containsKey(query);
  }

  bool isLoadingQuery(_RankQuery query) {
    return loadingQueries.contains(query);
  }

  _RankState copyWith({
    _RankCategory? category,
    _RankPeriod? period,
    Map<_RankCategory, _RankPeriod>? periodsByCategory,
    Map<_RankQuery, _RankBoard>? boards,
    Set<_RankQuery>? loadingQueries,
    Map<_RankQuery, Object>? errors,
  }) {
    return _RankState(
      category: category ?? this.category,
      period: period ?? this.period,
      periodsByCategory: periodsByCategory ?? this.periodsByCategory,
      boards: boards ?? this.boards,
      loadingQueries: loadingQueries ?? this.loadingQueries,
      errors: errors ?? this.errors,
    );
  }

  _RankState startLoading(_RankQuery query) {
    final nextErrors = Map<_RankQuery, Object>.of(errors)..remove(query);
    return copyWith(
      loadingQueries: {...loadingQueries, query},
      errors: nextErrors,
    );
  }

  _RankState putBoard(_RankQuery query, _RankBoard board) {
    final nextBoards = Map<_RankQuery, _RankBoard>.of(boards)..[query] = board;
    final nextLoading = Set<_RankQuery>.of(loadingQueries)..remove(query);
    final nextErrors = Map<_RankQuery, Object>.of(errors)..remove(query);
    return copyWith(
      boards: nextBoards,
      loadingQueries: nextLoading,
      errors: nextErrors,
    );
  }

  _RankState putError(_RankQuery query, Object error) {
    final nextLoading = Set<_RankQuery>.of(loadingQueries)..remove(query);
    final nextErrors = Map<_RankQuery, Object>.of(errors)..[query] = error;
    return copyWith(loadingQueries: nextLoading, errors: nextErrors);
  }
}

class _RankQuery {
  const _RankQuery({required this.category, required this.period});

  final _RankCategory category;
  final _RankPeriod period;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _RankQuery &&
            other.category == category &&
            other.period == period;
  }

  @override
  int get hashCode => Object.hash(category, period);
}
