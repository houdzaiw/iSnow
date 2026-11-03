import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';

import 'package:project/classes/message/im_message_formatter.dart';
import 'package:project/localization/app_localizations.dart';
import 'package:project/model/im_conversation_preview.dart';

import 'support/im_fakes.dart';
import 'support/im_preview_samples.dart';

V2TimConversation _custom(
  String type,
  Map<String, Object?> payload, {
  String uid = '20',
  bool stringPayload = false,
}) => imConversation(uid)
  ..lastMessage = imCustom(
    {'type': type, 'payload': payload},
    uid: uid,
    payloadAsString: stringPayload,
  );

String _render(
  V2TimConversation conversation, {
  String language = 'en',
  int? uid = 10,
}) {
  final preview = imConversationPreview(
    conversation,
    languageCode: language,
    currentUid: uid,
  );
  return preview.text ??
      AppLocalizations(Locale(language)).t(preview.localizationKey!);
}

void main() {
  for (final stringPayload in [false, true]) {
    for (final (index, sample) in imOrdinaryPreviewSamples.indexed) {
      test('ordinary $index ${sample.type}, string payload $stringPayload', () {
        expect(
          _render(
            _custom(sample.type, sample.payload, stringPayload: stringPayload),
          ),
          sample.expected,
        );
      });
    }
    for (final (index, sample) in imSystemPreviewSamples.indexed) {
      test('system $index ${sample.type}, string payload $stringPayload', () {
        expect(
          _render(
            _custom(
              sample.type,
              sample.payload,
              uid: '10000',
              stringPayload: stringPayload,
            ),
          ),
          sample.expected,
        );
      });
    }
  }

  for (final uid in ['10000', '10001', '10002', '10003']) {
    test('system identity $uid selects title rather than text', () {
      expect(
        _render(
          _custom('SystemComplexIMMsg', {
            'titleMap': {'en': 'Notice title'},
            'textMap': {'en': 'Notice body'},
          }, uid: uid),
        ),
        'Notice title',
      );
    });
  }

  for (final sample in [
    (language: 'en', expected: 'English'),
    (language: 'zh', expected: '中文标题'),
    (language: 'ar', expected: 'رسالة'),
    (language: 'tr', expected: 'Bildirim'),
    (language: 'id', expected: 'Pesan'),
    (language: 'fr', expected: 'English'),
    (language: 'ZH_CN', expected: '中文标题'),
  ]) {
    test(
      'server languages select ${sample.language} with English fallback',
      () {
        final preview = imConversationPreview(
          _custom('Vip', {
            'titleMap': {
              'en': 'English',
              'zh': '中文标题',
              'ar': 'رسالة',
              'tr': 'Bildirim',
              'id': 'Pesan',
            },
          }, uid: '10000'),
          languageCode: sample.language,
        );
        expect(preview.text, sample.expected);
      },
    );
  }

  test('flat transfer and reward titles use Nady field names', () {
    expect(
      _render(
        _custom('transferAccounts', {'titleEn': 'English', 'titleAr': 'تحويل'}),
        language: 'ar',
      ),
      'تحويل',
    );
    expect(
      _render(
        _custom('purseTransferAccountsImMsg', {
          'title': 'Wallet',
          'titleTr': 'Cüzdan',
        }, uid: '10001'),
        language: 'tr',
      ),
      'Cüzdan',
    );
    expect(
      _render(
        _custom('RewardPackSendIMMsg', {
          'enTitle': 'Reward',
          'idTitle': 'Hadiah',
        }, uid: '10000'),
        language: 'id',
      ),
      'Hadiah',
    );
  });

  test(
    'empty or mistyped translations fall back to English, then safe labels',
    () {
      expect(
        _render(
          _custom('Vip', {
            'titleMap': {'en': 'English', 'zh': '  '},
          }, uid: '10000'),
          language: 'zh',
        ),
        'English',
      );
      expect(
        _render(
          _custom('Vip', {
            'titleMap': {
              'en': 'English',
              'zh': {'secret': 'hidden'},
            },
          }, uid: '10000'),
          language: 'zh',
        ),
        'English',
      );
      expect(
        _render(_custom('Vip', {'titleMap': {}}, uid: '10000'), language: 'zh'),
        'VIP 通知',
      );
      expect(
        _render(
          _custom('SystemComplexIMMsg', {
            'textMap': {'en': 'Not a title'},
          }, uid: '10000'),
          language: 'zh',
        ),
        '你有一条新消息',
      );
    },
  );

  test('gift direction requires the active UID and a valid target', () {
    expect(
      _render(_custom('SystemSendGiftStore', {'targetUserId': 10}), uid: null),
      '[Gift]',
    );
    expect(
      _render(_custom('SystemSendGiftStore', {'targetUserId': {}})),
      '[Gift]',
    );
    expect(
      _render(_custom('SystemSendGiftStore', {'targetUserId': 10}), uid: 20),
      'You sent',
    );
    expect(
      _render(
        _custom('SystemSendGiftStore', {'targetUserId': 10}),
        language: 'zh',
      ),
      '送给你',
    );
  });

  for (final raw in [
    null,
    '',
    '{bad json',
    '[]',
    'true',
    '"text"',
    {'type': 42, 'payload': {}},
    {
      'type': 'UnknownType',
      'payload': {'secret': 'never show'},
    },
    {'type': 'TextIMMsg', 'payload': 'invalid json'},
    {
      'type': 'TextIMMsg',
      'payload': {
        'text': {'private': 'not text'},
      },
    },
  ]) {
    test('invalid or unsupported custom data stays private: $raw', () {
      for (final uid in ['20', '10000']) {
        final c = imConversation(uid)..lastMessage = imCustom(raw, uid: uid);
        expect(
          _render(c),
          uid == '20' ? '[Unsupported message]' : 'You have a new message',
        );
      }
    });
  }

  test('only genuinely absent or empty text uses the empty preview label', () {
    expect(
      _render(imConversation('20')..lastMessage = null),
      'No message content',
    );
    expect(
      _render(_custom('TextIMMsg', {'text': '  \n '})),
      'No message content',
    );
    final c = imConversation('20');
    c.lastMessage!.textElem!.text = '';
    expect(_render(c), 'No message content');
  });

  for (final (type, label) in [
    (3, '[Image]'),
    (4, '[Voice]'),
    (5, '[Video]'),
    (6, '[File]'),
    (7, '[Location]'),
    (8, '[Emoji]'),
    (9, '[Group notification]'),
    (10, '[Chat history]'),
    (11, '[Group notification]'),
    (999, '[Unsupported message]'),
  ]) {
    test(
      'native message type $type has a meaningful summary without textElem',
      () {
        final c = imConversation('20');
        c.lastMessage!
          ..elemType = type
          ..textElem = null;
        expect(_render(c), label);
      },
    );
  }

  test('native text normalizes only the summary, not the SDK message', () {
    final c = imConversation('20');
    c.lastMessage!.textElem!.text = '  Hello\n\tworld 👋  ';
    expect(_render(c), 'Hello world 👋');
    expect(c.lastMessage!.textElem!.text, '  Hello\n\tworld 👋  ');
    expect(imMessagePreview(c.lastMessage), 'Hello\n\tworld 👋');
  });

  test('the legacy bubble formatter keeps its original output', () {
    expect(
      imMessagePreview(_custom('shareRoom', {}).lastMessage),
      '[Share Room]',
    );
    expect(
      imMessagePreview(
        _custom('transferAccounts', {'titleEn': 'Transfer title'}).lastMessage,
      ),
      '[Transfer]',
    );
    expect(
      imMessagePreview(
        _custom('SystemComplexIMMsg', {
          'titleMap': {'en': 'Notice'},
        }).lastMessage,
      ),
      '[Custom message]',
    );
    expect(
      imMessagePreview(
        _custom('TextIMMsg', {
          'text': 'Old body',
        }, stringPayload: true).lastMessage,
      ),
      'Old body',
    );
    expect(
      imMessagePreview(_custom('TextIMMsg', {'text': 'Map body'}).lastMessage),
      '[Custom message]',
    );
  });

  test('envelope accepts Map or JSON at each protocol layer', () {
    for (final outerString in [false, true]) {
      for (final innerString in [false, true]) {
        final data = {
          'type': 'TextIMMsg',
          'payload': innerString
              ? jsonEncode({'text': 'hello'})
              : {'text': 'hello'},
        };
        final model = ImCustomMessageEnvelope.tryParse(
          outerString ? jsonEncode(data) : data,
        )!;
        expect(model.type, 'TextIMMsg');
        expect(model.payload['text'], 'hello');
      }
    }
    expect(ImCustomMessageEnvelope.tryParse({1: 'invalid'}), isNull);
  });
}
