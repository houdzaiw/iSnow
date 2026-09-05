import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/viewmodel/room_state.dart';
import 'package:project/model/room_models.dart';

void main() {
  test('parses zero-based mic position and nested room user data', () {
    final mic = RoomMicModel.fromJson({
      'position': 0,
      'isLock': false,
      'isMute': false,
      'charmValue': 12,
      'roomUserBaseDto': {
        'uid': 72546721,
        'userBase': {
          'uid': 72546721,
          'nick': 'hei',
          'avatar': 'https://example.com/avatar.jpg',
          'wealthLevel': 16,
        },
      },
    });

    final seat = RoomSeatViewData.fromMic(mic, position: 0);

    expect(mic.position, 0);
    expect(mic.uid, 72546721);
    expect(mic.userInfo?['nick'], 'hei');
    expect(seat.position, 0);
    expect(seat.displayPosition, 1);
    expect(seat.uid, 72546721);
    expect(seat.nickname, 'hei');
    expect(seat.avatar, 'https://example.com/avatar.jpg');
    expect(seat.heat, 12);
  });

  test('parses room identity strings', () {
    final owner = EnterRoomResp.fromJson({
      'roomId': '1001',
      'identity': 'ROOM_OWNER',
    });
    final manager = EnterRoomResp.fromJson({
      'roomId': '1001',
      'identity': 'ROOM_MANAGER',
    });
    final audience = EnterRoomResp.fromJson({
      'roomId': '1001',
      'identity': 'ROOM_AUDIENCE',
    });

    expect(owner.identity, UserRoomIdentity.owner);
    expect(owner.identity?.isOwnerOrManager, isTrue);
    expect(manager.identity, UserRoomIdentity.manager);
    expect(manager.identity?.isOwnerOrManager, isTrue);
    expect(audience.identity, UserRoomIdentity.audience);
    expect(audience.identity?.isOwnerOrManager, isFalse);
  });

  test('detects owner by room owner uid fallback', () {
    final roomInfo = RoomInfo.fromJson({
      'roomInfoDTO': {'roomId': '1001', 'roomUid': 72546721},
    });
    final state = RoomPageState.initial(
      '1001',
    ).copyWith(roomInfo: roomInfo, currentUid: 72546721);

    expect(roomInfo.roomOwnerUid, 72546721);
    expect(state.isOwnerOrManager, isTrue);
  });
}
