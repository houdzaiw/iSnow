part of '../rank_page.dart';

class _RankState {
  const _RankState({
    required this.category,
    required this.period,
    required this.board,
  });

  final _RankCategory category;
  final _RankPeriod period;
  final _RankBoard board;

  _RankState copyWith({
    _RankCategory? category,
    _RankPeriod? period,
    _RankBoard? board,
  }) {
    return _RankState(
      category: category ?? this.category,
      period: period ?? this.period,
      board: board ?? this.board,
    );
  }
}
