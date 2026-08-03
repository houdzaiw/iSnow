import 'base_user_model.dart';

class LoginModel {
  final String token;
  final int uid;
  final String loginType;
  final double userNo;
  final BaseUserInfo? userBaseInfo;

  LoginModel({
    required this.token,
    required this.uid,
    required this.loginType,
    required this.userNo,
    this.userBaseInfo,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      token: json['token'] ?? '',
      uid: json['uid'] ?? 0,
      loginType: json['loginType']?.toString() ?? '',
      userNo: (json['userNo'] ?? 0).toDouble(),
      userBaseInfo: json['userBaseInfo'] != null
          ? BaseUserInfo.fromJson(json['userBaseInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'uid': uid,
      'loginType': loginType,
      'userNo': userNo,
      'userBaseInfo': userBaseInfo?.toJson(),
    };
  }

  LoginModel copyWith({
    String? token,
    int? uid,
    String? loginType,
    double? userNo,
    BaseUserInfo? userBaseInfo,
  }) {
    return LoginModel(
      token: token ?? this.token,
      uid: uid ?? this.uid,
      loginType: loginType ?? this.loginType,
      userNo: userNo ?? this.userNo,
      userBaseInfo: userBaseInfo ?? this.userBaseInfo,
    );
  }
}