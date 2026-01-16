import 'package:dio/dio.dart';

class HttpDioManager {
  static const String _baseUrl = 'http://simi2.w1.luyouxia.net/simi';

  static final HttpDioManager _instance = HttpDioManager._internal();
  late Dio _dio;

  // Private constructor
  HttpDioManager._internal() {
    _initDio();
  }

  // Factory constructor for singleton pattern
  factory HttpDioManager() {
    return _instance;
  }

  // Initialize Dio configuration
  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add custom headers or token here if needed
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  // GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PATCH request
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Download file
  Future<void> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Upload file
  Future<dynamic> upload(
    String path, {
    required String filePath,
    String fileKey = 'file',
    Map<String, dynamic>? extraFields,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(filePath),
        if (extraFields != null) ...extraFields,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Handle errors
  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        print('Connection timeout: ${error.message}');
      case DioExceptionType.sendTimeout:
        print('Send timeout: ${error.message}');
      case DioExceptionType.receiveTimeout:
        print('Receive timeout: ${error.message}');
      case DioExceptionType.badResponse:
        print('Bad response: ${error.response?.statusCode} - ${error.message}');
      case DioExceptionType.cancel:
        print('Request cancelled: ${error.message}');
      case DioExceptionType.connectionError:
        print('Connection error: ${error.message}');
      case DioExceptionType.unknown:
        print('Unknown error: ${error.message}');
      case DioExceptionType.badCertificate:
        print('Bad certificate: ${error.message}');
    }
  }

  // Get Dio instance
  Dio getDio() {
    return _dio;
  }

  // Close Dio
  void close() {
    _dio.close();
  }
}

