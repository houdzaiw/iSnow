import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'membership_models.dart';
import 'membership_repository.dart';
import 'membership_session.dart';
import 'membership_state.dart';
import 'membership_view_model.dart';

class MembershipAuxState {
  const MembershipAuxState({
    this.settings,
    this.rewards,
    this.titles,
    this.records = const {},
    this.pages = const {},
    this.totals = const {},
    this.loading = const {},
    this.errors = const {},
    this.saving = const {},
  });
  final List<VipSettingItem>? settings;
  final List<NobleReward>? rewards;
  final List<NobleTitle>? titles;
  final Map<MembershipKind, List<MembershipRecord>> records;
  final Map<MembershipKind, int> pages, totals;
  final Set<String> loading, saving;
  final Map<String, Object> errors;
  MembershipAuxState copyWith({
    List<VipSettingItem>? settings,
    List<NobleReward>? rewards,
    List<NobleTitle>? titles,
    Map<MembershipKind, List<MembershipRecord>>? records,
    Map<MembershipKind, int>? pages,
    Map<MembershipKind, int>? totals,
    Set<String>? loading,
    Set<String>? saving,
    Map<String, Object>? errors,
  }) => MembershipAuxState(
    settings: settings ?? this.settings,
    rewards: rewards ?? this.rewards,
    titles: titles ?? this.titles,
    records: records ?? this.records,
    pages: pages ?? this.pages,
    totals: totals ?? this.totals,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    errors: errors ?? this.errors,
  );
}

final membershipAuxProvider =
    StateNotifierProvider<MembershipAuxViewModel, MembershipAuxState>((ref) {
      final model = MembershipAuxViewModel(
        ref.watch(membershipRepositoryProvider),
      );
      ref.listen(membershipRevisionProvider, (_, _) => model.refreshLoaded());
      return model;
    });

class MembershipAuxViewModel extends StateNotifier<MembershipAuxState> {
  MembershipAuxViewModel(this.repository) : super(const MembershipAuxState());
  final MembershipRepository repository;
  int _epoch = 0;
  bool get alive => mounted;
  Future<void> refreshLoaded() async {
    final tasks = <Future<void>>[
      if (state.settings != null) load('settings', force: true),
      if (state.rewards != null) load('rewards', force: true),
      if (state.titles != null) load('titles', force: true),
      for (final kind in state.records.keys) history(kind, refresh: true),
    ];
    await Future.wait(tasks);
  }

  Future<void> load(String key, {bool force = false}) async {
    if (key == 'settings' && state.saving.any((s) => s.startsWith('setting:'))) {
      return;
    }
    if (!alive || state.loading.contains(key)) return;
    if (!force &&
        ((key == 'settings' && state.settings != null) ||
            (key == 'rewards' && state.rewards != null) ||
            (key == 'titles' && state.titles != null))) {
      return;
    }
    final epoch = _epoch;
    state = state.copyWith(
      loading: {...state.loading, key},
      errors: {...state.errors}..remove(key),
    );
    try {
      switch (key) {
        case 'settings':
          final result = await repository.settings();
          if (alive && epoch == _epoch) {
            state = state.copyWith(settings: result);
          }
        case 'rewards':
          final result = await repository.rewards(force: force);
          if (alive && epoch == _epoch) state = state.copyWith(rewards: result);
        case 'titles':
          final result = await repository.titles(force: force);
          if (alive && epoch == _epoch) state = state.copyWith(titles: result);
      }
    } catch (e) {
      if (alive && epoch == _epoch) {
        state = state.copyWith(errors: {...state.errors, key: e});
      }
    } finally {
      if (alive && epoch == _epoch) {
        state = state.copyWith(loading: {...state.loading}..remove(key));
      }
    }
  }

  Future<bool> saveSetting(
    VipSettingItem setting,
    bool value,
    int vipLevel,
  ) async {
    final key = 'setting:${setting.id}';
    if (!alive || state.saving.contains(key) || vipLevel < setting.limit) {
      return false;
    }
    state = state.copyWith(
      saving: {...state.saving, key},
      errors: {...state.errors}..remove(key),
    );
    try {
      await repository.setSetting(setting.id, value);
      if (!alive) return false;
      state = state.copyWith(
        settings: state.settings
            ?.map(
              (item) => item.id == setting.id
                  ? VipSettingItem(
                      id: item.id,
                      name: item.name,
                      limit: item.limit,
                      open: value,
                      type: item.type,
                    )
                  : item,
            )
            .toList(),
      );
      return true;
    } catch (e) {
      if (alive) state = state.copyWith(errors: {...state.errors, key: e});
      return false;
    } finally {
      if (alive) state = state.copyWith(saving: {...state.saving}..remove(key));
    }
  }

