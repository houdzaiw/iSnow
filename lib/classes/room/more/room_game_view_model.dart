import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import '../room_repository.dart';
import 'room_tools_config.dart';
import 'room_tools_repository.dart';

typedef RoomGameKey = ({String roomId, String url, String language});
final roomGameViewModelProvider = FutureProvider.autoDispose
    .family<Uri, RoomGameKey>((ref, key) async {
      final room = ref.watch(roomRepositoryProvider);
      final generation = room.roomGeneration;
      final config = ref.watch(roomToolsConfigProvider);
      final api = ref.watch(roomToolsRepositoryProvider);
      var cancelled = false;
      ref.onDispose(() => cancelled = true);
      final raw = key.url
          .replaceAll(r'${roomId}', Uri.encodeComponent(key.roomId))
          .replaceAll(r'${language}', Uri.encodeComponent(key.language));
      final uri = Uri.parse(raw);
      if (!uri.hasScheme || !config.trustedGame(uri)) {
        throw StateError('Game host is not configured');
      }
      final parameters = {
        ...uri.queryParameters,
        'roomId': key.roomId,
        'language': key.language,
      };
      if (uri.origin != Uri.parse(config.apiBase).origin) {
        final user = await room.currentUser();
        if (cancelled || room.roomGeneration != generation) {
          throw StateError('Game closed');
        }
        if (user?.userNo == null) throw StateError('Missing game user number');
        final token = await api.get(HttpApi.gameToken);
        if (token is! String || token.isEmpty) {
          throw StateError('Missing game token');
        }
        if (config.yomiHosts.contains(uri.host.toLowerCase())) {
          parameters.addAll({
            'platAuthCode': token,
            'platUserId': '${user!.userNo}',
            'platPayload': key.roomId,
          });
        } else {
          parameters.addAll({'token': token, 'uid': '${user!.userNo}'});
        }
      }
      if (cancelled ||
          room.roomGeneration != generation ||
          room.roomState.currentRoomId != key.roomId ||
          !room.roomState.isInRoom) {
        throw StateError('Room session ended');
      }
      return uri.replace(queryParameters: parameters);
    });

double? gameHeightRatio(Object? value) {
  final ratio = value is num ? value.toDouble() : double.tryParse('$value');
  return ratio != null && ratio.isFinite && ratio > 0 ? ratio : null;
}
