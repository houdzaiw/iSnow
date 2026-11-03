import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import 'im_conversation_preview.dart';

enum SystemMessageActionKind { image, details }

enum SystemMessageDestination { image, web, wallet, room }

class SystemMessageAction {
  const SystemMessageAction(
    this.destination, {
    this.uri,
    this.roomId,
    this.title = '',
  });
  final SystemMessageDestination destination;
  final Uri? uri;
  final String? roomId;
  final String title;

  static SystemMessageAction? forLink(
    String raw, {
    required String language,
    required String title,
  }) {
    try {
      return _forLink(raw, language: language, title: title);
    } on FormatException {
      return null;
    }
  }

  static SystemMessageAction? _forLink(
    String raw, {
    required String language,
    required String title,
  }) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.userInfo.isNotEmpty) return null;
    if (httpImageUri(raw) != null) {
      return SystemMessageAction(
        SystemMessageDestination.web,
        title: title,
        uri: uri.replace(
          queryParameters: {
            ...uri.queryParametersAll,
            'language': [language],
          },
        ),
      );
    }
    if (uri.scheme != 'nady') return null;
    final page =
        uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? uri.host;
    if (page == 'me-wallet') {
      return const SystemMessageAction(SystemMessageDestination.wallet);
    }
    if (page == 'voice-room') {
      final id = uri.queryParameters['roomId']?.trim();
      if (id != null &&
          RegExp(r'^\d+$').hasMatch(id) &&
          (int.tryParse(id) ?? 0) > 0) {
        return SystemMessageAction(SystemMessageDestination.room, roomId: id);
      }
    }
    return null;
  }
}

class SystemMessageActionRequest {
  const SystemMessageActionRequest(this.action, this.generation);
  final SystemMessageAction action;
  final int generation;
}

class SystemMessageCardData {
  const SystemMessageCardData({
    required this.id,
    required this.supported,
    this.title = '',
    this.text = '',
    this.picture,
    this.linkUrl = '',
    this.event,
    this.time,
  });

  final String id, title, text, linkUrl;
  final bool supported;
  final Uri? picture;
  final int? event;
  final DateTime? time;

  factory SystemMessageCardData.fromMessage(
    V2TimMessage message, {
    required String id,
    required String languageCode,
  }) {
    final envelope = message.elemType == MessageElemType.V2TIM_ELEM_TYPE_CUSTOM
        ? ImCustomMessageEnvelope.tryParse(message.customElem?.data)
        : null;
    final time = _time(envelope?.timestamp) ?? _sdkTime(message.timestamp);
    if (message.elemType == MessageElemType.V2TIM_ELEM_TYPE_TEXT) {
      final text = _text(message.textElem?.text);
      return SystemMessageCardData(
        id: id,
        supported: text.isNotEmpty,
        text: text,
        time: time,
      );
    }
    if (envelope?.type != 'SystemComplexIMMsg') {
      return SystemMessageCardData(id: id, supported: false, time: time);
    }
    final data = envelope!.payload;
    final language = languageCode
        .toLowerCase()
        .replaceAll('_', '-')
        .split('-')
        .first;
    final title = _localized(data['titleMap'], language);
    final text = _localized(data['textMap'], language);
    final picture = httpImageUri(_text(data['picUrl']));
    return SystemMessageCardData(
      id: id,
      time: time,
      title: title,
      text: text,
      picture: picture,
      linkUrl: _text(data['linkUrl']),
      event: data['event'] is int ? data['event'] as int : null,
      supported: title.isNotEmpty || text.isNotEmpty || picture != null,
    );
  }

  SystemMessageAction? details(String language) => supported
      ? SystemMessageAction.forLink(linkUrl, language: language, title: title)
      : null;
}

Uri? httpImageUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}

String _text(Object? raw) => raw is String ? raw.trim() : '';
String _localized(Object? raw, String language) {
  final data = ImCustomMessageEnvelope.decodeMap(raw);
  final local = _text(data?[language]);
  return local.isNotEmpty ? local : _text(data?['en']);
}

const _maximumDateMilliseconds = 8640000000000000;
DateTime? _time(int? value) =>
    value == null || value <= 0 || value > _maximumDateMilliseconds
    ? null
    : _date(value < 10000000000 ? value * 1000 : value);
DateTime? _sdkTime(int? value) =>
    value == null || value <= 0 || value > _maximumDateMilliseconds ~/ 1000
    ? null
    : _date(value * 1000);
DateTime? _date(int milliseconds) {
  try {
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  } on RangeError {
    return null;
  }
}
