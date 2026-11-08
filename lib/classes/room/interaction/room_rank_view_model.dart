import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import 'room_interaction_repository.dart';
import 'room_interaction_view_model.dart';

enum RoomRankPeriod {
  daily(5),
  weekly(4),
  monthly(3);

  const RoomRankPeriod(this.frequency);
  final int frequency;
}

typedef RoomRankQuery = ({
  RoomInteractionKey session,
  RoomRankPeriod period,
  bool profit,
});

final roomRankBoardProvider = FutureProvider.autoDispose
    .family<RoomRankBoard?, RoomRankQuery>((ref, key) async {
      final session = ref.watch(roomInteractionProvider(key.session).notifier);
      if (!session.active) return null;
      final result = await session.api.rank(key);
      return session.active ? result : null;
    });

extension RoomRankRepository on RoomInteractionRepository {
  Future<RoomRankBoard> rank(RoomRankQuery key) async {
    final params = {
      'frequencyType': key.period.frequency,
      'roomId': key.session.roomId,
    };
    final rows = roomInteractionMap(
      await get(key.profit ? HttpApi.roomRankIncome : HttpApi.rankCommonly, {
        ...params,
        'size': 100,
        if (!key.profit) ...{'rankType': 1, 'isInRoom': true},
      }),
    );
    int? total;
    try {
      final summary = roomInteractionMap(
        await get(HttpApi.roomRankSummary, {
          'roomId': key.session.roomId,
          'type': key.period.frequency,
        }),
      );
      total = int.tryParse('${summary[key.profit ? 'diamondVal' : 'coinVal']}');
    } catch (_) {
      // The room aggregate can be unavailable independently of the ranked users.
    }
    return RoomRankBoard.fromJson(rows, total);
  }
}

class RoomRankBoard {
  const RoomRankBoard(this.rows, this.me, this.endsAt, this.total);

  factory RoomRankBoard.fromJson(Map<String, dynamic> json, int? total) {
    final rows = json['rankVOs'];
    final count = int.tryParse('${json['countdown']}') ?? 0;
    return RoomRankBoard(
      [
        if (rows is List)
          for (final entry in rows.whereType<Map>())
            RoomRankRow.fromJson(roomInteractionMap(entry)),
      ],
      json['me'] is Map
          ? RoomRankRow.fromJson(roomInteractionMap(json['me']))
          : null,
      count > 0 ? DateTime.now().add(Duration(seconds: count)) : null,
      total,
    );
  }

  final List<RoomRankRow> rows;
  final RoomRankRow? me;
  final DateTime? endsAt;
  final int? total;
}

class RoomRankRow {
  const RoomRankRow(
    this.uid,
    this.name,
    this.avatar,
    this.position,
    this.amount,
  );
  factory RoomRankRow.fromJson(Map<String, dynamic> json) => RoomRankRow(
    int.tryParse('${json['uid']}') ?? 0,
    (json['nick'] ?? '').toString(),
    json['avatar']?.toString(),
    int.tryParse('${json['seqNo']}') ?? 0,
    int.tryParse('${json['rankVal']}') ?? 0,
  );
  final int uid, position, amount;
  final String name;
  final String? avatar;
}
