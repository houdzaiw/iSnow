import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/country_info.dart';
import '../../../model/server_response.dart';
import 'account_binding_repository.dart';

class AccountBindingState {
  const AccountBindingState({
    this.accounts = const [],
    this.countries = const [],
    this.loading = true,
    this.busy = false,
    this.verifiedOld = false,
    this.area = '966',
    this.phone = '',
    this.code = '',
    this.password = '',
    this.seconds = 0,
    this.error,
  });
  final List<BoundAccount> accounts;
  final List<CountryInfo> countries;
  final bool loading, busy, verifiedOld;
  final String area, phone, code, password;
  final int seconds;
  final Object? error;
  BoundAccount? get boundPhone =>
      accounts.where((a) => a.type == 5 && a.bound).firstOrNull;
  bool get verifyOld => boundPhone != null && !verifiedOld;
  AccountBindingState copy({
    List<BoundAccount>? accounts,
    List<CountryInfo>? countries,
    bool? loading,
    bool? busy,
    bool? verifiedOld,
    String? area,
    String? phone,
    String? code,
    String? password,
    int? seconds,
    Object? error,
  }) => AccountBindingState(
    accounts: accounts ?? this.accounts,
    countries: countries ?? this.countries,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    verifiedOld: verifiedOld ?? this.verifiedOld,
    area: area ?? this.area,
    phone: phone ?? this.phone,
    code: code ?? this.code,
    password: password ?? this.password,
    seconds: seconds ?? this.seconds,
    error: error,
  );
}

final accountBindingProvider =
    StateNotifierProvider.autoDispose<
      AccountBindingViewModel,
      AccountBindingState
    >(
      (ref) =>
          AccountBindingViewModel(ref.watch(accountBindingRepositoryProvider)),
    );

class AccountBindingViewModel extends StateNotifier<AccountBindingState> {
  AccountBindingViewModel(this.repo) : super(const AccountBindingState()) {
    Future.microtask(() {
      if (_alive) load();
    });
  }
  final AccountBindingRepository repo;
  bool _alive = true;
  Timer? _timer;
  ({String phone, String area, bool old})? _sent;
  @override
  void dispose() {
    _alive = false;
    _timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (!_alive || state.busy) return;
    state = state.copy(loading: true);
    try {
      final accounts = await repo.accounts();
      List<CountryInfo> countries;
      try {
        countries = await repo.countries();
      } catch (_) {
        countries = CountryInfo.fallbackList;
      }
      if (!_alive) return;
      final old = accounts.where((a) => a.type == 5 && a.bound).firstOrNull;
      _sent = null;
      state = AccountBindingState(
        accounts: accounts,
        countries: countries,
        loading: false,
        area: old?.area.isNotEmpty == true ? old!.area : state.area,
        phone: old?.account ?? '',
      );
    } catch (e) {
      if (_alive) state = state.copy(loading: false, error: e);
    }
  }

  void edit({String? phone, String? area, String? code, String? password}) {
    if (state.busy || state.loading) return;
    if ((phone != null || area != null) && state.verifyOld) return;
    if (phone != null || area != null) _sent = null;
    state = state.copy(
      phone: phone,
      area: area,
      code: phone != null || area != null ? '' : code,
      password: password,
    );
  }

  bool get validPhone =>
      RegExp(r'^\d{1,4}$').hasMatch(state.area) &&
      RegExp(r'^\d{5,16}$').hasMatch(state.phone);
  Future<void> send({int type = 1}) async {
    if (!_alive || state.loading || state.busy || state.seconds > 0) return;
    if (!validPhone) {
      throw const NadyApiException(message: 'Enter a valid phone number');
    }
    final snapshot = (
      phone: state.phone,
      area: state.area,
      old: state.verifyOld,
    );
    state = state.copy(busy: true);
    try {
      await repo.send(
        snapshot.phone,
        snapshot.area,
        verifyOld: snapshot.old,
        type: type,
        isCurrent: () => _alive,
      );
      if (!_alive) return;
      _sent = snapshot;
      state = state.copy(seconds: 120);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_alive) {
          timer.cancel();
          return;
        }
        final remaining = state.seconds - 1;
        state = state.copy(seconds: remaining < 0 ? 0 : remaining);
        if (remaining <= 0) timer.cancel();
      });
    } finally {
      if (_alive) state = state.copy(busy: false);
    }
  }

  Future<bool?> submit() async {
    if (!_alive || state.loading || state.busy) return null;
    final snapshot = (
      phone: state.phone,
      area: state.area,
      old: state.verifyOld,
    );
    if (!validPhone ||
        _sent != snapshot ||
        !RegExp(r'^\d{4,8}$').hasMatch(state.code)) {
      throw const NadyApiException(
        message: 'Request a code for this phone number first',
      );
    }
    final password = state.password, code = state.code;
    if (!state.verifyOld && state.boundPhone == null && password.length < 6) {
      throw const NadyApiException(
        message: 'Password must contain at least 6 characters',
      );
    }
    state = state.copy(busy: true);
    try {
      if (snapshot.old) {
        await repo.verify(
          snapshot.phone,
          snapshot.area,
          code,
          isCurrent: () => _alive,
        );
        if (!_alive) return null;
        _timer?.cancel();
        _sent = null;
        state = state.copy(verifiedOld: true, phone: '', code: '', seconds: 0);
        return null;
      }
      final result = await repo.bind(
        snapshot.phone,
        snapshot.area,
        code,
        password,
        needsPassword: state.boundPhone == null,
        isCurrent: () => _alive,
      );
      if (!_alive) return null;
      return result;
    } finally {
      if (_alive) state = state.copy(busy: false);
    }
  }
}
