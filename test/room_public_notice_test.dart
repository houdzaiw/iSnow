import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/interaction/room_public_notice.dart';

void main() {
  test('real PK HTML becomes text with a room-user target', () {
    final parts = decodeRoomPublicNotice(
      '<p><a href="nady://?action=1&amp;uid=12594212" '
      'style="text-decoration: none;"><span '
      'style="color: rgba(23, 235, 173, 1);">lihei</span></a>'
      ' turned on the 1V1 PK for 3 minutes</p>',
    );
    expect(
      parts.map((p) => p.text).join(),
      'lihei turned on the 1V1 PK for 3 minutes',
    );
    expect(parts.singleWhere((p) => p.uid != null).uid, 12594212);
  });

  test('notice HTML preserves paragraphs and decodes entities', () {
    final parts = decodeRoomPublicNotice(
      '<p>A &amp; B<br>Second</p><p>第三段</p>',
    );
    expect(parts.map((p) => p.text).join(), 'A & B\nSecond\n第三段');
  });

  for (final href in [
    'javascript:alert(1)',
    'https://example.com/?action=1&uid=10',
    'nady://?action=2&uid=10',
    'nady://?action=1&uid=-1',
    'nady://?action=1&uid=bad',
    'nady://?action=%GG&uid=10',
  ]) {
    test('unsupported notice link stays text: $href', () {
      final parts = decodeRoomPublicNotice('<p><a href="$href">User</a></p>');
      expect(parts.map((p) => p.text).join(), 'User');
      expect(parts.every((p) => p.uid == null), isTrue);
    });
  }

  test('script/style and remote images are not rendered or loaded', () {
    final parts = decodeRoomPublicNotice(
      '<script>secret()</script><style>.hidden{}</style><p>Safe'
      '<img src="https://example.com/image.png"></p>',
    );
    expect(parts.map((p) => p.text).join(), 'Safe');
  });

  test('plain notices keep existing mention decoding and literal text', () {
    final parts = decodeRoomPublicNotice('Coins < 2');
    expect(parts.single.text, 'Coins < 2');
  });

  test('generic notice reads translated text, never business data', () {
    final notice = RoomPublicNotice.fromJson({
      'event': 1,
      'textMap': {'en': 'PK started', 'ar': 'بدأ التحدي'},
      'data': {'pkId': 'private-business-id'},
    });
    expect(notice.text('ar-SA'), 'بدأ التحدي');
    expect(notice.text('zh'), 'PK started');
  });

  test('JSON textMap preserves paragraphs and falls back from blank text', () {
    final notice = RoomPublicNotice.fromJson({
      'textMap': '{"en":"First\\nSecond","ar":" "}',
    });
    expect(notice.text('ar'), 'First\nSecond');
  });

  for (final textMap in [
    null,
    '{broken',
    <String, dynamic>{'en': 12},
  ]) {
    test('missing or invalid textMap does not expose raw data: $textMap', () {
      expect(
        RoomPublicNotice.fromJson({
          'textMap': textMap,
          'data': {'pkId': 'business-id'},
          'text': 'Not part of the generic notice protocol',
        }).text('en'),
        isNull,
      );
    });
  }
}
