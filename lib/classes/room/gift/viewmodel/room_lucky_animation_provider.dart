import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../effects/room_gift_asset_resolver.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_lucky_animation_policy.dart';
import '../room_lucky_config_repository.dart';

typedef RoomLuckyAnimationRequest = ({
  RoomLuckyGiftResult result,
  int? currentUid,
});
final roomLuckyAnimationProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource?, RoomLuckyAnimationRequest>((
      ref,
      request,
    ) async {
      final result = request.result;
      final config = result.numberLevel > 0
          ? const RoomLuckyBubbleConfig()
          : await ref.read(roomLuckyConfigRepositoryProvider).load();
      return ref
          .read(roomGiftAssetResolverProvider)
          .resolveLucky(result, config: config, currentUid: request.currentUid);
    });
