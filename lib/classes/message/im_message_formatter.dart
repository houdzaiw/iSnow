import 'dart:convert';

import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import '../../model/im_conversation_preview.dart';
import '../../model/im_models.dart';

/// List-only summaries. Chat bubbles intentionally retain imMessagePreview.
ImConversationPreview imConversationPreview(
  V2TimConversation conversation, {
  required String languageCode,
  int? currentUid,
}) {
  final message = conversation.lastMessage;
  if (message == null) return _label('emptyPreview');
  final language = languageCode
      .toLowerCase()
      .replaceAll('_', '-')
      .split('-')
      .first;
  return switch (message.elemType) {
    MessageElemType.V2TIM_ELEM_TYPE_TEXT =>
      _previewText(message.textElem?.text) ?? _label('emptyPreview'),
    MessageElemType.V2TIM_ELEM_TYPE_CUSTOM => _conversationCustomPreview(
      message.customElem?.data,
      system: isImSystemUser(conversation.userID ?? ''),
      language: language,
      currentUid: currentUid,
    ),
    MessageElemType.V2TIM_ELEM_TYPE_IMAGE => _label('preview.image'),
    MessageElemType.V2TIM_ELEM_TYPE_SOUND => _label('preview.voice'),
    MessageElemType.V2TIM_ELEM_TYPE_VIDEO => _label('preview.video'),
    MessageElemType.V2TIM_ELEM_TYPE_FILE => _label('preview.file'),
    MessageElemType.V2TIM_ELEM_TYPE_FACE => _label('preview.emoji'),
    MessageElemType.V2TIM_ELEM_TYPE_LOCATION => _label('preview.location'),
    MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS ||
    MessageElemType.V2TIM_ELEM_TYPE_GROUP_REPORT => _label(
      'preview.groupNotice',
    ),
    MessageElemType.V2TIM_ELEM_TYPE_MERGER => _label('preview.history'),
    _ => _label('preview.unsupported'),
  };
}

ImConversationPreview _conversationCustomPreview(
  Object? raw, {
  required bool system,
  required String language,
  required int? currentUid,
}) {
  final fallback = _label(
    system ? 'preview.newMessage' : 'preview.unsupported',
  );
  final message = ImCustomMessageEnvelope.tryParse(raw);
  if (message == null) return fallback;
  final data = message.payload;
  if (message.type == 'TextIMMsg') {
    return data['text'] is String
        ? _previewText(data['text']) ?? _label('emptyPreview')
        : fallback;
  }
  if (system) return _systemPreview(message, language) ?? fallback;
  return switch (message.type) {
    'shareRoom' => _label('preview.shareRoom'),
    'shareParty' => _label('preview.shareParty'),
    'InvitationIMMsg' => _label('preview.whatsUp'),
    'transferAccounts' =>
      _localizedPreview(_titleFields(data), language) ??
          _label('preview.transfer'),
    'SystemComplexIMMsg' || 'InviteAcceptedPrivateComplexMsg' =>
      _localizedPreview(
            ImCustomMessageEnvelope.decodeMap(data['textMap']),
            language,
          ) ??
          fallback,
    'SystemSendGiftStore' => _giftPreview(data, currentUid),
    'TransferNoticeIMMsg' => switch (_intField(data['digitalCurrency'])) {
      3 => _label('preview.usdTransfer'),
      1 || 2 || 4 => _label('preview.coinTransfer'),
      _ => _label('preview.transfer'),
    },
    'ChannelSendsInviteIMMsg' || 'AgentSendsInviteIMMsg' => switch (_intField(
      data['type'],
    )) {
      1 => _label('preview.inviteAgent'),
      2 => _label('preview.inviteHost'),
      3 => _label('preview.inviteBd'),
      _ => _label('preview.invitation'),
    },
    'shareBanner' => _label('preview.message'),
    'shareOfficial' => _label('preview.official'),
    'shareWhatsapp' => _label('preview.whatsapp'),
    _ => fallback,
  };
}

ImConversationPreview? _systemPreview(
  ImCustomMessageEnvelope message,
  String language,
) {
  final data = message.payload;
  switch (message.type) {
    case 'purseTransferAccountsImMsg':
      return _localizedPreview(
            _titleFields(data, englishKey: 'title'),
            language,
          ) ??
          _label('preview.transfer');
    case 'transferAccounts':
      return _localizedPreview(_titleFields(data), language) ??
          _label('preview.transfer');
    case 'RewardPackSendIMMsg':
      return _localizedPreview({
            'en': data['enTitle'],
            'ar': data['arTitle'],
            'tr': data['trTitle'],
            'id': data['idTitle'],
          }, language) ??
          _label('preview.gift');
    case 'SystemComplexIMMsg':
    case 'InviteRelationshipSuccessMsg':
    case 'InviteSuccessRewardMsg':
      return _localizedPreview(
        ImCustomMessageEnvelope.decodeMap(data['titleMap']),
        language,
      );
    case 'Vip':
      return _localizedPreview(
            ImCustomMessageEnvelope.decodeMap(data['titleMap']),
            language,
          ) ??
          _label('preview.vip');
    case 'InviteActiveMsg':
      return _previewText(data['title']) ??
          _label(
            _intField(data['event']) == 1
                ? 'preview.releaseFriend'
                : 'preview.activateFriends',
          );
    case 'InvitationNoticeMsg':
      return switch (_intField(data['type'])) {
        1 => _label('preview.commented'),
        2 => _label('preview.replied'),
        3 => _label('preview.mentioned'),
        4 => _label('preview.liked'),
        _ => null,
      };
    default:
      return null;
  }
}

ImConversationPreview _giftPreview(Map<String, Object?> data, int? uid) {
  final target = _intField(data['targetUserId']);
  if (uid == null || uid <= 0 || target == null || target <= 0) {
    return _label('preview.gift');
  }
  return _label(uid == target ? 'preview.sentYou' : 'preview.youSent');
}

Map<String, Object?> _titleFields(
  Map<String, Object?> data, {
  String englishKey = 'titleEn',
}) => {
  'en': data[englishKey],
  'ar': data['titleAr'],
  'tr': data['titleTr'],
  'id': data['titleId'],
};

ImConversationPreview? _localizedPreview(
  Map<String, Object?>? values,
  String language,
) => _previewText(values?[language]) ?? _previewText(values?['en']);

final _previewWhitespace = RegExp(r'\s+');

ImConversationPreview? _previewText(Object? value) {
  if (value is! String) return null;
  final text = value.trim().replaceAll(_previewWhitespace, ' ');
  return text.isEmpty ? null : ImConversationPreview.text(text);
}

int? _intField(Object? value) => value is int
    ? value
    : value is String
    ? int.tryParse(value)
    : null;

ImConversationPreview _label(String suffix) =>
    ImConversationPreview.label('message.$suffix');

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
      _ => '[Custom message]',
    };
  } catch (_) {
    return '[Custom message]';
  }
}
