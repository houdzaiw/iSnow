import '../../../manager/app_socket_manager.dart';
import '../../../manager/room_agora_manager.dart';
import '../../../manager/room_manager.dart';
import '../../../model/room_models.dart';

enum RoomChatFilter { all, chat, gift }

enum RoomChatEntryKind { chat, gift, system, enter, image, expression }

class RoomSeatViewData {
  const RoomSeatViewData({
    required this.position,
    this.uid,
    this.nickname,
    this.avatar,
    this.heat = 100,
    this.isLocked = false,
    this.isMuted = false,
    this.volume = 0,
    this.raw = const {},
  });

  final int position;
  final int? uid;
  final String? nickname;
  final String? avatar;
  final int heat;
  final bool isLocked;
  final bool isMuted;
  final int volume;
  final Map<String, dynamic> raw;

  bool get isOccupied => uid != null && uid! > 0;
  bool get isSpeaking => volume > 0;

  factory RoomSeatViewData.empty(int position) {
    return RoomSeatViewData(position: position);
  }

  factory RoomSeatViewData.fromMic(
    RoomMicModel mic, {
    required int position,
    int volume = 0,
  }) {
    final userInfo = mic.userInfo ?? const <String, dynamic>{};
    return RoomSeatViewData(
      position: mic.position > 0 ? mic.position : position,
      uid: mic.uid,
      nickname: _stringValue(
        userInfo['nick'] ??
            userInfo['nickname'] ??
            userInfo['userName'] ??
            mic.raw['nick'],
      ),
      avatar: _stringValue(
        userInfo['avatar'] ?? userInfo['headUrl'] ?? mic.raw['avatar'],
      ),
      heat:
          _intValue(
            mic.raw['heat'] ??
                mic.raw['score'] ??
                mic.raw['charmValue'] ??
                userInfo['wealthLevel'],
          ) ??
          100,
      isLocked: mic.isLocked ?? false,
      isMuted: mic.isMuted ?? false,
      volume: volume,
      raw: mic.raw,
    );
  }
}

class RoomChatEntry {
  const RoomChatEntry({
    required this.id,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
    this.senderUid,
    this.isLocal = false,
  });

  final String id;
  final RoomChatEntryKind kind;
  final String text;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;
  final int? senderUid;
  final bool isLocal;

  bool get isGift => kind == RoomChatEntryKind.gift;
  bool get isChat =>
      kind == RoomChatEntryKind.chat || kind == RoomChatEntryKind.enter;

  factory RoomChatEntry.system(String text) {
    return RoomChatEntry(
      id: 'system-${DateTime.now().microsecondsSinceEpoch}',
      kind: RoomChatEntryKind.system,
      text: text,
      createdAt: DateTime.now(),
    );
  }
}

class RoomPageState {
  const RoomPageState({
    required this.roomId,
    this.currentRoomId = '',
    this.status = RoomStatus.idle,
    this.isInRoom = false,
    this.isMinimized = false,
    this.roomTitle = 'Voice Room',
    this.roomAvatar,
    this.roomNo = '',
    this.roomDesc,
    this.onlineCount = 0,
    this.roomInfo,
    this.enterResponse,
    this.seats = const [],
    this.messages = const [],
    this.chatFilter = RoomChatFilter.all,
    this.currentUid,
    this.currentUserName,
    this.currentUserAvatar,
    this.socketStatus = AppSocketStatus.idle,
    this.socketReady = false,
    this.socketErrorMessage,
    this.agoraState = const RoomAgoraState(),
    this.sendingMessage = false,
    this.pendingSeatPosition,
    this.errorMessage,
  });

  final String roomId;
  final String currentRoomId;
  final RoomStatus status;
  final bool isInRoom;
  final bool isMinimized;
  final String roomTitle;
  final String? roomAvatar;
  final String roomNo;
  final String? roomDesc;
  final int onlineCount;
  final RoomInfo? roomInfo;
  final EnterRoomResp? enterResponse;
  final List<RoomSeatViewData> seats;
  final List<RoomChatEntry> messages;
  final RoomChatFilter chatFilter;
  final int? currentUid;
  final String? currentUserName;
  final String? currentUserAvatar;
  final AppSocketStatus socketStatus;
  final bool socketReady;
  final String? socketErrorMessage;
  final RoomAgoraState agoraState;
  final bool sendingMessage;
  final int? pendingSeatPosition;
  final String? errorMessage;

