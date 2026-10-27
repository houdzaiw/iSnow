import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/room_share_models.dart';

final roomShareManagerProvider = Provider((ref) => RoomShareManager());

/// Only platform operations live here; no room state, HTTP, or navigation.
class RoomShareManager {
  RoomShareManager({Future<bool> Function(Uri)? launch})
    : _launch = launch ?? _launchExternal;

  final Future<bool> Function(Uri) _launch;

  static Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Opening an application is not confirmation that it accepted the content.
  Future<bool> openChannel(
    RoomShareAction action,
    RoomShareContent content,
  ) async {
    final text = Uri.encodeComponent(content.text);
    final link = Uri.encodeComponent(content.link.toString());
    final description = Uri.encodeComponent(content.description);
    final target = switch (action) {
      RoomShareAction.whatsapp => 'whatsapp://send?text=$text',
      RoomShareAction.facebook =>
        'https://www.facebook.com/sharer/sharer.php?u=$link',
      RoomShareAction.snapchat => 'snapchat://share?text=$text',
      RoomShareAction.telegram => 'tg://msg_url?url=$link&text=$description',
      RoomShareAction.messenger => 'fb-messenger://share/?link=$link',
      RoomShareAction.x => 'twitter://post?message=$text',
      RoomShareAction.instagram => 'instagram://sharesheet?text=$text',
      RoomShareAction.contacts => 'sms:?body=$text',
      _ => throw ArgumentError.value(action, 'action', 'Not a direct channel'),
    };
    try {
      return await _launch(Uri.parse(target));
    } on Exception {
      return false;
    }
  }

  Future<RoomShareOutcome> shareText({
    required String text,
    required Rect origin,
  }) async {
    if (origin.isEmpty || !origin.isFinite) {
      throw ArgumentError.value(origin, 'origin', 'Invalid share anchor');
    }
    final result = await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
    return switch (result.status) {
      ShareResultStatus.success => RoomShareOutcome.shared,
      ShareResultStatus.dismissed => RoomShareOutcome.cancelled,
      ShareResultStatus.unavailable => RoomShareOutcome.unavailable,
    };
  }
}
