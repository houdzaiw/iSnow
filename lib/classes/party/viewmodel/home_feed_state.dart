part of '../party_page.dart';

class _HomeFeedState {
  const _HomeFeedState({
    required this.banners,
    required this.friends,
    required this.hotCountries,
    required this.rooms,
    this.selectedCountryCode,
  });

  final List<_HomeBannerItem> banners;
  final List<_HomeFriendItem> friends;
  final List<CountryInfo> hotCountries;
  final List<_HomeRoomItem> rooms;
  final String? selectedCountryCode;

  _HomeFeedState copyWith({
    List<_HomeRoomItem>? rooms,
    String? selectedCountryCode,
    bool clearSelectedCountryCode = false,
  }) {
    return _HomeFeedState(
      banners: banners,
      friends: friends,
      hotCountries: hotCountries,
      rooms: rooms ?? this.rooms,
      selectedCountryCode: clearSelectedCountryCode
          ? null
          : selectedCountryCode ?? this.selectedCountryCode,
    );
  }
}

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
