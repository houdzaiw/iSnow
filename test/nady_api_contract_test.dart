import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/create_party/create_party_models.dart';
import 'package:project/classes/create_party/create_party_state.dart';
import 'package:project/classes/create_room/create_room_models.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/server_response.dart';
import 'package:project/model/user_profile.dart';

void main() {
  group('Nady request signature', () {
    test('matches the documented md5 signing rule', () {
      final sign = HttpDioManager.generateSign({
        'phone': '13212345678',
        'areaCode': '996',
        'v': '1234567890',
      }, HttpDioManager.devSecret);

      expect(sign, 'ede2b341ffaedfc3040af965560ef5c5');
    });

    test('is independent of param order and ignores punctuation', () {
      final ordered = HttpDioManager.generateSign({
        'areaCode': '996',
        'phone': '13212345678',
        'v': '1234567890',
      }, HttpDioManager.devSecret);
      final shuffled = HttpDioManager.generateSign({
        'v': '1234567890',
        'phone': '132-1234 5678',
        'areaCode': '+996',
      }, HttpDioManager.devSecret);

      expect(shuffled, ordered);
    });
  });

  group('Nady response parsing', () {
    test('serializes create party request like Nady API', () {
      final startTime = DateTime(2026, 9, 6, 21, 30);
      final draft = CreatePartyDraft(
        picUrl: 'dev/party-cover.png',
        topic: 'Weekend Party',
        description: 'Sing and chat together',
        duration: 90,
        beginTime: startTime,
        tagIdList: const ['1', '2'],
      );

      expect(draft.toJson(), {
        'picUrl': 'dev/party-cover.png',
        'topic': 'Weekend Party',
        'description': 'Sing and chat together',
        'duration': 90,
        'beginTime': startTime.toUtc().millisecondsSinceEpoch,
        'tagIdList': ['1', '2'],
      });
    });

    test('enables create party submit only when required fields are ready', () {
      final ready = CreatePartyState(
        startTime: DateTime.now().add(const Duration(hours: 1)),
        coverUrl: 'dev/party-cover.png',
        topic: 'Weekend Party',
        description: 'Sing and chat together',
        durationMinutes: 90,
      );

      expect(ready.canSubmit, isTrue);
      expect(ready.copyWith(coverUrl: null).canSubmit, isFalse);
      expect(ready.copyWith(topic: '   ').canSubmit, isFalse);
      expect(ready.copyWith(description: '   ').canSubmit, isFalse);
      expect(ready.copyWith(durationMinutes: 0).canSubmit, isFalse);
      expect(ready.copyWith(canCreateParty: false).canSubmit, isFalse);
    });

    test('serializes open room request and parses room id response', () {
      const draft = CreateRoomDraft(
        avatar: 'https://simisoul.xyz/dev/avatar.jpg',
        title: 'hello1',
        roomDesc: 'hello',
        language: 'en',
      );
      final response = NadyServerResponse<String>.fromJson({
        'code': 200,
        'data': '2091733862198116353',
        'timestamp': '2026-08-24T03:46:30.846+0000',
        'message': 'success',
        'traceId': 'c8646e7f-d896-4ca5-a76f-799a45414a02',
        'msg': 'success',
      }, (json) => json?.toString() ?? '');

      expect(draft.toJson(), {
        'avatar': 'https://simisoul.xyz/dev/avatar.jpg',
        'title': 'hello1',
        'roomDesc': 'hello',
        'language': 'en',
      });
      expect(response.isSuccess, isTrue);
      expect(response.data, '2091733862198116353');
    });

    test('parses server response wrapper and user status', () {
      final response = NadyServerResponse<UserData>.fromJson({
        'code': 200,
        'message': 'ok',
        'timestamp': '2026-08-02T12:00:00Z',
        'traceId': 'trace-1',
        'data': {
          'uid': 1001,
          'userNo': 90001,
          'nick': 'Nady User',
          'gender': 1,
          'countryCode': 'KG',
          'areaCode': '996',
          'phone': '13212345678',
          'roomId': '2091733862198116353',
          'userStatus': 'USER_STATUS_NEED_COMPLETE',
        },
      }, (json) => UserData.fromJson((json as Map).cast<String, dynamic>()));

      expect(response.isSuccess, isTrue);
      expect(response.traceId, 'trace-1');
      expect(response.data?.uid, 1001);
      expect(response.data?.roomId, '2091733862198116353');
      expect(response.data?.userStatus, NadyLoginStatus.incompleteInformation);
      expect(
        response.data?.toJson()['userStatus'],
        'USER_STATUS_NEED_COMPLETE',
      );
      expect(response.data?.toJson()['roomId'], '2091733862198116353');
    });

    test('converts failure wrapper to debuggable exception', () {
      final response = NadyServerResponse<void>.fromJson({
        'code': 401,
        'message': 'invalid token',
        'traceId': 'trace-401',
      }, null);

      expect(response.isSuccess, isFalse);
      expect(
        response.toException().toString(),
        contains('traceId=trace-401 invalid token'),
      );
    });
  });
}
