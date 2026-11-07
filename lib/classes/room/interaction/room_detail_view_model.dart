import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import 'room_interaction_repository.dart';
import 'room_interaction_view_model.dart';
import 'room_management_repository.dart';

final roomAdminCountProvider = FutureProvider.autoDispose
    .family<int, RoomInteractionKey>((ref, key) async {
      final session = ref.watch(roomInteractionProvider(key).notifier);
      if (!ref.watch(roomInteractionProvider(key))) {
        throw StateError('Room session is no longer active');
      }
      return (await session.api.members(
        key.roomId,
        RoomManagementList.admins,
      )).length;
    });

typedef RoomPartyKey = ({RoomInteractionKey session, bool history});

final roomLinkedPartiesProvider = StateNotifierProvider.autoDispose
    .family<RoomLinkedPartiesViewModel, RoomLinkedPartiesState, RoomPartyKey>(
      (ref, key) => RoomLinkedPartiesViewModel(
        ref.watch(roomInteractionProvider(key.session).notifier),
        key.history,
      ),
    );

class RoomLinkedPartiesState {
  const RoomLinkedPartiesState({
    this.items = const [],
    this.loading = false,
    this.more = true,
    this.error,
  });
  final List<RoomLinkedParty> items;
  final bool loading, more;
  final String? error;
}

class RoomLinkedPartiesViewModel extends StateNotifier<RoomLinkedPartiesState> {
  RoomLinkedPartiesViewModel(this.session, this.history)
    : super(const RoomLinkedPartiesState(loading: true)) {
    Future.microtask(load);
  }
  final RoomInteractionViewModel session;
  final bool history;
  int _page = 0;
  bool _pending = false;

  Future<void> load({bool refresh = false}) async {
    if (!mounted || !session.active || _pending || (!refresh && !state.more)) {
      return;
    }
    _pending = true;
    final previous = state;
    final page = refresh ? 1 : _page + 1;
    state = RoomLinkedPartiesState(items: previous.items, loading: true);
    try {
      final result = await session.api.parties(
        session.key.roomId,
        history: history,
        page: page,
      );
      if (!mounted || !session.active) return;
      final unique = <int, RoomLinkedParty>{
        if (page > 1)
          for (final item in previous.items) item.id: item,
        for (final item in result) item.id: item,
      };
      _page = page;
      state = RoomLinkedPartiesState(
        items: List.unmodifiable(unique.values),
        more:
            result.isNotEmpty &&
            unique.length > (page == 1 ? 0 : previous.items.length),
      );
    } catch (error) {
      if (mounted && session.active) {
        state = RoomLinkedPartiesState(
          items: previous.items,
          more: previous.more,
          error: userFacingErrorMessage(error),
        );
      }
    } finally {
      _pending = false;
    }
  }
}

typedef RoomPartyDetailsKey = ({RoomInteractionKey session, int id});

final roomPartyDetailsProvider = StateNotifierProvider.autoDispose
    .family<
      RoomPartyDetailsViewModel,
      RoomPartyDetailsState,
      RoomPartyDetailsKey
    >(
      (ref, key) => RoomPartyDetailsViewModel(
        ref.watch(roomInteractionProvider(key.session).notifier),
        key.id,
      ),
    );

class RoomPartyDetailsState {
  const RoomPartyDetailsState({
    this.item,
    this.busy = true,
    this.error,
    this.actor,
  });
  final RoomLinkedParty? item;
  final bool busy;
  final String? error;
  final int? actor;
}

class RoomPartyDetailsViewModel extends StateNotifier<RoomPartyDetailsState> {
  RoomPartyDetailsViewModel(this.session, this.id)
    : super(const RoomPartyDetailsState()) {
    Future.microtask(load);
  }
  final RoomInteractionViewModel session;
  final int id;
  bool _pending = false, _closed = false;
  bool get active => mounted && !_closed && session.active;
  void close() => _closed = true;

  Future<void> load() => _run();

  Future<void> reminder() => _run(remind: true);

  Future<void> cancel() => _run(cancel: true);

  Future<void> _run({bool remind = false, bool cancel = false}) async {
    if (!active || _pending) return;
    _pending = true;
    final before = state;
    state = RoomPartyDetailsState(item: before.item, actor: before.actor);
    try {
      final actor = await session.room.currentUid();
      if (!active) return;
      var latest = await session.api.partyDetail(id);
      if (!active) return;
      if (actor != null && actor > 0 && latest.status == 2) {
        if (remind &&
            latest.ownerUid > 0 &&
            latest.ownerUid != actor &&
            latest.subscribed == before.item?.subscribed) {
          await session.api.partyReminder(id, !latest.subscribed);
        } else if (cancel && latest.ownerUid == actor) {
          await session.api.cancelParty(id);
        }
        if (remind || cancel) {
          if (!active) return;
          latest = await session.api.partyDetail(id);
          if (!active) return;
        }
      }
      state = RoomPartyDetailsState(item: latest, actor: actor, busy: false);
    } catch (error) {
      if (active) {
        state = RoomPartyDetailsState(
          item: before.item,
          actor: before.actor,
          busy: false,
          error: userFacingErrorMessage(error),
        );
      }
    } finally {
      _pending = false;
    }
  }
}
