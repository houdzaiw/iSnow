import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../configs/app_configs.dart';
import '../../../manager/auth_session.dart';
import '../../../manager/http_api.dart';
import '../../../manager/http_dio_manager.dart';
import '../../../manager/room_gift_manager.dart';
import '../../../model/server_response.dart';
import 'models/room_lucky_animation_policy.dart';

final roomLuckyConfigRepositoryProvider = Provider<RoomLuckyConfigRepository>(
  (ref) => RoomLuckyConfigRepository(HttpDioManager()),
);

/// Only successful, nonempty config is cached; failed requests can retry.
class RoomLuckyConfigRepository {
  RoomLuckyConfigRepository(
    this.http, {
    AuthSession? session,
    RoomGiftManager? giftManager,
  }) : session = session ?? AuthSession.instance,
       giftManager = giftManager ?? RoomGiftManager.instance;
  final HttpDioManager http;
  final AuthSession session;
  final RoomGiftManager giftManager;
  String? _key;
  Future<RoomLuckyBubbleConfig>? _pending;

  Future<RoomLuckyBubbleConfig> load() async {
    final uid = await session.uid();
    if (uid == null || uid <= 0) return const RoomLuckyBubbleConfig();
    final generation = giftManager.balanceToken.generation;
    final env = AppConfig.shared.appEnv.name;
    final key = '$env:$uid:$generation';
    if (_key == key && _pending != null) return _pending!;
    _key = key;
    final request = _fetch(uid, generation, env);
    _pending = request;
    try {
      final result = await request;
      if (result.isEmpty && identical(_pending, request)) _pending = null;
      return result;
    } catch (_) {
      if (identical(_pending, request)) _pending = null;
      rethrow;
    }
  }

  Future<RoomLuckyBubbleConfig> _fetch(
    int? uid,
    int generation,
    String env,
  ) async {
    final response = await http.post(
      HttpApi.systemConfigById,
      data: const {'configId': 'gift_award_bubble_config'},
    );
    if (await session.uid() != uid ||
        giftManager.balanceToken.generation != generation ||
        AppConfig.shared.appEnv.name != env) {
      throw const NadyApiException(message: 'Lucky animation session changed');
    }
    if (response is! Map) throw const FormatException('Invalid lucky config');
    final result = NadyServerResponse<RoomLuckyBubbleConfig>.fromJson(
      Map<String, dynamic>.from(response),
      RoomLuckyBubbleConfig.parse,
    );
    if (!result.isSuccess) throw result.toException();
    return result.data ?? const RoomLuckyBubbleConfig();
  }
}
