import 'base_user_model.dart';

class UserModel {
  final int followingNum;
  final int followerNum;
  final int visitorNum;
  final int receiveGiftValue;
  final BaseUserInfo userBaseInfo;

  UserModel({
    required this.followingNum,
    required this.followerNum,
    required this.visitorNum,
    required this.receiveGiftValue,
    required this.userBaseInfo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      followingNum: json['followingNum'] ?? 0,
      followerNum: json['followerNum'] ?? 0,
      visitorNum: json['visitorNum'] ?? 0,
      receiveGiftValue: json['receiveGiftValue'] ?? 0,
      userBaseInfo: BaseUserInfo.fromJson(json['userBaseInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followingNum': followingNum,
      'followerNum': followerNum,
      'visitorNum': visitorNum,
      'receiveGiftValue': receiveGiftValue,
      'userBaseInfo': userBaseInfo.toJson(),
    };
  }

  /// 可选：手写 copyWith（推荐保留）
  UserModel copyWith({
    int? followingNum,
    int? followerNum,
    int? visitorNum,
    int? receiveGiftValue,
    BaseUserInfo? userBaseInfo,
  }) {
    return UserModel(
      followingNum: followingNum ?? this.followingNum,
      followerNum: followerNum ?? this.followerNum,
      visitorNum: visitorNum ?? this.visitorNum,
      receiveGiftValue: receiveGiftValue ?? this.receiveGiftValue,
      userBaseInfo: userBaseInfo ?? this.userBaseInfo,
    );
  }
}