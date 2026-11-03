import 'dart:convert';

/// A list preview is either server text or a localized application label.
class ImConversationPreview {
  const ImConversationPreview.text(String value)
    : text = value,
      localizationKey = null;

  const ImConversationPreview.label(String key)
    : text = null,
      localizationKey = key;

  final String? text;
  final String? localizationKey;
}

class ImCustomMessageEnvelope {
  const ImCustomMessageEnvelope({
    required this.type,
    required this.payload,
    this.timestamp,
  });

  final String type;
  final Map<String, Object?> payload;
  final int? timestamp;

  static ImCustomMessageEnvelope? tryParse(Object? raw) {
    final data = decodeMap(raw);
    final type = data?['type'];
    if (type is! String || type.trim().isEmpty) return null;
    return ImCustomMessageEnvelope(
      type: type,
      payload: decodeMap(data?['payload']) ?? const {},
      timestamp: data?['timestamp'] is int
          ? data!['timestamp'] as int
          : int.tryParse('${data?['timestamp']}'),
    );
  }

  static Map<String, Object?>? decodeMap(Object? value) {
    try {
      final decoded = value is String ? jsonDecode(value) : value;
      if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
        return null;
      }
      return decoded.cast<String, Object?>();
    } on FormatException {
      return null;
    }
  }
}
