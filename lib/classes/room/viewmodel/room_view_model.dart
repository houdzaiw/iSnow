import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/app_socket_manager.dart';
import '../../../manager/room_manager.dart';
import '../../../model/room_models.dart';
import '../../../model/room_socket_message.dart';
import '../room_repository.dart';
import '../gift/event/room_gift_event_manager.dart';
import '../gift/event/room_gift_event_parser.dart';
import '../gift/event/room_gift_event_provider.dart';
import '../gift/event/room_gift_room_id_provider.dart';
import '../gift/models/room_gift_event_models.dart';
import 'room_state.dart';

export '../room_repository.dart' show roomRepositoryProvider;

final roomViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomViewModel, RoomPageState, String>((ref, roomId) {
      final model = RoomViewModel(
        repository: ref.read(roomRepositoryProvider),
        roomId: roomId,
      );
      ProviderSubscription<RoomGiftEventManager>? gifts;
      ref.listen(roomGiftRoomIdProvider(roomId), (_, id) {
        gifts?.close();
        gifts = ref.listen(
          roomGiftEventManagerProvider(id).notifier,
          (_, manager) => model.bindGiftManager(manager),
          fireImmediately: true,
        );
      }, fireImmediately: true);
      ref.onDispose(() => gifts?.close());
      return model;
    });

class RoomViewModel extends StateNotifier<RoomPageState> {
  RoomViewModel({
    required RoomRepository repository,
    required String roomId,
    RoomGiftEventManager? giftManager,
  }) : _repository = repository,
       _giftManager = giftManager,
       _roomId = roomId,
       super(RoomPageState.initial(roomId)) {
    _repository.addListener(_syncFromManager);
    _socketSubscription = _repository.socketMessages.listen(
      _handleSocketMessage,
    );
    unawaited(_loadCurrentUser());
    _syncFromManager();
    _removeGiftListener = _giftManager?.addListener(_syncGiftState);
  }

  final RoomRepository _repository;
  RoomGiftEventManager? _giftManager;
  VoidCallback? _removeGiftListener;
  final String _roomId;
  late final StreamSubscription<RoomSocketMessage> _socketSubscription;
  bool _entering = false;
  bool _leaving = false;
  String? _sessionRoomId;
  Map<String, RoomGiftPublicMessage> _giftMessages = const {};

  /// Bind to the server's canonical room ID after entering, not the route alias.
  void bindGiftManager(RoomGiftEventManager manager) {
    if (!mounted || identical(_giftManager, manager)) return;
    _removeGiftListener?.call();
    _giftManager = manager;
    _giftMessages = const {};
    _removeGiftListener = manager.addListener(_syncGiftState);
  }

