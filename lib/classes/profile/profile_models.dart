import '../../model/user_profile.dart';

class ProfileAccountSummary {
  const ProfileAccountSummary({
    required this.user,
    required this.followingNum,
    required this.followerNum,
    required this.visitorNum,
    required this.receiveGiftValue,
  });

  final UserData user;
  final int followingNum;
  final int followerNum;
  final int visitorNum;
  final int receiveGiftValue;

  factory ProfileAccountSummary.cached(UserData user) {
    return ProfileAccountSummary(
      user: user,
      followingNum: 0,
      followerNum: 0,
      visitorNum: 0,
      receiveGiftValue: 0,
    );
  }

  factory ProfileAccountSummary.fromMe(MeModel me) {
    return ProfileAccountSummary(
      user: me.userBaseInfo,
      followingNum: me.followingNum,
      followerNum: me.followerNum,
      visitorNum: me.visitorNum,
      receiveGiftValue: me.receiveGiftValue,
    );
  }
}

class ProfileMetricItem {
  const ProfileMetricItem({required this.value, required this.titleKey});

  final String value;
  final String titleKey;
}
