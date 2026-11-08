part of '../party_page.dart';

class _PartyFeedState {
  const _PartyFeedState({
    required this.sortTab,
    this.items = const [],
    this.pageNum = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
  });

  final _FeedSortTab sortTab;
  final List<_PartyFeedItem> items;
  final int pageNum;
  final bool hasMore;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Object? error;

  _PartyFeedState copyWith({
    List<_PartyFeedItem>? items,
    int? pageNum,
    bool? hasMore,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    Object? error = _partyFeedUnset,
  }) {
    return _PartyFeedState(
      sortTab: sortTab,
      items: items ?? this.items,
      pageNum: pageNum ?? this.pageNum,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: identical(error, _partyFeedUnset) ? this.error : error,
    );
  }
}

const Object _partyFeedUnset = Object();
