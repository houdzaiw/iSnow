import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/lucky_box/room_lucky_box_models.dart';

void main() {
  RoomLuckyBoxConfig config(String en, {String ar = ''}) =>
      RoomLuckyBoxConfig.fromJson({'rulesUrlEn': en, 'rulesUrlAr': ar});

  for (final extension in ['jpg', 'JPEG', 'png', 'webp', 'gif']) {
    test('recognizes $extension rules with encoded query parameters', () {
      final value = config('https://example.com/rules.$extension?token=a%2Fb');
      expect(value.rulesAreImage('en'), isTrue);
      expect(value.rules('en'), contains('token=a%2Fb'));
    });
  }

  test('HTML rules keep the web destination', () {
    expect(
      config('https://example.com/rules.html').rulesAreImage('en'),
      isFalse,
    );
    expect(
      config('https://example.com/rules?pic=x.jpg').rulesAreImage('en'),
      isFalse,
    );
  });

  test('language fallback selects and classifies the same resource', () {
    final value = config(
      'https://example.com/en.jpg',
      ar: 'https://example.com/ar.html',
    );
    expect(value.rulesAreImage('ar'), isFalse);
    expect(value.rulesAreImage('zh'), isTrue);
    expect(config('https://example.com/en.jpg').rulesAreImage('ar'), isTrue);
  });

  test('unsupported URLs cannot become image rules', () {
    for (final url in [
      '',
      'file:///rules.jpg',
      'https://user:password@example.com/rules.jpg',
    ]) {
      expect(config(url).rules('en'), isEmpty);
      expect(config(url).rulesAreImage('en'), isFalse);
    }
  });
}
