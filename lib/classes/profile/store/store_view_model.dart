import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/user_profile.dart';
import '../../wallet/wallet_models.dart';
import 'store_models.dart';
import 'store_repository.dart';

const _unchanged = Object();

class StoreBoard {
  const StoreBoard({
    this.items = const [],
    this.page = 0,
    this.loading = false,
    this.more = true,
    this.error,
    this.selectedId,
    this.priceIndex = 0,
    this.failedMore = false,
  });
  final List<StoreProduct> items;
  final int page, priceIndex;
  final bool loading, more, failedMore;
  final Object? error;
  final int? selectedId;
  StoreProduct? get selected =>
      items.where((p) => p.id == selectedId).firstOrNull;
  StoreBoard copy({
    List<StoreProduct>? items,
    int? page,
    bool? loading,
    bool? more,
    Object? error = _unchanged,
    bool? failedMore,
    int? selectedId,
    int? priceIndex,
  }) => StoreBoard(
    items: items ?? this.items,
    page: page ?? this.page,
    loading: loading ?? this.loading,
    more: more ?? this.more,
    error: identical(error, _unchanged) ? this.error : error,
    failedMore: failedMore ?? this.failedMore,
    selectedId: selectedId ?? this.selectedId,
    priceIndex: priceIndex ?? this.priceIndex,
  );
}

class StoreState {
  const StoreState({
    this.category = StoreCategory.avatar,
    this.boards = const {},
    this.busy = false,
    this.purse,
    this.newTypes = const {},
    this.balanceError,
  });
  final StoreCategory category;
  final Map<StoreCategory, StoreBoard> boards;
  final bool busy;
  final WalletPurse? purse;
  final Object? balanceError;
  final Set<int> newTypes;
  StoreBoard get board => boards[category] ?? const StoreBoard();
  StoreState copy({
    StoreCategory? category,
    Map<StoreCategory, StoreBoard>? boards,
    bool? busy,
    WalletPurse? purse,
    Set<int>? newTypes,
    Object? balanceError = _unchanged,
  }) => StoreState(
    category: category ?? this.category,
    boards: boards ?? this.boards,
    busy: busy ?? this.busy,
    purse: purse ?? this.purse,
    newTypes: newTypes ?? this.newTypes,
    balanceError: identical(balanceError, _unchanged)
        ? this.balanceError
        : balanceError,
  );
}

final storeViewModelProvider =
    StateNotifierProvider.autoDispose<StoreViewModel, StoreState>(
      (ref) => StoreViewModel(ref.watch(storeRepositoryProvider)),
    );

class StoreViewModel extends StateNotifier<StoreState> {
  StoreViewModel(this.repo) : super(const StoreState()) {
    Future.microtask(() {
      if (_alive) {
        load(StoreCategory.avatar);
        refreshBalance();
        refreshNew();
      }
    });
  }
  bool _alive = true;
  final _revision = <StoreCategory, int>{};
  final StoreRepository repo;
  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  void _board(StoreCategory c, StoreBoard b) {
    if (_alive) state = state.copy(boards: {...state.boards, c: b});
  }

  void selectCategory(StoreCategory category) {
    if (state.busy) return;
    state = state.copy(category: category);
    if (!state.boards.containsKey(category)) load(category);
  }

  Future<void> load(StoreCategory category, {bool more = false}) async {
    final before = state.boards[category] ?? const StoreBoard();
    if (before.loading || more && !before.more) return;
    final revision = (_revision[category] ?? 0) + 1;
    _revision[category] = revision;
    _board(category, before.copy(loading: true, error: null));
    try {
      final page = more ? before.page + 1 : 1;
      final data = await repo.products(category, page);
      if (!_alive || _revision[category] != revision) return;
      final items = <int, StoreProduct>{
        if (more)
          for (final p in before.items) p.id: p,
        for (final p in data.items) p.id: p,
      }.values.toList();
      final selected = items.any((p) => p.id == before.selectedId)
          ? before.selectedId
          : items.firstOrNull?.id;
      _board(
        category,
        before.copy(
          items: items,
          page: page,
          loading: false,
          more: data.hasMore,
          selectedId: selected,
          priceIndex: 0,
          error: null,
        ),
      );
    } catch (e) {
      if (_alive && _revision[category] == revision) {
        _board(category, before.copy(error: e, failedMore: more));
      }
    }
  }

  void selectProduct(int id) {
    if (state.busy || !state.board.items.any((p) => p.id == id)) return;
    _board(state.category, state.board.copy(selectedId: id, priceIndex: 0));
  }

  void selectPrice(int index) {
    if (state.busy ||
        index < 0 ||
        index >= (state.board.selected?.prices.length ?? 0)) {
      return;
    }
    _board(state.category, state.board.copy(priceIndex: index));
  }

  Future<void> refreshBalance() async {
    try {
      final value = await repo.purse();
      if (_alive) state = state.copy(purse: value, balanceError: null);
    } catch (e) {
      if (_alive) state = state.copy(balanceError: e);
    }
  }

  Future<void> refreshNew() async {
    try {
      final value = await repo.newProducts();
      if (_alive) state = state.copy(newTypes: value);
    } catch (_) {
      /* Missing new markers do not block the catalog. */
    }
  }

  Future<StoreOrder?> order({UserData? recipient}) async {
    if (state.busy) return null;
    final product = state.board.selected;
    final index = state.board.priceIndex;
    if (product == null || index >= product.prices.length) return null;
    final price = product.prices[index];
    final account = await repo.features.identity();
    if (!_alive) return null;
    return StoreOrder(
      account,
      product,
      price,
      targetUid: recipient?.uid,
      targetName: recipient?.nick ?? '',
    );
  }

  Future<bool?> submit(StoreOrder order) async {
    if (!_alive || state.busy) return null;
    state = state.copy(busy: true);
    try {
      final refreshed = await repo.purchase(order, isCurrent: () => _alive);
      if (!_alive) return null;
      await refreshBalance();
      return _alive ? refreshed : null;
    } finally {
      if (_alive) state = state.copy(busy: false);
    }
  }
}