  bool hasMore(MembershipKind kind) =>
      (state.records[kind]?.length ?? 0) < (state.totals[kind] ?? 1);
  Future<void> history(MembershipKind kind, {bool refresh = false}) async {
    final key = 'history:${kind.name}';
    if (!alive || state.loading.contains(key) || (!refresh && !hasMore(kind))) {
      return;
    }
    final page = refresh ? 1 : (state.pages[kind] ?? 0) + 1;
    state = state.copyWith(
      loading: {...state.loading, key},
      errors: {...state.errors}..remove(key),
    );
    try {
      final result = await repository.history(kind, page);
      if (!alive) return;
      final items = <String, MembershipRecord>{
        if (!refresh)
          for (final item in state.records[kind] ?? <MembershipRecord>[])
            item.key: item,
        for (final item in result.items) item.key: item,
      }.values.toList(growable: false);
      state = state.copyWith(
        records: {...state.records, kind: items},
        pages: {...state.pages, kind: page},
        totals: {
          ...state.totals,
          kind: result.items.isEmpty ? items.length : result.total,
        },
      );
    } catch (e) {
      if (alive) state = state.copyWith(errors: {...state.errors, key: e});
    } finally {
      if (alive) {
        state = state.copyWith(loading: {...state.loading}..remove(key));
      }
    }
  }

  Future<MembershipSubmitResult> claim(
    NobleTitle title, {
    required int nobleLevel,
    required MembershipIdentity account,
  }) async {
    const key = 'claim';
    if (!alive || state.saving.contains(key)) {
      return MembershipSubmitResult.stale;
    }
    if (title.owner != null || nobleLevel < 6) {
      state = state.copyWith(
        errors: {
          ...state.errors,
          key: const MembershipFailure('membership.titleUnavailable'),
        },
      );
      return MembershipSubmitResult.failed;
    }
    state = state.copyWith(
      saving: {...state.saving, key},
      errors: {...state.errors}..remove(key),
    );
    try {
      await repository.claimTitle(title.id, account);
    } catch (e) {
      if (alive) {
        state = state.copyWith(
          errors: {...state.errors, key: e},
          saving: {...state.saving}..remove(key),
        );
      }
      return alive
          ? MembershipSubmitResult.failed
          : MembershipSubmitResult.stale;
    }
    if (!alive) return MembershipSubmitResult.stale;
    bool refreshFailed = false;
    try {
      await repository.syncAccount(account);
    } catch (_) {
      refreshFailed = true;
    }
    if (!alive) return MembershipSubmitResult.stale;
    await load('titles', force: true);
    if (!alive) return MembershipSubmitResult.stale;
    state = state.copyWith(saving: {...state.saving}..remove(key));
    return refreshFailed || state.errors.containsKey('titles')
        ? MembershipSubmitResult.refreshFailed
        : MembershipSubmitResult.success;
  }

  @override
  void dispose() {
    _epoch++;
    super.dispose();
  }
}

class MembershipRecipientState {
  const MembershipRecipientState({
    this.keyword = '',
    this.user,
    this.loading = false,
    this.error,
  });
  final String keyword;
  final MembershipRecipient? user;
  final bool loading;
  final Object? error;
}

final membershipRecipientProvider = StateNotifierProvider.autoDispose
    .family<
      MembershipRecipientViewModel,
      MembershipRecipientState,
      MembershipAction
    >(
      (ref, action) => MembershipRecipientViewModel(
        ref.watch(membershipRepositoryProvider),
        action,
      ),
    );

class MembershipRecipientViewModel
    extends StateNotifier<MembershipRecipientState> {
  MembershipRecipientViewModel(this.repository, this.action)
    : super(const MembershipRecipientState());
  final MembershipRepository repository;
  final MembershipAction action;
  int _revision = 0;
  void changed(String value) {
    _revision++;
    state = MembershipRecipientState(keyword: value);
  }

  Future<void> search() async {
    final number = int.tryParse(state.keyword.trim());
    final revision = ++_revision;
    if (number == null || number <= 0) {
      state = MembershipRecipientState(
        keyword: state.keyword,
        error: const MembershipFailure('membership.invalidId'),
      );
      return;
    }
    state = MembershipRecipientState(keyword: state.keyword, loading: true);
    try {
      final user = await repository.recipient(
        number,
        unblock: action == MembershipAction.unblock,
      );
      if (!mounted || revision != _revision) return;
      if (user.user.uid == null || user.user.uid! <= 0) {
        throw const MembershipFailure('membership.userNotFound');
      }
      if (action != MembershipAction.unblock &&
          (!user.normal || user.blocked)) {
        throw const MembershipFailure('membership.invalidRecipient');
      }
      if (action == MembershipAction.experienceCard &&
          (user.user.userLevel?.vipLevel ?? 0) > 0) {
        throw const MembershipFailure('membership.experienceUnavailable');
      }
      state = MembershipRecipientState(keyword: state.keyword, user: user);
    } catch (e) {
      if (mounted && revision == _revision) {
        state = MembershipRecipientState(keyword: state.keyword, error: e);
      }
    }
  }

  @override
  void dispose() {
    _revision++;
    super.dispose();
  }
}
