// filepath: /Users/admin/Documents/project/isnow/lib/model/login_request.dart

class LoginRequest {
  final String account;
  final String password;
  final int loginType;
  final String areaCode;
  final String countryCode;

  LoginRequest({
    required this.account,
    required this.password,
    this.loginType = 5,
    this.areaCode = '1',
    this.countryCode = 'us',
  });

  Map<String, dynamic> toJson() {
    return {
      'code': account,
      'password': password,
      'loginType': loginType,
      'areaCode': areaCode,
      'countryCode': countryCode,
    };
  }
}

