import 'dart:convert';

import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

String imMessagePreview(V2TimMessage? message) {
  if (message == null) return '';

  return switch (message.elemType) {
    MessageElemType.V2TIM_ELEM_TYPE_TEXT =>
      message.textElem?.text?.trim() ?? '',
    MessageElemType.V2TIM_ELEM_TYPE_IMAGE => '[Image]',
    MessageElemType.V2TIM_ELEM_TYPE_SOUND => '[Voice]',
    MessageElemType.V2TIM_ELEM_TYPE_VIDEO => '[Video]',
    MessageElemType.V2TIM_ELEM_TYPE_FILE => '[File]',
    MessageElemType.V2TIM_ELEM_TYPE_FACE => '[Emoji]',
    MessageElemType.V2TIM_ELEM_TYPE_CUSTOM => _customMessagePreview(
      message.customElem?.data,
    ),
    _ => '',
  };
}

DateTime imMessageTime(V2TimMessage? message) {
  final timestamp = message?.timestamp;
  if (timestamp == null || timestamp <= 0) return DateTime.now();
  return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

String _customMessagePreview(String? rawData) {
  if (rawData == null || rawData.trim().isEmpty) return '[Custom message]';

  try {
    final json = jsonDecode(rawData);
    if (json is! Map) return '[Custom message]';

    final type = json['type']?.toString();
    final payload = json['payload']?.toString();

    if (type == 'TextIMMsg' && payload != null) {
      final payloadJson = jsonDecode(payload);
      if (payloadJson is Map) {
        final text = payloadJson['text']?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }

    return switch (type) {
      'shareRoom' => '[Share Room]',
      'shareParty' => '[Room Party]',
      'transferAccounts' => '[Transfer]',
      'SystemSendGiftStore' => '[Gift]',
      'InvitationIMMsg' => '[Invitation]',
      _ => json['desc']?.toString() ?? '[Custom message]',
    };
  } catch (_) {
    return '[Custom message]';
  }
}
