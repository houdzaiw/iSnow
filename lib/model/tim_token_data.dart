class TimTokenData {
  const TimTokenData({
    required this.appId,
    required this.token,
    this.expiresIn,
    this.expires,
  });

  final int appId;
  final String token;
  final double? expiresIn;
  final double? expires;

  factory TimTokenData.fromJson(Map<String, dynamic> json) {
    return TimTokenData(
      appId: (json['appID'] as num?)?.toInt() ?? 0,
      token: json['token']?.toString() ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toDouble(),
      expires: (json['expires'] as num?)?.toDouble(),
    );
  }
}
