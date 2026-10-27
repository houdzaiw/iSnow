import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/room_share_manager.dart';
import 'package:project/model/room_share_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  final manager = RoomShareManager();
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('clipboard is delegated to the existing platform channel', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      received = call;
      return null;
    });
    await manager.copyText('Invitation https://share.example/s/abc');
    expect(received?.method, 'Clipboard.setData');
    expect(received?.arguments, {
      'text': 'Invitation https://share.example/s/abc',
    });
  });

  for (final (raw, outcome) in [
    ('chosen.app', RoomShareOutcome.shared),
    ('', RoomShareOutcome.cancelled),
    (
      'dev.fluttercommunity.plus/share/unavailable',
      RoomShareOutcome.unavailable,
    ),
  ]) {
    test('system sharing maps $outcome and forwards the iPad origin', () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return raw;
      });
      final result = await manager.shareText(
        text: 'Invitation',
        origin: const Rect.fromLTWH(10, 20, 30, 40),
      );
      expect(result, outcome);
      expect(received?.method, 'share');
      expect(received?.arguments, {
        'text': 'Invitation',
        'originX': 10.0,
        'originY': 20.0,
        'originWidth': 30.0,
        'originHeight': 40.0,
      });
    });
  }

  test('invalid anchors fail before invoking the native sheet', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return '';
    });
    await expectLater(
      manager.shareText(text: 'Invitation', origin: Rect.zero),
      throwsArgumentError,
    );
    expect(calls, 0);
  });

  for (final (action, scheme, key, useLink) in [
    (RoomShareAction.whatsapp, 'whatsapp', 'text', false),
    (RoomShareAction.facebook, 'https', 'u', true),
    (RoomShareAction.snapchat, 'snapchat', 'text', false),
    (RoomShareAction.telegram, 'tg', 'url', true),
    (RoomShareAction.messenger, 'fb-messenger', 'link', true),
    (RoomShareAction.x, 'twitter', 'message', false),
    (RoomShareAction.instagram, 'instagram', 'text', false),
    (RoomShareAction.contacts, 'sms', 'body', false),
  ]) {
    test(
      '$action uses the Nady route and safely encodes its content',
      () async {
        Uri? received;
        final direct = RoomShareManager(
          launch: (uri) async {
            received = uri;
            return true;
          },
        );
        final content = RoomShareContent(
          description: 'A & B / 中文 + #invite',
          link: Uri.parse('https://share.example/s/abc?keep=a%26b'),
        );
        expect(await direct.openChannel(action, content), isTrue);
        expect(received?.scheme, scheme);
        expect(
          received?.queryParameters[key],
          useLink ? content.link.toString() : content.text,
        );
        if (action == RoomShareAction.telegram) {
          expect(received?.queryParameters['text'], content.description);
        }
        if (action == RoomShareAction.facebook) {
          expect(received?.host, 'www.facebook.com');
          expect(received?.path, '/sharer/sharer.php');
        }
      },
    );
  }

  test(
    'unavailable and exceptional channels do not invoke system fallback',
    () async {
      final content = RoomShareContent(
        description: 'Join',
        link: Uri.parse('https://share.example'),
      );
      for (final throws in [false, true]) {
        var calls = 0;
        final direct = RoomShareManager(
          launch: (_) async {
            calls++;
            if (throws) throw PlatformException(code: 'unavailable');
            return false;
          },
        );
        expect(
          await direct.openChannel(RoomShareAction.instagram, content),
          isFalse,
        );
        expect(calls, 1);
      }
    },
  );
}
