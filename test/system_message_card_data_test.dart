import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/model/im_conversation_preview.dart';
import 'package:project/model/system_message_card_data.dart';

import 'support/im_fakes.dart';
import 'support/system_message_fixture.dart';

void main() {
  SystemMessageCardData card(
    Map<String, Object?> payload, {
    String language = 'en',
    Object? time = 1700000000,
  }) => SystemMessageCardData.fromMessage(
    systemNotice('notice', payload: payload, timestamp: time),
    id: 'notice',
    languageCode: language,
  );

  test('envelope accepts outer and payload maps or JSON with timestamp', () {
    for (final outer in [false, true]) {
      for (final inner in [false, true]) {
        final payload = {
          'textMap': {'en': 'First\n\nSecond'},
        };
        final raw = {
          'type': 'SystemComplexIMMsg',
          'timestamp': '1700000000',
          'payload': inner ? jsonEncode(payload) : payload,
        };
        final envelope = ImCustomMessageEnvelope.tryParse(
          outer ? jsonEncode(raw) : raw,
        )!;
        expect(envelope.timestamp, 1700000000);
        expect(envelope.payload, payload);
      }
    }
  });

  for (final combination in ['text', 'image', 'both']) {
    test('$combination uses only generic content and preserves paragraphs', () {
      final data = card({
        if (combination != 'image') ...{
          'titleMap': {'en': 'Title'},
          'textMap': {'en': ' First line\n\nSecond line '},
        },
        if (combination != 'text') 'picUrl': 'https://example.test/image.png',
        'event': 2,
        'eventPayload': 'malformed activity data',
        'list': ['secret'],
      });
      expect(data.supported, isTrue);
      expect(data.picture != null, combination != 'text');
      expect(
        data.text,
        combination != 'image' ? 'First line\n\nSecond line' : '',
      );
      expect(data.event, 2);
    });
  }

  test('native text remains readable and unknown types are safe', () {
    final text = imText('native', uid: '10000')
      ..textElem!.text = 'Native\nbody';
    expect(
      SystemMessageCardData.fromMessage(
        text,
        id: 'native',
        languageCode: 'en',
      ).text,
      'Native\nbody',
    );
    for (final raw in [
      '{broken',
      jsonEncode({
        'type': 'Unknown',
        'payload': {
          'titleMap': {'en': 'Secret'},
          'desc': 'raw',
        },
      }),
    ]) {
      final data = SystemMessageCardData.fromMessage(
        imCustom(raw),
        id: 'x',
        languageCode: 'en',
      );
      expect(data.supported, isFalse);
      expect(data.title, isEmpty);
      expect(data.text, isEmpty);
      expect(data.details('en'), isNull);
    }
    expect(
      card({'titleMap': 12, 'textMap': [], 'picUrl': 99}).supported,
      isFalse,
    );
    expect(
      card({
        'eventPayload': jsonEncode({
          'titleMap': {'en': 'Hidden'},
        }),
      }).supported,
      isFalse,
    );
  });

  test('language uses current language then English without flattening', () {
    final payload = {
      'titleMap': {'en': 'English', 'zh': '中文'},
      'textMap': jsonEncode({'en': 'One\nTwo', 'zh': '第一行\n第二行'}),
    };
    expect(card(payload, language: 'zh_CN').title, '中文');
    expect(card(payload, language: 'zh-CN').text, '第一行\n第二行');
    expect(card(payload, language: 'tr').text, 'One\nTwo');
    expect(
      card({
        'titleMap': {'zh': '中文'},
      }, language: 'tr').supported,
      isFalse,
    );
  });

  for (final time in [1700000000, 1700000000000, '1700000000000']) {
    test('custom time $time is preferred over SDK time', () {
      final data = card({
        'textMap': {'en': 'Notice'},
      }, time: time);
      expect(data.time!.millisecondsSinceEpoch, 1700000000000);
    });
  }

  test('invalid custom time falls back; absent or overflowing times hide', () {
    for (final time in [null, -1, 0, 'broken', 9223372036854775807]) {
      expect(card({}, time: time).time!.millisecondsSinceEpoch, 1700000000000);
      final message = systemNotice('x', timestamp: time)..timestamp = 0;
      expect(
        SystemMessageCardData.fromMessage(
          message,
          id: 'x',
          languageCode: 'en',
        ).time,
        isNull,
      );
    }
    final message = systemNotice('x', timestamp: null)
      ..timestamp = 9223372036854775807;
    expect(
      SystemMessageCardData.fromMessage(
        message,
        id: 'x',
        languageCode: 'en',
      ).time,
      isNull,
    );
  });

  test('web link merges language without losing query arrays or fragment', () {
    final action = SystemMessageAction.forLink(
      'https://example.test/path?q=a%26b&x=1&x=2&language=ar#section',
      language: 'zh',
      title: 'Title',
    )!;
    expect(action.destination, SystemMessageDestination.web);
    expect(action.uri!.queryParametersAll, {
      'q': ['a&b'],
      'x': ['1', '2'],
      'language': ['zh'],
    });
    expect(action.uri!.fragment, 'section');
    expect(action.title, 'Title');
  });

  test(
    'only known native destinations and positive numeric room IDs execute',
    () {
      expect(
        SystemMessageAction.forLink(
          'nady://main/me-wallet',
          language: 'en',
          title: '',
        )!.destination,
        SystemMessageDestination.wallet,
      );
      final room = SystemMessageAction.forLink(
        'nady://main/voice-room?roomId=123',
        language: 'en',
        title: '',
      )!;
      expect(room.destination, SystemMessageDestination.room);
      expect(room.roomId, '123');
      for (final link in [
        '',
        'nady://main/unknown',
        'nady://main/voice-room',
        'nady://main/voice-room?roomId=0',
        'nady://main/voice-room?roomId=-1',
        'nady://main/voice-room?roomId=x',
        'javascript:alert(1)',
        'file:///test',
        '//example.test',
        'https://',
        'https://user:secret@example.test',
      ]) {
        expect(
          SystemMessageAction.forLink(link, language: 'en', title: ''),
          isNull,
          reason: link,
        );
      }
      for (final url in [
        'javascript:x',
        'file:///image',
        '',
        'https://u:p@example.test/image',
      ]) {
        expect(httpImageUri(url), isNull);
      }
      expect(httpImageUri('http://example.test/image'), isNotNull);
      expect(
        card({
          'textMap': {'en': 'Notice'},
          'linkUrl': 'nady://main/unknown',
        }).details('en'),
        isNull,
      );
    },
  );
}
