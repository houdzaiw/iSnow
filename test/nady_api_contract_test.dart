import 'package:flutter_test/flutter_test.dart';
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
          'userStatus': 'USER_STATUS_NEED_COMPLETE',
        },
      }, (json) => UserData.fromJson((json as Map).cast<String, dynamic>()));

      expect(response.isSuccess, isTrue);
      expect(response.traceId, 'trace-1');
      expect(response.data?.uid, 1001);
      expect(response.data?.userStatus, NadyLoginStatus.incompleteInformation);
      expect(
        response.data?.toJson()['userStatus'],
        'USER_STATUS_NEED_COMPLETE',
      );
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