  Future<void> enterRoom({String roomPassword = '', int followUid = 0}) async {
    if (!mounted || _entering) return;
    final current = _repository.roomState;
    if (current.status == RoomStatus.ready &&
        current.isInRoom &&
        current.currentRoomId == _roomId) {
      _syncFromManager();
      return;
    }
    _entering = true;
    _giftMessages = const {};
    state = RoomPageState.initial(_roomId).copyWith(
      currentUid: state.currentUid,
      currentUserName: state.currentUserName,
      currentUserAvatar: state.currentUserAvatar,
      status: RoomStatus.entering,
      errorMessage: null,
    );

    try {
      await _repository.enterRoom(
        roomId: _roomId,
        roomPassword: roomPassword,
        followUid: followUid,
      );
      if (!mounted) return;
      _sessionRoomId = _repository.roomState.currentRoomId;
      _syncFromManager();
      final gifts = _giftManager;
      if (gifts != null) _syncGiftState(gifts.snapshot);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        status: RoomStatus.error,
        isInRoom: false,
        errorMessage: error.toString(),
      );
    } finally {
      _entering = false;
    }
  }

  Future<void> refresh() async {
    if (!mounted || !state.isReady || _leaving) return;
    try {
      await _repository.refreshRoomData();
      _syncFromManager();
    } catch (error) {
      if (!mounted || !state.isReady) return;
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  bool minimizeRoom() {
    if (!mounted || _leaving || !state.isReady) return false;
    _repository.minimizeRoom();
    _syncFromManager();
    return _repository.roomState.isMinimized &&
        _repository.roomState.status == RoomStatus.ready;
  }

  void restoreRoom() {
    _repository.restoreRoom();
    _syncFromManager();
  }

  Future<void> exitMinimizedRoom() async {
    await _repository.exitMinimizedRoom();
    _syncFromManager();
  }

  Future<bool> leaveRoom() async {
    if (!mounted || _leaving) return false;
    _leaving = true;
    try {
      await _repository.leaveRoom();
      if (mounted) _syncFromManager();
      return !_repository.roomState.isInRoom;
    } catch (error) {
      // The server exit request may fail after local Agora/socket cleanup has
      // completed. Local room state is the source of truth for page teardown.
      if (!_repository.roomState.isInRoom) {
        if (mounted) _syncFromManager();
        return true;
      }
      if (mounted) {
        state = state.copyWith(errorMessage: error.toString());
      }
      return false;
    } finally {
      _leaving = false;
    }
  }

  void setChatFilter(RoomChatFilter filter) {
    state = state.copyWith(chatFilter: filter);
  }

  Future<void> sendMessage(String text) async {
    if (!mounted || !state.isReady || _leaving) return;
    final message = text.trim();
    if (message.isEmpty || state.sendingMessage) return;

    final roomId = _effectiveRoomId;
    final localEntry = RoomChatEntry(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      kind: RoomChatEntryKind.chat,
      text: message,
      createdAt: DateTime.now(),
      senderName: state.currentUserName,
      senderAvatar: state.currentUserAvatar,
      senderUid: state.currentUid,
      isLocal: true,
    );

    state = state.copyWith(
      sendingMessage: true,
      messages: _appendMessage(localEntry),
      errorMessage: null,
    );

    try {
      await _repository.sendTextMessage(roomId: roomId, text: message);
      if (!mounted || !state.isReady) return;
      state = state.copyWith(sendingMessage: false, errorMessage: null);
    } catch (error) {
      if (!mounted || !state.isReady) return;
      state = state.copyWith(
        sendingMessage: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> toggleSeat(RoomSeatViewData seat) async {
    if (seat.isOccupied && seat.uid == state.currentUid) {
      await downMic(seat.position);
      return;
    }
    if (!seat.isOccupied && !seat.isLocked) {
      await upMic(seat.position);
    }
  }

  Future<void> upMic(int position) {
    return _runSeatOperation(position, () async {
      await _repository.upMic(position);
    });
  }

  Future<void> downMic(int position) {
    return _runSeatOperation(position, () async {
      await _repository.downMic(position);
    });
  }

  Future<void> kickDownMic(RoomSeatViewData seat) {
    final targetUid = seat.uid;
    if (targetUid == null || targetUid == 0) return Future<void>.value();
    return _runSeatOperation(seat.position, () async {
      await _repository.kickDownMic(
        position: seat.position,
        targetUid: targetUid,
      );
    });
  }

  Future<void> setSeatMuted(RoomSeatViewData seat, bool mute) {
    return _runSeatOperation(seat.position, () async {
      await _repository.muteMicSeat(position: seat.position, mute: mute);
    });
  }

  Future<void> setSeatLocked(RoomSeatViewData seat, bool locked) {
    return _runSeatOperation(seat.position, () async {
      await _repository.lockMicSeat(position: seat.position, isLock: locked);
    });
  }

  Future<void> toggleLocalMicrophone() async {
    if (!mounted ||
        !state.isReady ||
        !state.isOnMic ||
        _leaving ||
        state.togglingMicrophone) {
      return;
    }
    final roomId = state.currentRoomId;
    state = state.copyWith(togglingMicrophone: true, errorMessage: null);
    try {
      await _repository.muteLocalMicrophone(!state.agoraState.mutedMicrophone);
      _syncFromManager();
    } catch (error) {
      if (!mounted ||
          _leaving ||
          !state.isReady ||
          state.currentRoomId != roomId) {
        return;
      }
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      if (mounted) state = state.copyWith(togglingMicrophone: false);
    }
  }

  Future<void> toggleSpeaker() async {
    if (!mounted || !state.isReady || _leaving) return;
    try {
      await _repository.muteSpeaker(!state.agoraState.mutedSpeaker);
      _syncFromManager();
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> _runSeatOperation(
    int position,
    Future<void> Function() operation,
  ) async {
    if (!mounted ||
        !state.isReady ||
        _leaving ||
        state.pendingSeatPosition != null) {
      return;
    }
    state = state.copyWith(pendingSeatPosition: position, errorMessage: null);
    try {
      await operation();
      _syncFromManager();
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      if (mounted) {
        state = state.copyWith(pendingSeatPosition: null);
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final uid = await _repository.currentUid();
    final user = await _repository.currentUser();
    if (!mounted) return;
    state = state.copyWith(
      currentUid: uid ?? user?.uid,
      currentUserName: _stringValue(user?.nick),
      currentUserAvatar: _stringValue(user?.avatar),
    );
  }

  void _syncFromManager() {
    if (!mounted) return;
    final roomState = _repository.roomState;
    if (_sessionRoomId == null) {
      if (roomState.currentRoomId != _roomId || !roomState.isInRoom) return;
      _sessionRoomId = roomState.currentRoomId;
    }
    // A new page must not mistake the old room's teardown for its own Exit.
    if (roomState.currentRoomId != null &&
        roomState.currentRoomId != _sessionRoomId) {
      return;
    }
    final socketState = _repository.socketState;
    final agoraState = _repository.agoraState;
    final roomInfo = roomState.roomInfo;
    final enterResponse = roomState.enterResponse;
    final roomData = _roomDataMap(roomInfo);
    final effectiveRoomId =
        _stringValue(roomState.currentRoomId) ??
        _stringValue(state.currentRoomId) ??
        _roomId;

    state = state.copyWith(
      currentRoomId: effectiveRoomId,
      status: roomState.status,
      isInRoom: roomState.isInRoom,
      isMinimized: roomState.isMinimized,
      roomTitle: _roomTitle(roomInfo, enterResponse),
      roomAvatar: _roomAvatar(roomInfo, roomData),
      roomNo: _roomNo(roomInfo, enterResponse, effectiveRoomId),
      roomDesc: _stringValue(roomInfo?.roomDesc ?? roomData['roomDesc']),
      onlineCount: _onlineCount(roomInfo, roomData),
      roomInfo: roomInfo,
      enterResponse: enterResponse,
      seats: _buildSeats(roomState.micList, agoraState.volumeLevels),
      socketStatus: socketState.status,
      socketReady:
          socketState.status == AppSocketStatus.ready &&
          socketState.roomChannelSubscribed,
      socketErrorMessage: socketState.errorMessage,
      agoraState: agoraState,
      errorMessage: roomState.errorMessage,
    );
  }

  List<RoomSeatViewData> _buildSeats(
    List<RoomMicModel> micList,
    Map<int, int> volumeLevels,
  ) {
    final byPosition = <int, RoomMicModel>{};
    final seatCount = _seatCountForMicList(micList);
    for (var index = 0; index < micList.length; index += 1) {
      final mic = micList[index];
      final position = _micPosition(mic, index);
      if (position >= 0 && position < seatCount) {
        byPosition[position] = mic;
      }
    }
    return List.generate(seatCount, (index) {
      final position = index;
      final mic = byPosition[position];
      if (mic == null) return RoomSeatViewData.empty(position);
      final uid = mic.uid;
      return RoomSeatViewData.fromMic(
        mic,
        position: position,
        volume: uid == null ? 0 : volumeLevels[uid] ?? 0,
      );
    });
  }

  int _seatCountForMicList(List<RoomMicModel> micList) {
    if (micList.isEmpty) return roomDefaultMicSeatCount;

    var maxPosition = -1;
    for (var index = 0; index < micList.length; index += 1) {
      final position = _micPosition(micList[index], index);
      if (position > maxPosition) maxPosition = position;
    }

    final inferredCount = maxPosition + 1 > micList.length
        ? maxPosition + 1
        : micList.length;
    if (inferredCount < roomDefaultMicSeatCount) return roomDefaultMicSeatCount;
    if (inferredCount > roomMaxMicSeatCount) return roomMaxMicSeatCount;
    return inferredCount;
  }

  int _micPosition(RoomMicModel mic, int index) {
    final position = mic.position;
    if (position >= 0 && position < roomMaxMicSeatCount) return position;
    return index;
  }

  void _handleSocketMessage(RoomSocketMessage message) {
    if (!mounted || !state.isReady) return;
    if (!_isCurrentRoomMessage(message)) return;
    if (RoomGiftEventParser.events.contains(message.event)) return;

    if (message.event == 'RoomScreenSystemClear') {
      _giftManager?.reset(clearHistory: true);
      state = state.copyWith(
        messages: [RoomChatEntry.system('Screen has been cleared.')],
      );
      return;
    }

    if (message.event == 'RoomMicUpdateEvent') {
      _syncFromManager();
      return;
    }

    if (message.event == 'RoomKickOutEvent') {
      final payload = _payloadMap(message.payload);
      final from = payload['from'];
      final targetUid = from is Map ? from['uid'] : payload['uid'];
      if (payload['roomId']?.toString() != _effectiveRoomId ||
          state.currentUid == null ||
          targetUid?.toString() != state.currentUid.toString()) {
        return;
      }
      state = state.copyWith(
        messages: _appendMessage(
          RoomChatEntry.system('You were removed from the room.'),
        ),
      );
      return;
    }

    final entry = _chatEntryFromSocket(message);
    if (entry == null) return;
    state = state.copyWith(messages: _appendMessage(entry));
  }

  void _syncGiftState(RoomGiftEventState gifts) {
    if (!mounted) return;
    final previous = _giftMessages;
    _giftMessages = {for (final gift in gifts.publicMessages) gift.key: gift};
    final entries = [...state.messages];
    var changed = false;
    for (final gift in gifts.publicMessages) {
      if (identical(previous[gift.key], gift)) continue;
      final id = 'gift-${gift.key}';
      final entry = RoomChatEntry(
        id: id,
        kind: RoomChatEntryKind.gift,
        text: gift.text,
        createdAt: gift.createdAt,
        senderName: gift.sender.name,
        senderAvatar: gift.sender.avatar,
        senderUid: gift.sender.uid,
        gift: gift,
      );
      final index = entries.indexWhere((entry) => entry.id == id);
      if (index >= 0) {
        entries[index] = entry;
        changed = true;
      } else if (!previous.containsKey(gift.key)) {
        entries.add(entry);
        changed = true;
      }
    }
    if (!changed && gifts.roomWeekVal == state.roomWeekVal) return;
    state = state.copyWith(
      roomWeekVal: gifts.roomWeekVal,
      messages: entries.length > 80
          ? entries.sublist(entries.length - 80)
          : entries,
    );
  }

  bool _isCurrentRoomMessage(RoomSocketMessage message) {
    final currentRoomId = _effectiveRoomId;
    return message.channel == 'room:$currentRoomId' ||
        message.channel == 'room';
  }

  RoomChatEntry? _chatEntryFromSocket(RoomSocketMessage message) {
    final kind = _kindForEvent(message.event);
    if (kind == null) return null;
    final payload = _payloadMap(message.payload);
    final user = _userMap(payload);
    final text = _messageText(payload, message.event);
    if (text == null || text.isEmpty) return null;
    return RoomChatEntry(
      id:
          message.msgId ??
          _stringValue(payload['msgID'] ?? payload['msgId']) ??
          'socket-${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      text: text,
      createdAt: _messageTime(message, payload),
      senderName: _stringValue(
        payload['nick'] ??
            payload['nickname'] ??
            payload['userName'] ??
            user['nick'] ??
            user['nickname'],
      ),
      senderAvatar: _stringValue(payload['avatar'] ?? user['avatar']),
      senderUid: _intValue(payload['uid'] ?? user['uid']),
    );
  }

  RoomChatEntryKind? _kindForEvent(String event) {
    return switch (event) {
      'RoomScreenMessageEvent' => RoomChatEntryKind.chat,
      'RoomScreenEnterRoomMessageEvent' => RoomChatEntryKind.enter,
      'inRoomWelcomeContentEvent' => RoomChatEntryKind.enter,
      'RoomScreenSystemNoticeEvent' => RoomChatEntryKind.system,
      'RoomScreenImageEvent' => RoomChatEntryKind.image,
      'RoomScreenExpressionEvent' => RoomChatEntryKind.expression,
      'roomScreenSendGiftComboEvent' => RoomChatEntryKind.gift,
      'RoomSendGiftComboPublicScreenEvent' => RoomChatEntryKind.gift,
      'RoomSendGiftPublicScreenEvent' => RoomChatEntryKind.gift,
      'CustomPublicScreenMsg' => RoomChatEntryKind.system,
      'RoomScreenLuckyBagSendEvent' => RoomChatEntryKind.gift,
      'RoomScreenLuckyBagReciveEvent' => RoomChatEntryKind.gift,
      'LuckyWheelCancelContent' => RoomChatEntryKind.system,
      'LuckyWheelStartContent' => RoomChatEntryKind.system,
      _ => null,
    };
  }

  String? _messageText(Map<String, dynamic> payload, String event) {
    final raw = _stringValue(
      payload['msg'] ??
          payload['message'] ??
          payload['content'] ??
          payload['text'] ??
          payload['data'] ??
          payload['giftName'],
    );
    if (raw != null) return raw;
    return switch (event) {
      'RoomScreenEnterRoomMessageEvent' => 'entered the room',
      'inRoomWelcomeContentEvent' => 'entered the room',
      'roomScreenSendGiftComboEvent' => 'sent a gift',
      'RoomSendGiftPublicScreenEvent' => 'sent a gift',
      _ => null,
    };
  }

  List<RoomChatEntry> _appendMessage(RoomChatEntry entry) {
    final next = [...state.messages, entry];
    if (next.length <= 80) return next;
    return next.sublist(next.length - 80);
  }

  Map<String, dynamic> _payloadMap(Object? payload) {
    final decoded = _decodePayload(payload);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    final text = _stringValue(decoded);
    return text == null ? const {} : {'msg': text};
  }

  Object? _decodePayload(Object? payload) {
    if (payload is String) {
      try {
        return jsonDecode(payload);
      } catch (_) {
        return payload;
      }
    }
    return payload;
  }

  Map<String, dynamic> _userMap(Map<String, dynamic> payload) {
    final raw =
        payload['userBaseInfo'] ??
        payload['userInfo'] ??
        payload['sendUserInfo'] ??
        payload['fromUser'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return const {};
  }

  DateTime _messageTime(
    RoomSocketMessage message,
    Map<String, dynamic> payload,
  ) {
    final rawTimestamp = _intValue(payload['timestamp'] ?? message.timestamp);
    if (rawTimestamp == null || rawTimestamp <= 0) return DateTime.now();
    final timestamp = rawTimestamp < 1000000000000
        ? rawTimestamp * 1000
        : rawTimestamp;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  String _roomTitle(RoomInfo? info, EnterRoomResp? enterResponse) {
    final roomData = _roomDataMap(info);
    return _stringValue(
          info?.title ??
              roomData['title'] ??
              roomData['roomName'] ??
              roomData['name'] ??
              enterResponse?.raw['title'],
        ) ??
        'Voice Room';
  }

  String? _roomAvatar(RoomInfo? info, Map<String, dynamic> roomData) {
    return _stringValue(
      info?.avatar ??
          roomData['avatar'] ??
          roomData['roomAvatar'] ??
          roomData['cover'],
    );
  }

  String _roomNo(
    RoomInfo? info,
    EnterRoomResp? enterResponse,
    String currentRoomId,
  ) {
    final roomData = _roomDataMap(info);
    return _stringValue(
          roomData['roomNo'] ??
              roomData['roomNumber'] ??
              roomData['userNo'] ??
              info?.roomId ??
              enterResponse?.raw['roomNo'] ??
              enterResponse?.raw['roomId'],
        ) ??
        currentRoomId;
  }

  int _onlineCount(RoomInfo? info, Map<String, dynamic> roomData) {
    return info?.audienceCount ??
        _intValue(
          roomData['audienceCount'] ??
              roomData['roomAudience'] ??
              roomData['onlineNum'] ??
              roomData['inRoomNum'],
        ) ??
        0;
  }

  Map<String, dynamic> _roomDataMap(RoomInfo? info) {
    final raw = info?.raw;
    if (raw == null) return const {};
    final nested = raw['roomInfoDTO'] ?? raw['roomInfo'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return nested.cast<String, dynamic>();
    return raw;
  }

  String get _effectiveRoomId {
    return _stringValue(state.currentRoomId) ?? _roomId;
  }

  String? _stringValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    _removeGiftListener?.call();
    _repository.removeListener(_syncFromManager);
    unawaited(_socketSubscription.cancel());
    super.dispose();
  }
}
