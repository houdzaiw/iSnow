import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import 'room_mention.dart';

/// Nady's generic public notice uses textMap for display and data for actions.
class RoomPublicNotice {
  const RoomPublicNotice(this.textMap);

  final Map<String, String> textMap;

  factory RoomPublicNotice.fromJson(Map<String, dynamic> json) {
    dynamic value = json['textMap'];
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        value = null;
      }
    }
    return RoomPublicNotice({
      if (value is Map)
        for (final entry in value.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
    });
  }

  String? text(String languageCode) {
    final language = languageCode.toLowerCase().split(RegExp('[-_]')).first;
    for (final key in [language, 'en']) {
      final value = textMap[key];
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }
}

/// Render server notice HTML as text and known room-user links only.
List<RoomMentionSegment> decodeRoomPublicNotice(String text) {
  if (!RegExp(r'<[a-zA-Z][^>]*>').hasMatch(text)) {
    return decodeRoomMentions(text);
  }
  final parts = <RoomMentionSegment>[];
  void append(String value, int? uid) {
    if (value.isEmpty) return;
    if (parts.isNotEmpty && parts.last.uid == uid) {
      final previous = parts.removeLast();
      parts.add(RoomMentionSegment('${previous.text}$value', uid: uid));
    } else {
      parts.add(RoomMentionSegment(value, uid: uid));
    }
  }

  void lineBreak() {
    if (parts.isNotEmpty && !parts.last.text.endsWith('\n')) {
      append('\n', null);
    }
  }

  void visit(dom.Node node, int? uid) {
    if (node is dom.Text) {
      append(node.data, uid);
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName;
    if (const {
      'script',
      'style',
      'iframe',
      'object',
      'noscript',
    }.contains(tag)) {
      return;
    }
    if (tag == 'br') {
      lineBreak();
      return;
    }
    final block = const {'p', 'div', 'li', 'ul', 'ol'}.contains(tag);
    if (block) lineBreak();
    var target = uid;
    if (tag == 'a') {
      target = _noticeUserUid(node.attributes['href']);
    }
    for (final child in node.nodes) {
      visit(child, target);
    }
    if (block) lineBreak();
  }

  for (final node in html.parseFragment(text).nodes) {
    visit(node, null);
  }
  while (parts.isNotEmpty) {
    final last = parts.removeLast();
    final value = last.text.trimRight();
    if (value.isNotEmpty) {
      parts.add(RoomMentionSegment(value, uid: last.uid));
      break;
    }
  }
  return parts;
}

int? _noticeUserUid(String? href) {
  try {
    final uri = Uri.parse(href ?? '');
    if (uri.scheme != 'nady' || uri.queryParameters['action'] != '1') {
      return null;
    }
    final uid = int.tryParse(uri.queryParameters['uid'] ?? '');
    return uid != null && uid > 0 ? uid : null;
  } on FormatException {
    return null;
  }
}
