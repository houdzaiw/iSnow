import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../model/room_socket_message.dart';
import 'room_interaction_view_model.dart';
import 'room_rocket.dart';

final roomRocketProvider = StateNotifierProvider.autoDispose
    .family<RoomRocketViewModel, RoomRocket?, RoomInteractionKey>(
      (ref, key) =>
          RoomRocketViewModel(ref.watch(roomInteractionProvider(key).notifier)),
    );

class RoomRocketViewModel extends StateNotifier<RoomRocket?> {
  RoomRocketViewModel(this.session) : super(null) {
    _events = session.room.socketMessages.listen(receive);
    Future.microtask(load);
  }

  final RoomInteractionViewModel session;
  StreamSubscription<RoomSocketMessage>? _events;
  RoomRocket? _latest;
  String? _country;
  bool _loadedCountry = false;
  int _revision = 0;

  bool get active => mounted && session.active;

  Future<void> load() async {
    if (!active) return;
    final roomId = session.key.roomId;
    final revision = _revision;
    try {
      final user = await session.room.currentUser();
      if (!active) return;
      _country = user?.countryCode;
      _loadedCountry = true;
      _render();
      final data = await session.room.activeRocket(roomId);
      if (!active || data?.roomId != roomId) return;
      _latest = revision == _revision ? data : _latest?.withLinksFrom(data);
      _render();
    } catch (_) {
      // No configured activity means no pendant. Later socket state can enable it.
    }
  }

  void receive(RoomSocketMessage message) {
    if (!active || message.event != 'RoomBigRocketStatusEvent') return;
    final roomId = session.key.roomId;
    if (!{
      'global',
      'global_lobby',
      'room:$roomId',
      'room',
    }.contains(message.channel)) {
      return;
    }
    final data = RoomRocket.parse(message.payload);
    if (data == null || data.roomId != roomId) return;
    _revision++;
    _latest = data.withLinksFrom(_latest);
    _render();
  }

  void _render() {
    if (!active || !_loadedCountry) return;
    state = _latest?.visibleFor(_country) == true ? _latest : null;
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    super.dispose();
  }
}
