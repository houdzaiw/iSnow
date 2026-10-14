import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/oauth/provider/login_provider.dart';
import 'package:project/manager/api_error_message.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/http_dio_manager.dart';
import 'package:project/model/login_response.dart';
import 'package:project/model/server_response.dart';
import 'package:project/model/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('msg takes precedence and diagnostic fields remain available', () {
    final response = NadyServerResponse<void>.fromJson(const {
      'code': 8011,
      'msg': 'Network anomaly, pleaselogin again.',
      'message': 'Internal fallback',
      'traceId': 'a2fe0252-bfca-4f84-bc42-d213f475687e',
    }, null);
    final error = response.toException();
    expect(response.message, 'Network anomaly, pleaselogin again.');
    expect(userFacingErrorMessage(error, fallback: 'Failed'), response.message);
    expect(error.code, 8011);
    expect(error.traceId, 'a2fe0252-bfca-4f84-bc42-d213f475687e');
    expect(error.toString(), contains('code=8011'));
    expect(error.toString(), contains('traceId='));
  });

  for (final msg in [null, '', '   ', 123, <String>[]]) {
    test('invalid/empty msg falls back to message: $msg', () {
      final response = NadyServerResponse<void>.fromJson({
        'code': 1003,
        'msg': msg,
        'message': 'Server fallback',
      }, null);
      expect(userFacingErrorMessage(response.toException()), 'Server fallback');
    });
  }

  test('missing server text keeps the operation-specific fallback', () {
    expect(nadyResponseMessage(const {'msg': ' ', 'message': null}), isNull);
    expect(
      userFacingErrorMessage(
        const NadyApiException(message: ''),
        fallback: 'Try again',
      ),
      'Try again',
    );
    expect(
      userFacingErrorMessage(StateError('offline'), fallback: 'Try again'),
      'Try again',
    );
    expect(userFacingErrorMessage(StateError('offline')), 'Bad state: offline');
  });

  test(
    'generated diagnostic defaults do not override a localized fallback',
    () {
      final error = NadyServerResponse<void>.fromJson(const {
        'code': 1003,
        'msg': ' ',
        'message': null,
        'traceId': 'empty-message',
      }, null).toException();
      expect(error.hasDisplayMessage, isFalse);
      expect(serverErrorMessage(error), isNull);
      expect(
        userFacingErrorMessage(error, fallback: 'Local fallback'),
        'Local fallback',
      );
      expect(userFacingErrorMessage(error), 'Request failed');
      expect(error.toString(), contains('traceId=empty-message'));
    },
  );

  test('empty login failure text allows the page fallback to be used', () {
    for (final message in [null, '', '   ']) {
      expect(LoginResponse.failure(message).message, isNull);
    }
    expect(
      LoginResponse.failure('Please log in again').message,
      'Please log in again',
    );
  });

  for (final data in [null, 'not a user', <String>[], <String, Object>{}]) {
    test('failure data cannot mask the server message: $data', () {
      var decoded = false;
      final response = NadyServerResponse<HasUserResponse>.fromJson(
        {'code': 8011, 'msg': 'Please log in again', 'data': data},
        (json) {
          decoded = true;
          return HasUserResponse.fromJson(
            (json as Map).cast<String, dynamic>(),
          );
        },
      );
      expect(decoded, isFalse);
      expect(response.data, isNull);
      expect(
        userFacingErrorMessage(response.toException()),
        'Please log in again',
      );
    });
  }

  test('success still decodes its typed data', () {
    final response = NadyServerResponse<HasUserResponse>.fromJson(
      const {
        'code': 200,
        'msg': 'success',
        'data': {'hasUser': true, 'status': 1},
      },
      (json) => HasUserResponse.fromJson((json as Map).cast<String, dynamic>()),
    );
    expect(response.isSuccess, isTrue);
    expect(response.data?.hasUser, isTrue);
  });

  test('string-valued API codes cannot mask the server msg', () {
    final response = NadyServerResponse<void>.fromJson(const {
      'code': '8011',
      'msg': 'Please log in again',
    }, null);
    expect(response.code, 8011);
    expect(
      userFacingErrorMessage(response.toException()),
      'Please log in again',
    );
  });

  test('success with null data retains the nullable converter contract', () {
    final response = NadyServerResponse<bool>.fromJson(const {
      'code': 200,
      'data': null,
    }, (json) => json == true);
    expect(response.data, isFalse);
  });

  test('HTTP error bodies also prefer msg without showing Dio diagnostics', () {
    final options = RequestOptions(path: HttpApi.hasUser);
    final error = DioException.badResponse(
      statusCode: 500,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 500,
        data: {'msg': 'Service unavailable', 'message': 'Internal error'},
      ),
    );
    expect(
      userFacingErrorMessage(error, fallback: 'Network failed'),
      'Service unavailable',
    );
    expect(error.response?.statusCode, 500);
  });

  test(
    'transport errors without server text retain their friendly fallback',
    () {
      final error = DioException(
        requestOptions: RequestOptions(path: HttpApi.hasUser),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout diagnostics',
      );
      expect(serverErrorMessage(error), isNull);
      expect(userFacingErrorMessage(error, fallback: 'Try again'), 'Try again');
    },
  );

  test('Dio wrapping a business exception still exposes only its message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: HttpApi.hasUser),
      error: const NadyApiException(message: 'Please log in again', code: 8011),
    );
    expect(userFacingErrorMessage(error), 'Please log in again');
  });

  test(
    'hasUser repository preserves msg, code and traceId from the API',
    () async {
      final repository = LoginProvider(
        httpManager: _Http(const {
          'code': 8011,
          'msg': 'Network anomaly, pleaselogin again.',
          'message': 'Internal fallback',
          'traceId': 'has-user-error',
          'data': null,
        }),
      );
      await expectLater(
        repository.hasUser(phone: '123456789', areaCode: '1'),
        throwsA(
          isA<NadyApiException>()
              .having(
                (error) => error.message,
                'message',
                'Network anomaly, pleaselogin again.',
              )
              .having((error) => error.code, 'code', 8011)
              .having((error) => error.traceId, 'traceId', 'has-user-error'),
        ),
      );
    },
  );
}

class _Http implements HttpDioManager {
  const _Http(this.response);
  final Map<String, dynamic> response;
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    expect(path, HttpApi.hasUser);
    expect(queryParameters, {'phone': '123456789', 'areaCode': '1'});
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
