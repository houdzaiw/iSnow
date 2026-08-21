class RoomSocketMessage {
  const RoomSocketMessage({
    required this.channel,
    required this.event,
    required this.raw,
    this.payload,
    this.timestamp,
    this.toType,
    this.ids,
    this.msgId,
    this.from,
  });

  final String channel;
  final String event;
  final Object? payload;
  final int? timestamp;
  final String? toType;
  final List<String>? ids;
  final String? msgId;
  final String? from;
  final Map<String, dynamic> raw;

  factory RoomSocketMessage.fromJson(
    Map<String, dynamic> json, {
    required String channel,
  }) {
    return RoomSocketMessage(
      channel: channel,
      event: json['event']?.toString() ?? '',
      payload: json['payload'],
      timestamp: _asInt(json['timestamp']),
      toType: json['toType']?.toString(),
      ids: _asStringList(json['ids']),
      msgId: json['msgId']?.toString(),
      from: json['from']?.toString(),
      raw: json,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<String>? _asStringList(Object? value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }
}
