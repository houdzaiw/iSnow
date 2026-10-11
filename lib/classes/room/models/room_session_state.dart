import '../../../manager/room_manager.dart';

class RoomSessionState {
  const RoomSessionState({
    this.room = const RoomState(),
    this.isLoggedIn = false,
    this.isBusy = false,
  });

  final RoomState room;
  final bool isLoggedIn;
  final bool isBusy;

  bool get canShowMini =>
      isLoggedIn &&
      room.isInRoom &&
      room.isMinimized &&
      room.status == RoomStatus.ready &&
      (room.currentRoomId?.isNotEmpty ?? false);

  RoomSessionState copyWith({
    RoomState? room,
    bool? isLoggedIn,
    bool? isBusy,
  }) => RoomSessionState(
    room: room ?? this.room,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isBusy: isBusy ?? this.isBusy,
  );
}
