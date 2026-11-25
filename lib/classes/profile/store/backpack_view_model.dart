import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'store_models.dart';
import 'store_repository.dart';
import '../tools/profile_feature_repository.dart';

class PropBoard {
  const PropBoard({
    this.items = const [],
    this.selectedId,
    this.page = 0,
    this.loading = false,
    this.busy = false,
    this.more = true,
    this.error,
  });
  final List<OwnedProp> items;
  final int? selectedId;
  final int page;
  final bool loading, busy, more;
  final Object? error;
  OwnedProp? get selected => items.where((p) => p.id == selectedId).firstOrNull;
  PropBoard copy({
    List<OwnedProp>? items,
    int? selectedId,
    int? page,
    bool? loading,
    bool? busy,
    bool? more,
    Object? error,
  }) => PropBoard(
    items: items ?? this.items,
    selectedId: selectedId ?? this.selectedId,
    page: page ?? this.page,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    more: more ?? this.more,
    error: error,
  );
}

final backpackProvider = StateNotifierProvider.autoDispose
    .family<BackpackViewModel, PropBoard, StoreCategory>(
      (ref, category) =>
          BackpackViewModel(ref.watch(storeRepositoryProvider), category),
    );

class BackpackViewModel extends StateNotifier<PropBoard> {
  BackpackViewModel(this.repo, this.category) : super(const PropBoard()) {
    Future.microtask(() {
      if (_alive) load();
    });
  }
  final StoreRepository repo;
  final StoreCategory category;
  bool _alive = true;
  MembershipIdentity? _loadedAccount;
  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }

  void select(int id) {
    if (!state.busy) state = state.copy(selectedId: id);
  }

  Future<void> load({bool more = false}) async {
    if (!_alive || state.loading || more && !state.more) return;
    final old = state;
    state = state.copy(loading: true);
    try {
      final account = await repo.features.identity();
      final page = more ? old.page + 1 : 1;
      final items = await repo.props(category, page);
      if (!_alive) return;
      await repo.features.check(account);
      if (!_alive) return;
      _loadedAccount = account;
      final merged = <int, OwnedProp>{
        if (more)
          for (final item in old.items) item.id: item,
        for (final item in items) item.id: item,
      }.values.toList();
      state = PropBoard(
        items: merged,
        page: page,
        more: items.isNotEmpty,
        busy: old.busy,
        selectedId: merged.any((p) => p.id == old.selectedId)
            ? old.selectedId
            : merged.firstOrNull?.id,
      );
    } catch (e) {
      if (_alive) state = old.copy(error: e);
    }
  }

  Future<bool?> use() async {
    final prop = state.selected;
    if (!_alive || state.busy || prop == null) return null;
    state = state.copy(busy: true);
    try {
      final result = await repo.use(
        prop,
        enable: prop.state != 2,
        isCurrent: () => _alive,
      );
      if (!_alive) return null;
      await load();
      return _alive ? result && state.error == null : null;
    } finally {
      if (_alive) state = state.copy(busy: false);
    }
  }

  Future<bool> beginTransfer() async {
    if (!_alive ||
        state.busy ||
        state.loading ||
        state.selected == null ||
        _loadedAccount == null) {
      return false;
    }
    state = state.copy(busy: true);
    try {
      await repo.features.check(_loadedAccount!);
      return _alive;
    } catch (_) {
      endTransfer();
      rethrow;
    }
  }

  void endTransfer() {
    if (_alive) state = state.copy(busy: false);
  }

  Future<PropTransfer> prepareTransfer(int targetUid) =>
      repo.prepareTransfer(state.selected!, targetUid, _loadedAccount!);
  Future<bool?> transfer(PropTransfer order) async {
    if (!_alive || !state.busy || order.prop.id != state.selectedId) {
      return null;
    }
    final result = await repo.transfer(order, () => _alive);
    if (!_alive) return null;
    await load();
    return _alive ? result && state.error == null : null;
  }
}
