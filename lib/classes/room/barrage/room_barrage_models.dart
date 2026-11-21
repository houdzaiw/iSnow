import '../gift/models/room_gift_effect_task.dart';
import '../gift/models/room_gift_event_models.dart';
import '../gift/effects/room_gift_asset_resolver.dart';

enum RoomBarrageKind {
  gift,
  lucky,
  gameWin,
  gameGrandPrize,
  rocket,
  jackpot,
  resource,
  nobleLogin,
  nobleUpgrade,
  luckyBag,
}

enum RoomBarrageActionKind { none, enterRoom, profile, gift, game, prize, web }

class RoomBarrageAction {
  const RoomBarrageAction(
    this.kind, {
    this.roomId = '',
    this.uid = 0,
    this.giftId = 0,
    this.url,
  });
  final RoomBarrageActionKind kind;
  final String roomId;
  final int uid, giftId;
  final Uri? url;
}

class RoomBarragePrize {
  const RoomBarragePrize({
    this.gameName = '',
    this.icon = '',
    this.amount = 0,
    this.activityId = '',
    this.round = 0,
    this.pool = 0,
  });
  final String gameName, icon, activityId;
  final int amount, round, pool;
}

class RoomBarrageTask {
  const RoomBarrageTask({
    required this.key,
    required this.kind,
    required this.createdAt,
    this.roomId = '',
    this.comboId = '',
    this.sender = const RoomGiftUser(uid: 0),
    this.icon = '',
    this.background = '',
    this.foreground = '',
    this.texts = const {},
    this.title = '',
    this.quantityLabel = '',
    this.count = 0,
    this.amount = 0,
    this.multiplier = 0,
    this.value = 0,
    this.giftId = 0,
    this.link,
    this.prize,
    this.fullscreen,
    this.functionPosition,
  });
  final String key,
      roomId,
      comboId,
      icon,
      background,
      foreground,
      title,
      quantityLabel;
  final RoomBarrageKind kind;
  final DateTime createdAt;
  final RoomGiftUser sender;
  final Map<String, String> texts;
  final int count, amount, giftId, value;
  final double multiplier;
  final Uri? link;
  final RoomBarragePrize? prize;
  final RoomGiftEffectTask? fullscreen;
  final int? functionPosition;
  bool get isPrize => const {
    RoomBarrageKind.gameGrandPrize,
    RoomBarrageKind.rocket,
    RoomBarrageKind.jackpot,
  }.contains(kind);
  int priority(int? currentUid) {
    if (isPrize) return 0;
    if (currentUid != null && sender.uid == currentUid) return 1;
    return switch (kind) {
      RoomBarrageKind.resource => 2,
      RoomBarrageKind.nobleLogin || RoomBarrageKind.nobleUpgrade => 3,
      RoomBarrageKind.gameWin => 4,
      RoomBarrageKind.lucky => 5,
      _ => 6,
    };
  }

  String text(String language) {
    final localized = texts[language] ?? texts['en'];
    if (localized?.isNotEmpty == true) {
      return switch (kind) {
        RoomBarrageKind.gameWin => '${sender.name} · $localized · $amount',
        RoomBarrageKind.luckyBag => '${sender.name} · $localized · $amount',
        RoomBarrageKind.resource =>
          '$localized${quantityLabel.isNotEmpty ? ' · $quantityLabel' : ''}',
        _ => localized!,
      };
    }
    return switch (kind) {
      RoomBarrageKind.jackpot => 'SUPER · $amount',
      RoomBarrageKind.rocket => '${sender.name} · Room Rocket',
      RoomBarrageKind.gameGrandPrize =>
        '${prize?.gameName ?? ''} · ${(prize?.amount ?? 0) > 0 ? prize!.amount : prize?.pool ?? amount}',
      RoomBarrageKind.lucky =>
        '${sender.name} · x${multiplier.toInt()} · +$amount',
      _ =>
        '${sender.name}${title.isNotEmpty ? ' · $title' : ''}${count > 0 ? ' · x$count' : ''}${amount > 0 ? ' · +$amount' : ''}',
    };
  }

  RoomBarrageAction action(String? currentRoomId) => switch (kind) {
    RoomBarrageKind.gameGrandPrize => const RoomBarrageAction(
      RoomBarrageActionKind.prize,
    ),
    RoomBarrageKind.nobleLogin || RoomBarrageKind.nobleUpgrade =>
      sender.uid > 0
          ? RoomBarrageAction(RoomBarrageActionKind.profile, uid: sender.uid)
          : const RoomBarrageAction(RoomBarrageActionKind.none),
    RoomBarrageKind.resource =>
      link == null
          ? const RoomBarrageAction(RoomBarrageActionKind.none)
          : RoomBarrageAction(RoomBarrageActionKind.web, url: link),
    RoomBarrageKind.jackpot =>
      roomId.isEmpty || giftId <= 0
          ? const RoomBarrageAction(RoomBarrageActionKind.none)
          : RoomBarrageAction(
              RoomBarrageActionKind.gift,
              roomId: roomId,
              giftId: giftId,
            ),
    RoomBarrageKind.gameWin when link != null => RoomBarrageAction(
      RoomBarrageActionKind.game,
      roomId: roomId,
      url: link,
    ),
    _ =>
      roomId.isEmpty || roomId == currentRoomId
          ? const RoomBarrageAction(RoomBarrageActionKind.none)
          : RoomBarrageAction(RoomBarrageActionKind.enterRoom, roomId: roomId),
  };
}

class RoomBarragePrepared {
  const RoomBarragePrepared(this.task, {this.background, this.foreground});
  final RoomBarrageTask task;
  final RoomGiftAnimationResource? background, foreground;
}

Uri? roomBarrageWebLink(Object? raw) {
  if (raw is! String) return null;
  final uri = Uri.tryParse(raw.trim());
  return uri != null &&
          ['http', 'https'].contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}
