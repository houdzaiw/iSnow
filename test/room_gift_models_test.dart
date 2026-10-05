import 'package:flutter_test/flutter_test.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';

void main() {
  group('RoomGift', () {
    test('parses Nady gift fields and configured counts', () {
      final gift = RoomGift.fromJson({
        'id': 31,
        'name': 'Rose',
        'icon': 'https://example.com/rose.webp',
        'price': 20,
        'isCombo': 1,
        'tabId': 8,
        'defaultGiftNum': 8,
        'defaultGiftNumConfig': '1, 8,18, 888',
        'banner': 'https://example.com/campaign.png',
        'jumpLink': 'https://example.com/campaign',
      }, fallbackTabId: 0);

      expect(gift.id, 31);
      expect(gift.tabId, 8);
      expect(gift.defaultGiftNum, 8);
      expect(gift.countOptions, [1, 8, 18, 888]);
      expect(gift.isBackpack, isFalse);
      expect(gift.banner, 'https://example.com/campaign.png');
      expect(gift.copyWith(amount: 8).banner, gift.banner);
      expect(gift.copyWith(amount: 8).jumpLink, gift.jumpLink);
    });

    test('falls back to a valid default quantity', () {
      final gift = RoomGift.fromJson({
        'id': 1,
        'name': 'Star',
        'icon': '',
        'price': 1,
        'isCombo': 0,
        'defaultGiftNum': 0,
      }, fallbackTabId: 9);

      expect(gift.defaultGiftNum, 1);
      expect(gift.countOptions, [1, 8, 18, 888]);
    });

    test(
      'campaign links preserve existing parameters and reject non-web URLs',
      () {
        final gift = RoomGift.fromJson({
          'id': 1,
          'jumpLink':
              'https://example.com/campaign?scene=room&language=en#gift',
        }, fallbackTabId: 8);
        final uri = Uri.parse(gift.resolvedCampaignUrl('zh'));
        expect(uri.queryParameters, {'scene': 'room', 'language': 'zh'});
        expect(uri.fragment, 'gift');
        final invalid = RoomGift.fromJson({
          'id': 1,
          'jumpLink': 'javascript:alert(1)',
        }, fallbackTabId: 8);
        expect(invalid.resolvedCampaignUrl('en'), isEmpty);
      },
    );
  });

  test('SendRoomGiftRequest matches the Nady API contract', () {
    const request = SendRoomGiftRequest(
      targetUids: [1001, 1002],
      sendType: RoomGiftSendType.multi,
      roomId: '20001',
      giftId: 31,
      giftCount: 8,
      giftSource: 2,
      comboId: '',
      comboCount: 1,
      price: 20,
      userBackpackId: 99,
    );

    expect(request.toJson(), {
      'targetUids': [1001, 1002],
      'sendType': 6,
      'roomId': '20001',
      'giftId': 31,
      'giftCount': 8,
      'giftSource': 2,
      'comboId': '',
      'comboCount': 1,
      'price': 20,
      'userBackpackId': 99,
    });
  });
}
