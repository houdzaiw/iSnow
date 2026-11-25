import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/profile/membership/membership_models.dart';

void main() {
  const icon = 'https://current.example.test/vip/icon.png';
  const stale = 'https://legacy.example.test/vip/preview.png';

  VipMembershipLevel level(String preview, {String iconUrl = icon}) =>
      VipMembershipLevel.fromJson({'iconUrl': iconUrl, 'showIconUrl': preview});

  test('static VIP preview uses the Nady icon field and retains raw URLs', () {
    final value = level(stale);
    expect(value.previewSource, icon);
    expect(value.preview, stale);
    expect(value.icon, icon);
  });

  for (final extension in ['MP4', 'vap', 'pag', 'svga']) {
    test('animated VIP preview keeps .$extension URL including query', () {
      final source = 'https://example.test/preview.$extension?version=2';
      expect(level(source).previewSource, source);
    });
  }

  test('missing tier icon falls back to the provided static preview', () {
    expect(level(stale, iconUrl: '').previewSource, stale);
  });

  test('missing preview preserves the existing hidden preview area', () {
    expect(level('').previewSource, isEmpty);
    expect(level('', iconUrl: '').previewSource, isEmpty);
  });
}
