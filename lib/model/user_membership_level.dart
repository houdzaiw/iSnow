/// Optional membership fields shared by login, Profile and membership pages.
class UserMembershipLevel {
  const UserMembershipLevel({
    this.vipLevel = 0,
    this.vipNextLevel,
    this.vipIcon = '',
    this.aristocracyLevel = 0,
    this.aristocracyIcon = '',
  });
  final int vipLevel;
  final int? vipNextLevel;
  final String vipIcon;
  final int aristocracyLevel;
  final String aristocracyIcon;
  factory UserMembershipLevel.fromJson(Map<String, dynamic> json) =>
      UserMembershipLevel(
        vipLevel: _int(json['vipLevel']),
        vipNextLevel: json['vipNextLevel'] == null
            ? null
            : _int(json['vipNextLevel']),
        vipIcon: json['vipIcon']?.toString() ?? '',
        aristocracyLevel: _int(json['aristocracyLevel']),
        aristocracyIcon:
            (json['aristocracyIcon'] ?? json['aristocracyEnIcon'])
                ?.toString() ??
            '',
      );
  Map<String, dynamic> toJson() => {
    'vipLevel': vipLevel,
    'vipNextLevel': vipNextLevel,
    'vipIcon': vipIcon,
    'aristocracyLevel': aristocracyLevel,
    'aristocracyIcon': aristocracyIcon,
  };
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
