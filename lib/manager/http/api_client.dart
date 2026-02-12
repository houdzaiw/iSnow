import 'package:dio/dio.dart';
import 'api_path.dart';
import '../../model/server_response.dart';

// HTTP 状态码
const int _httpOk = 200;

// ApiClient 类用于管理 API 调用
class ApiClient {
  final Dio dio;

  ApiClient({required this.dio}) {
    // 设置 baseUrl
    dio.options.baseUrl = ApiPath.baseUrl;
  }

  /// 统一的 POST 请求处理
  /// 返回 ApiResponse，封装了 HTTP 层面的错误处理
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      // HTTP 请求失败
      if (response.statusCode != _httpOk) {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      // HTTP 请求成功，解析服务端响应
      if (response.data is Map<String, dynamic>) {
        final serverResponse = ServerResponse.fromJson(
          response.data as Map<String, dynamic>,
          null,
        );

        // 检查业务状态码
        if (!serverResponse.isSuccess) {
          // 业务失败，返回失败响应
          return ApiResponse(
            success: false,
            message: serverResponse.message,
            data: serverResponse.data,
            statusCode: response.statusCode,
            traceId: serverResponse.traceId,
          );
        }

        // HTTP 和业务都成功，返回 data 字段中的数据
        return ApiResponse(
          success: true,
          data: serverResponse.data, // 只返回 data.data
          statusCode: response.statusCode,
          message: serverResponse.message,
          traceId: serverResponse.traceId,
        );
      }

      // 如果响应不是标准格式，返回原始数据
      return ApiResponse(
        success: true,
        data: response.data,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  /// 统一的 GET 请求处理
  /// 返回 ApiResponse，封装了 HTTP 层面的错误处理
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
      );

      // HTTP 请求失败
      if (response.statusCode != _httpOk) {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      // HTTP 请求成功，解析服务端响应
      if (response.data is Map<String, dynamic>) {
        final serverResponse = ServerResponse.fromJson(
          response.data as Map<String, dynamic>,
          null,
        );

        // 检查业务状态码
        if (!serverResponse.isSuccess) {
          // 业务失败，返回失败响应
          return ApiResponse(
            success: false,
            message: serverResponse.message,
            data: serverResponse.data,
            statusCode: response.statusCode,
            traceId: serverResponse.traceId,
          );
        }

        // HTTP 和业务都成功，返回 data 字段中的数据
        return ApiResponse(
          success: true,
          data: serverResponse.data, // 只返回 data.data
          statusCode: response.statusCode,
          message: serverResponse.message,
          traceId: serverResponse.traceId,
        );
      }

      // 如果响应不是标准格式，返回原始数据
      return ApiResponse(
        success: true,
        data: response.data,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  /// 统一处理 DioException
  ApiResponse _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiResponse(
        success: false,
        message: 'Connection timeout, please try again',
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Server error',
          data: data,
        );
      }
      return ApiResponse(
        success: false,
        message: 'Server error: ${e.response?.statusCode}',
      );
    } else {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.message}',
      );
    }
  }
}

/// API 响应封装类
/// 用于统一封装 HTTP 层面的响应
class ApiResponse {
  final bool success; // HTTP 请求是否成功
  final String? message; // 错误消息
  final dynamic data; // 响应数据（仅包含 data.data）
  final int? statusCode; // HTTP 状态码
  final String? traceId; // 追踪 ID

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.traceId,
  });
}

class ServiceStatusCode {
  static const int successCode = 200;
  static const int failCode = -1;
  static const int timeoutCode = -1001;
  static const int cancelCode = -1002;
  static const int badCertificateCode = -1003;
  static const int connectionErrorCode = -1004;
  static const int unknownCode = -1100;
  static const int tokenExpired = 1006; //token过期
  static const int enterRoomPassword = 4011; //进房输入密码
  static const int enterRoomCant = 4010; //进房被拒绝
  static const int enterRoomPasswordError = 4012; //进房输入密码错误
  static const int loginRestrictionIp = 8011; //ip登录限制
  static const int loginRestrictionSysLanguage = 8012; //系统语言登录限制
  static const int loginRestrictionSIM = 8013; //sim卡登录限制
  static const int loginRestrictionTimezone = 8014; //时区登录限制
  static const int loginRestrictionStoreCode = 8015; //app商店code登录限制
  static const int insufficientCoinBalanc = 10003; //金币不足
  static const int restrictionsOnRegistration = 2009; //注册限制
  static const int shutDownCode = 2010; //封禁 设备/Ip
  static const List<int> loginRestrictionCodes = [
    loginRestrictionIp,
    loginRestrictionSysLanguage,
    loginRestrictionSIM,
    loginRestrictionTimezone,
    loginRestrictionStoreCode
  ];
}

class CommonApi {
  static final CommonApi _instance = CommonApi._();

  static CommonApi get of => _instance;

  static ApiClient get client => _instance.api;

  factory CommonApi() => _instance;

  CommonApi._();

  late ApiClient api;

  void initialize(Dio dio) {
    api = ApiClient(dio: dio);
  }
}