import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';

class HomeListState<T> {
  const HomeListState({
    this.items = const [],
    this.loading = true,
    this.refreshing = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.error,
    this.errorPage,
  });
  final List<T> items;
  final bool loading, refreshing, loadingMore, hasMore;
  final int page;
  final int? errorPage;
  final String? error;
}

/// Shared request coalescing and generation protection for read-only home lists.
class HomeListViewModel<T> extends StateNotifier<HomeListState<T>> {
  HomeListViewModel(this._fetch, {this.paginated = false, this.itemKey})
    : super(HomeListState<T>()) {
    Future.microtask(refresh);
  }
  final Future<List<T>> Function(int page) _fetch;
  final bool paginated;
  final String Function(T)? itemKey;
  Future<void>? _refresh;
  int _request = 0;

  Future<void> refresh() => _refresh ??= _refreshNow().whenComplete(() {
    _refresh = null;
  });

  Future<void> _refreshNow() async {
    if (!mounted) return;
    final request = ++_request;
    final previous = state;
    state = HomeListState(
      items: previous.items,
      loading: previous.items.isEmpty,
      refreshing: previous.items.isNotEmpty,
      page: previous.page,
      hasMore: previous.hasMore,
    );
    try {
      final items = await _fetch(1);
      if (!mounted || request != _request) return;
      state = HomeListState(
        items: _merge([], items),
        loading: false,
        page: 1,
        hasMore: paginated && items.length >= 20,
      );
    } catch (error) {
      if (!mounted || request != _request) return;
      state = HomeListState(
        items: previous.items,
        loading: false,
        page: previous.page,
        hasMore: previous.hasMore,
        error: userFacingErrorMessage(error),
        errorPage: 1,
      );
    }
  }

  Future<void> loadMore() async {
    if (!mounted ||
        !paginated ||
        state.loading ||
        state.refreshing ||
        state.loadingMore ||
        !state.hasMore) {
      return;
    }
    final request = ++_request;
    final previous = state;
    state = HomeListState(
      items: previous.items,
      loading: false,
      loadingMore: true,
      page: previous.page,
      hasMore: true,
    );
    try {
      final items = await _fetch(previous.page + 1);
      if (!mounted || request != _request) return;
      final merged = _merge(previous.items, items);
      state = HomeListState(
        items: merged,
        loading: false,
        page: previous.page + 1,
        hasMore: items.length >= 20 && merged.length > previous.items.length,
      );
    } catch (error) {
      if (!mounted || request != _request) return;
      state = HomeListState(
        items: previous.items,
        loading: false,
        page: previous.page,
        hasMore: true,
        error: userFacingErrorMessage(error),
        errorPage: previous.page + 1,
      );
    }
  }

  List<T> _merge(List<T> current, List<T> next) {
    final key = itemKey;
    if (key == null) return [...current, ...next];
    final seen = current.map(key).toSet();
    return [...current, ...next.where((item) => seen.add(key(item)))];
  }
}
