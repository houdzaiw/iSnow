part of '../party_page.dart';

const int _partyListPageSize = 10;

class _PartyFeedViewModel
    extends FamilyNotifier<_PartyFeedState, _FeedSortTab> {
  late final _PartyRepository _repository;

  @override
  _PartyFeedState build(_FeedSortTab arg) {
    _repository = ref.read(_partyRepositoryProvider);
    Future.microtask(refresh);
    return _PartyFeedState(sortTab: arg);
  }

  Future<void> refresh() async {
    if (state.isRefreshing && state.items.isNotEmpty) return;
    state = state.copyWith(
      isLoading: state.items.isEmpty,
      isRefreshing: state.items.isNotEmpty,
      error: null,
    );
    try {
      final items = await _repository.fetchPartyList(
        type: state.sortTab.partyType,
        pageNum: 1,
      );
      state = state.copyWith(
        items: items,
        pageNum: 1,
        hasMore: items.length >= _partyListPageSize,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.items.isEmpty) {
      return;
    }

    final nextPage = state.pageNum + 1;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final nextItems = await _repository.fetchPartyList(
        type: state.sortTab.partyType,
        pageNum: nextPage,
      );
      final merged = _appendUnique(state.items, nextItems);
      state = state.copyWith(
        items: merged,
        pageNum: nextPage,
        hasMore:
            nextItems.length >= _partyListPageSize &&
            merged.length > state.items.length,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  List<_PartyFeedItem> _appendUnique(
    List<_PartyFeedItem> current,
    List<_PartyFeedItem> next,
  ) {
    final seenKeys = current.map(_itemKey).toSet();
    final merged = current.toList(growable: true);
    for (final item in next) {
      final key = _itemKey(item);
      if (seenKeys.add(key)) {
        merged.add(item);
      }
    }
    return merged;
  }

  String _itemKey(_PartyFeedItem item) {
    final partyId = item.partyId;
    if (partyId != null) return 'party:$partyId';
    final roomId = item.roomId;
    if (roomId != null && roomId.isNotEmpty) return 'room:$roomId';
    return '${item.title}|${item.hostName}|${item.coverUrl}|${item.avatarUrl}';
  }
}
