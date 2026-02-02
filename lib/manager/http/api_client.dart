import 'package:dio/dio.dart';
import 'api_path.dart';

// ApiClient 类用于管理 API 调用
class ApiClient {
  final Dio dio;

  ApiClient({required this.dio}) {
    // 设置 baseUrl
    dio.options.baseUrl = ApiPath.baseUrl;
  }

  // 可以在这里添加具体的 API 方法
  // 例如：
  // Future<Response> login(Map<String, dynamic> data) async {
  //   return await dio.post('/api/login', data: data);
  // }
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