  bool get isLoading =>
      status == RoomStatus.entering || status == RoomStatus.leaving;

  bool get isReady => status == RoomStatus.ready && isInRoom;

  bool get isOnMic {
    final uid = currentUid;
    if (uid == null || uid == 0) return false;
    return seats.any((seat) => seat.uid == uid);
  }

  List<RoomChatEntry> get visibleMessages {
    return switch (chatFilter) {
      RoomChatFilter.all => messages,
      RoomChatFilter.chat => messages.where((item) => item.isChat).toList(),
      RoomChatFilter.gift => messages.where((item) => item.isGift).toList(),
    };
  }

  factory RoomPageState.initial(String roomId) {
    return RoomPageState(
      roomId: roomId,
      currentRoomId: roomId,
      roomNo: roomId,
      seats: List.generate(20, (index) => RoomSeatViewData.empty(index + 1)),
      messages: [
        RoomChatEntry(
          id: 'room-policy',
          kind: RoomChatEntryKind.system,
          text: 'Violations may lead to account restrictions.',
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  RoomPageState copyWith({
    String? currentRoomId,
    RoomStatus? status,
    bool? isInRoom,
    bool? isMinimized,
    String? roomTitle,
    Object? roomAvatar = _sentinel,
    String? roomNo,
    Object? roomDesc = _sentinel,
    int? onlineCount,
    RoomInfo? roomInfo,
    Object? enterResponse = _sentinel,
    List<RoomSeatViewData>? seats,
    List<RoomChatEntry>? messages,
    RoomChatFilter? chatFilter,
    Object? currentUid = _sentinel,
    Object? currentUserName = _sentinel,
    Object? currentUserAvatar = _sentinel,
    AppSocketStatus? socketStatus,
    bool? socketReady,
    Object? socketErrorMessage = _sentinel,
    RoomAgoraState? agoraState,
    bool? sendingMessage,
    Object? pendingSeatPosition = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return RoomPageState(
      roomId: roomId,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      status: status ?? this.status,
      isInRoom: isInRoom ?? this.isInRoom,
      isMinimized: isMinimized ?? this.isMinimized,
      roomTitle: roomTitle ?? this.roomTitle,
      roomAvatar: identical(roomAvatar, _sentinel)
          ? this.roomAvatar
          : roomAvatar as String?,
      roomNo: roomNo ?? this.roomNo,
      roomDesc: identical(roomDesc, _sentinel)
          ? this.roomDesc
          : roomDesc as String?,
      onlineCount: onlineCount ?? this.onlineCount,
      roomInfo: roomInfo ?? this.roomInfo,
      enterResponse: identical(enterResponse, _sentinel)
          ? this.enterResponse
          : enterResponse as EnterRoomResp?,
      seats: seats ?? this.seats,
      messages: messages ?? this.messages,
      chatFilter: chatFilter ?? this.chatFilter,
      currentUid: identical(currentUid, _sentinel)
          ? this.currentUid
          : currentUid as int?,
      currentUserName: identical(currentUserName, _sentinel)
          ? this.currentUserName
          : currentUserName as String?,
      currentUserAvatar: identical(currentUserAvatar, _sentinel)
          ? this.currentUserAvatar
          : currentUserAvatar as String?,
      socketStatus: socketStatus ?? this.socketStatus,
      socketReady: socketReady ?? this.socketReady,
      socketErrorMessage: identical(socketErrorMessage, _sentinel)
          ? this.socketErrorMessage
          : socketErrorMessage as String?,
      agoraState: agoraState ?? this.agoraState,
      sendingMessage: sendingMessage ?? this.sendingMessage,
      pendingSeatPosition: identical(pendingSeatPosition, _sentinel)
          ? this.pendingSeatPosition
          : pendingSeatPosition as int?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
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

const Object _sentinel = Object();
