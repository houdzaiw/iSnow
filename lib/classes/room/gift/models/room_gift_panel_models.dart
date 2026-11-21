class RoomJackpotInfo {
  const RoomJackpotInfo({
    this.enabled = false,
    this.mode = '',
    this.displayAmount = 0,
    this.realAmount,
  });
  final bool enabled;
  final String mode;
  final int displayAmount;
  final int? realAmount;
  bool get isSuper => enabled && mode.toUpperCase() == 'SUPER';
  factory RoomJackpotInfo.fromJson(Map<String, dynamic> json) =>
      RoomJackpotInfo(
        enabled: json['enabled'] == true || json['enabled'] == 1,
        mode: '${json['mode'] ?? ''}'.toUpperCase(),
        displayAmount: _number(json['displayAmount']).clamp(0, 1 << 62),
        realAmount: json['realAmount'] == null
            ? null
            : _number(json['realAmount']),
      );
  @override
  bool operator ==(Object other) =>
      other is RoomJackpotInfo &&
      enabled == other.enabled &&
      mode == other.mode &&
      displayAmount == other.displayAmount &&
      realAmount == other.realAmount;
  @override
  int get hashCode => Object.hash(enabled, mode, displayAmount, realAmount);
}

class RoomGiftBannerSnapshot {
  const RoomGiftBannerSnapshot({
    required this.giftId,
    required this.senderUid,
    required this.senderName,
    required this.senderAvatar,
    required this.multiple,
    required this.winAmount,
  });
  final int giftId, senderUid, winAmount;
  final String senderName, senderAvatar;
  final double multiple;
  factory RoomGiftBannerSnapshot.fromJson(Map<String, dynamic> json) =>
      RoomGiftBannerSnapshot(
        giftId: _number(json['giftId']),
        senderUid: _number(json['senderUid']),
        senderName: '${json['senderNick'] ?? ''}',
        senderAvatar: '${json['senderAvatar'] ?? ''}',
        multiple: double.tryParse('${json['multiple']}') ?? 0,
        winAmount: _number(json['winAmount']),
      );
}

int _number(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
