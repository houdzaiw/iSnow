import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../model/room_socket_message.dart';
import '../../../theme/app_theme.dart';
import '../gift/models/room_gift_effect_task.dart';
import '../gift/models/room_gift_event_models.dart';
import '../gift/models/room_gift_models.dart';
import '../gift/models/room_gift_panel_models.dart';
import 'room_barrage_models.dart';

class RoomBarrageParser {
  static const events = {
    'RoomGiftSendBannerEvent',
    'RoomLuckGiftSendBannerEvent',
    'RegularJoyBannerEffectEvent',
    'RoomGameFloatScreenEvent',
    'GlobalAristocracyOnlineEvent',
    'RoomAristocracyUpgradeEvent',
    'RoomResourceFloatScreenEvent',
    'WorldLuckyBagEvent',
    'RoomBigRocketPrizeEvent',
    'LuckyGiftJackpotSuperMode',
    'RoomLobbyBigWinStatusEvent',
    'RoomLobbyBigWinPrizeEvent',
  };
  RoomBarrageTask? parse(
    RoomSocketMessage event, {
    required DateTime now,
    required int uid,
    String? currentRoomId,
    String? countryCode,
    RoomScreenGiftMsg? Function(int)? activeJackpotGift,
  }) {
    if (!events.contains(event.event)) return null;
    if (!{
      'room',
      'global',
      'global_lobby',
      'global:$uid',
      if (currentRoomId?.isNotEmpty == true) 'room:$currentRoomId',
    }.contains(event.channel)) {
      return null;
    }
    final outer = _map(event.payload);
    final nested = _map(outer['msg']);
    final data = nested.isEmpty ? outer : {...outer, ...nested};
    if (data.isEmpty) return null;
    final countries = data['countryCodes'];
    if (countryCode?.isNotEmpty == true &&
        countries is List &&
        countries.isNotEmpty &&
        !countries.any(
          (v) => '$v'.toUpperCase() == countryCode!.toUpperCase(),
        )) {
      return null;
    }
    final timestamp = event.timestamp;
    final at =
        event.receivedAt ??
        (timestamp == null
            ? now
            : DateTime.fromMillisecondsSinceEpoch(
                timestamp < 1000000000000 ? timestamp * 1000 : timestamp,
              ));
    if (now.difference(at) > const Duration(seconds: 10) ||
        at.difference(now) > const Duration(seconds: 10)) {
      return null;
    }
    final id = event.msgId?.isNotEmpty == true
        ? event.msgId!
        : sha256.convert(utf8.encode(jsonEncode(_canonical(data)))).toString();
    final key =
        '${event.event}:$id'; // Cross-channel copies share one identity.
    var room = _id(data['roomId'] ?? event.raw['roomId']);
    if (event.channel.startsWith('room:') &&
        room.isNotEmpty &&
        room != currentRoomId) {
      return null;
    }
    RoomGiftUser user(Object? raw) => RoomGiftUser.fromJson(_map(raw));
    RoomGiftEffectTask effect(
      RoomGift gift,
      RoomGiftUser sender, {
      String? giftIcon,
    }) => RoomGiftEffectTask(
      key: 'barrage:$key',
      createdAt: at,
      kind: RoomGiftEffectKind.prize,
      giftIcon: giftIcon,
      message: RoomScreenGiftMsg(
        gift: gift,
        uid: sender.uid,
        userInfo: sender,
        roomId: room,
        giftCount: 1,
      ),
    );
    switch (event.event) {
      case 'RoomGiftSendBannerEvent':
      case 'RoomLuckGiftSendBannerEvent':
        final lucky = event.event == 'RoomLuckGiftSendBannerEvent';
        final sender = user(data[lucky ? 'userBaseInfo' : 'sendUserInfo']);
        final gift = lucky
            ? RoomGift.fromJson({
                ..._map(data['giftInfo']),
                'name': _name(_map(data['giftInfo'])['name']),
              }, fallbackTabId: 0)
            : RoomGift(
                id: giftInt(data['giftId']),
                name: _name(data['giftName']),
                icon: _text(data['giftPic']),
                price: giftInt(data['price']),
                tabId: 0,
                isCombo: 0,
              );
        if (room.isEmpty || sender.uid <= 0 || gift.id <= 0) return null;
        final count = giftInt(data['giftNum'], 1);
        return RoomBarrageTask(
          key: key,
          kind: lucky ? RoomBarrageKind.lucky : RoomBarrageKind.gift,
          createdAt: at,
          roomId: room,
          sender: sender,
          icon: gift.icon,
          title: gift.name,
          giftId: gift.id,
          background: _text(data[lucky ? 'effectUrl' : 'bannerEffectUrl']),
          foreground: _text(data['upperEffect']),
          texts: _texts(data['bannerContentObj']),
          count: count,
          amount: giftInt(data['amount']),
          multiplier: _double(data['multiply']),
          value: gift.price * count,
        );
      case 'GlobalAristocracyOnlineEvent':
      case 'RoomAristocracyUpgradeEvent':
        final login = event.event == 'GlobalAristocracyOnlineEvent';
        final sender = user(data['userInfo']);
        if (sender.uid <= 0) return null;
        return RoomBarrageTask(
          key: key,
          kind: login
              ? RoomBarrageKind.nobleLogin
              : RoomBarrageKind.nobleUpgrade,
          createdAt: at,
          sender: sender,
          icon: _text(data['aristocracyIcon']),
          background: _text(
            data[login ? 'onlineAnimationUrlBg' : 'upLevelAnimationUrlBg'],
          ),
          foreground: _text(
            data[login
                ? 'onlineAnimationUrlForward'
                : 'upLevelAnimationUrlForward'],
          ),
          texts: {
            for (final lang in ['en', 'ar', 'tr', 'id'])
              if (_text(data['${lang}Msg']).isNotEmpty)
                lang: _text(data['${lang}Msg']),
          },
        );
      case 'RoomResourceFloatScreenEvent':
        final reward = _map(data['rewardInfo']);
        return RoomBarrageTask(
          key: key,
          kind: RoomBarrageKind.resource,
          createdAt: at,
          sender: user(data['userInfo']),
          icon: _text(reward['goodsImg']),
          quantityLabel: _text(reward['showNumStr']),
          background: _text(data['effectUrl']),
          foreground: _text(data['upperEffect']),
          texts: _texts(data['copywriting']),
          link: roomBarrageWebLink(data['jumpLink']),
        );
      case 'RegularJoyBannerEffectEvent':
      case 'RoomGameFloatScreenEvent':
        final regular = event.event == 'RegularJoyBannerEffectEvent';
        if (room.isEmpty) return null;
        final sender = regular
            ? user(data['userInfo'])
            : RoomGiftUser(
                uid: 0,
                name: _text(data['nick']),
                avatar: _text(data['avatar']),
              );
        return RoomBarrageTask(
          key: key,
          kind: RoomBarrageKind.gameWin,
          functionPosition: regular ? null : 22,
          createdAt: at,
          roomId: room,
          sender: sender,
          icon: _text(data['icon']),
          background: _text(data['effectUrl']),
          foreground: _text(data['upperEffect']),
          texts: regular
              ? _texts(data['nameCopywriting'])
              : {'en': _text(data['gameName'])},
          amount: giftInt(data[regular ? 'gold' : 'win']),
          multiplier: _double(data['winMultiple']),
          link: roomBarrageWebLink(data['gameUrl']),
        );
      case 'WorldLuckyBagEvent':
        if (room.isEmpty) return null;
        return RoomBarrageTask(
          key: key,
          kind: RoomBarrageKind.luckyBag,
          createdAt: at,
          roomId: room,
          sender: user(data['userBaseInfo']),
          icon: _text(data['icon']),
          amount: giftInt(data['goldCount']),
          background: _text(data['effectUrl']),
          foreground: _text(data['upperEffect']),
          texts: {'en': _text(data['desc']), 'ar': _text(data['descAr'])},
        );
      case 'RoomBigRocketPrizeEvent':
        if (room.isEmpty) return null;
        final winners = data['winnerList'];
        final mvp = winners is List
            ? winners
                  .map(_map)
                  .where((u) => giftInt(u['role']) == 2)
                  .firstOrNull
            : null;
        final sender = RoomGiftUser.fromJson({
          ...?mvp,
          if (mvp?['avatar'] == null) 'avatar': mvp?['head'],
        });
        final level = giftInt(data['level'], 1).clamp(1, 6);
        final gift = RoomGift(
          id: -100,
          name: 'Room Rocket',
          icon: '',
          price: 0,
          tabId: -1,
          isCombo: 0,
          animationUrl: AppAssets.roomGiftRocketEffects[level - 1],
        );
        return RoomBarrageTask(
          key: key,
          kind: RoomBarrageKind.rocket,
          createdAt: at,
          roomId: room,
          sender: sender,
          icon: AppAssets.roomRocketStages[2][level - 1],
          fullscreen: effect(gift, sender),
        );
      case 'LuckyGiftJackpotSuperMode':
        final jackpot = RoomJackpotInfo.fromJson({...data, 'enabled': true});
        final giftId = giftInt(data['giftId']);
        final active = activeJackpotGift?.call(giftId);
        // Nady shows SUPER only for the currently active combo of that gift.
        if (room.isEmpty &&
            (event.channel == 'room' ||
                event.channel == 'room:$currentRoomId')) {
          room = currentRoomId ?? '';
        }
        if (!jackpot.isSuper ||
            giftId <= 0 ||
            active == null ||
            active.gift.id != giftId ||
            room != currentRoomId) {
          return null;
        }
        final gift = RoomGift(
          id: -2,
          name: 'SUPER',
          icon: '',
          price: 0,
          tabId: -1,
          isCombo: 0,
          animationUrl: AppAssets.roomGiftJackpotEffect,
        );
        return RoomBarrageTask(
          key: key,
          kind: RoomBarrageKind.jackpot,
          comboId: active.comboId,
          createdAt: at,
          roomId: room,
          sender: active.userInfo,
          icon: active.gift.icon,
          giftId: giftId,
          amount: jackpot.displayAmount,
          fullscreen: effect(gift, active.userInfo, giftIcon: active.gift.icon),
        );
      case 'RoomLobbyBigWinStatusEvent':
      case 'RoomLobbyBigWinPrizeEvent':
        final targeted = event.event == 'RoomLobbyBigWinPrizeEvent';
        if (targeted
            ? event.channel != 'global:$uid'
            : event.channel != 'global_lobby') {
          return null;
        }
        if (!targeted && !giftBool(data['showScreen'])) return null;
        final amount = giftInt(data['userWinCoins']);
        final pool = giftInt(data['bigWinTotalCoins']);
        if (targeted ? amount <= 0 : amount <= 0 && pool <= 0) return null;
        final activityId = _id(data['gameBigWinId']);
        final round = giftInt(data['curRound']);
        final prizeKey = activityId.isNotEmpty && round > 0
            ? 'big-win:$activityId:$round:${amount > 0 ? 'user:$uid' : 'pool:${giftInt(data['status'])}'}'
            : key;
        return RoomBarrageTask(
          key: prizeKey,
          kind: RoomBarrageKind.gameGrandPrize,
          functionPosition: 17,
          createdAt: at,
          roomId: room,
          amount: amount,
          sender: user(data['userInfo']),
          icon: _text(data['gameIcon']),
          prize: RoomBarragePrize(
            amount: amount,
            pool: pool,
            gameName: _text(data['gameName']),
            icon: _text(data['gameIcon']),
            activityId: _id(data['gameBigWinId']),
            round: giftInt(data['curRound']),
          ),
        );
    }
    return null;
  }

  Map<String, dynamic> _map(Object? raw) {
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return const {};
      }
    }
    return raw is Map
        ? {
            for (final e in raw.entries)
              if (e.key is String) e.key as String: e.value,
          }
        : const {};
  }

  String _id(Object? raw) => raw is int ? '$raw' : _text(raw);

  String _name(Object? raw) {
    final map = _map(raw);
    if (map.isNotEmpty) {
      return _text(map['en'] ?? map.values.whereType<String>().firstOrNull);
    }
    final value = _text(raw);
    return value.startsWith('{') || value.startsWith('[') ? '' : value;
  }

  String _text(Object? raw) => raw is String ? raw.trim() : '';
  double _double(Object? raw) {
    final value = double.tryParse('$raw');
    return value != null && value.isFinite ? value : 0;
  }

  Map<String, String> _texts(Object? raw) => Map.unmodifiable({
    for (final e in _map(raw).entries)
      if (_text(e.value).isNotEmpty) e.key: _text(e.value),
  });
  Object? _canonical(Object? value) => value is Map
      ? {
          for (final key in value.keys.whereType<String>().toList()..sort())
            key: _canonical(value[key]),
        }
      : value is List
      ? value.map(_canonical).toList()
      : value;
}
