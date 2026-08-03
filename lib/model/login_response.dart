import 'user_profile.dart';

class LoginResponse {
  const LoginResponse({
    required this.success,
    this.message,
    this.data,
    this.token,
    this.uid,
    this.status = NadyLoginStatus.unknown,
    this.loginType,
    this.userNo,
  });

  final bool success;
  final String? message;
  final UserData? data;
  final String? token;
  final int? uid;
  final NadyLoginStatus status;
  final String? loginType;
  final double? userNo;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userBaseInfo = (json['userBaseInfo'] as Map?)
        ?.cast<String, dynamic>();
    final uid = (json['uid'] as num?)?.toInt();
    return LoginResponse(
      success: true,
      token: json['token']?.toString(),
      uid: uid,
      status: nadyLoginStatusFromJson(json['status']),
      loginType: json['loginType']?.toString(),
      userNo: (json['userNo'] as num?)?.toDouble(),
      data: userBaseInfo == null
          ? null
          : UserData.fromJson(userBaseInfo).copyWith(uid: uid),
    );
  }

  factory LoginResponse.failure(String? message) {
    return LoginResponse(success: false, message: message);
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'uid': uid,
      'status': nadyLoginStatusToJson(status),
      'loginType': loginType,
      'userNo': userNo,
      'data': data?.toJson(),
    };
  }
}
