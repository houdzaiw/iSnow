// filepath: /Users/admin/Documents/project/isnow/lib/model/login_response.dart

class LoginResponse {
  final bool success;
  final String? message;
  final UserData? data;
  final String? token;

  LoginResponse({
    required this.success,
    this.message,
    this.data,
    this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      token: json['token'] as String?,
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'data': data?.toJson(),
    };
  }
}

class UserData {
  final String? userId;
  final String? email;
  final String? nickname;
  final String? avatar;
  final String? phone;

  UserData({
    this.userId,
    this.email,
    this.nickname,
    this.avatar,
    this.phone,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
    };
  }
}

