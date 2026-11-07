import '../../../manager/http_api.dart';
import '../../../model/room_models.dart';
import '../../../model/room_user_info.dart';
import '../../../model/server_response.dart';
import 'room_interaction_repository.dart';
import 'room_interaction_view_model.dart';

enum RoomModerationAction {
  addAdmin,
  removeAdmin,
  silence,
  unsilence,
  inviteMic,
  kickMic,
  muteMic,
  unmuteMic,
  lockMic,
  unlockMic,
  kick,
  block,
  unblock,
}

bool roomSilenced(int? end, {DateTime? now}) {
  if (end == null || end <= 0) return false;
  final milliseconds = end < 100000000000 ? end * 1000 : end;
  return milliseconds > (now ?? DateTime.now()).millisecondsSinceEpoch;
}

Set<RoomModerationAction> availableRoomModeration({
  required UserRoomIdentity? actor,
  required RoomUserInfo target,
  required RoomMicModel? seat,
}) {
  if (actor?.isOwnerOrManager != true || !target.identityConfirmed) return {};
  final owner = actor == UserRoomIdentity.owner;
  final targetRole = target.roomIdentity;
  final result = <RoomModerationAction>{
    if (seat == null) RoomModerationAction.inviteMic,
  };
  if (targetRole == UserRoomIdentity.owner ||
      (!owner && targetRole == UserRoomIdentity.manager)) {
    return result;
  }
  return {
    ...result,
    if (owner)
      targetRole == UserRoomIdentity.manager
          ? RoomModerationAction.removeAdmin
          : RoomModerationAction.addAdmin,
    roomSilenced(target.silenceEndTime)
        ? RoomModerationAction.unsilence
        : RoomModerationAction.silence,
    RoomModerationAction.kick,
    RoomModerationAction.block,
    if (seat != null) ...[
      RoomModerationAction.kickMic,
      seat.isMuted == true
          ? RoomModerationAction.unmuteMic
          : RoomModerationAction.muteMic,
      seat.isLocked == true
          ? RoomModerationAction.unlockMic
          : RoomModerationAction.lockMic,
    ],
  };
}

int roomModerationVipThreshold(RoomModerationAction action) => switch (action) {
  RoomModerationAction.silence || RoomModerationAction.unsilence => 4,
  RoomModerationAction.kickMic || RoomModerationAction.inviteMic => 5,
  RoomModerationAction.kick || RoomModerationAction.block => 6,
  _ => 0,
};

class RoomSilenceOption {
  const RoomSilenceOption(this.type, this.label);
  final int type;
  final String label;
}

extension RoomModerationRepository on RoomInteractionRepository {
  Future<List<RoomSilenceOption>> silenceOptions(String language) async {
    final data = await get(HttpApi.roomSilenceOptions, {});
    return [
      if (data is List)
        for (final row in data.whereType<Map>())
          if (int.tryParse('${row['timeType']}') case final type? when type > 0)
            RoomSilenceOption(
              type,
              (roomInteractionMap(row['translationCopy'])[language] ??
                      roomInteractionMap(row['translationCopy'])['en'] ??
                      row['desc'] ??
                      '')
                  .toString(),
            ),
    ];
  }
}

extension RoomModerationSession on RoomInteractionViewModel {
  UserRoomIdentity? actorRole(int? actor) {
    if (actor == null || actor <= 0) return null;
    final current = room.roomState;
    if (current.roomInfo?.roomOwnerUid == actor) return UserRoomIdentity.owner;
    return current.enterResponse?.identity;
  }

  RoomMicModel? seatFor(int uid) =>
      room.roomState.micList.where((entry) => entry.uid == uid).firstOrNull;

  Future<void> moderate(
    int uid,
    RoomModerationAction action, {
    int? duration,
    required bool Function() stillOpen,
  }) async {
    if (!active || !stillOpen()) return;
    final actor = await room.currentUid();
    if (!active || !stillOpen()) return;
    if (actor == null ||
        actor == uid ||
        actorRole(actor)?.isOwnerOrManager != true) {
      throw const NadyApiException(message: 'Room permission changed');
    }
    final roomId = key.roomId;
    if (action == RoomModerationAction.unblock) {
      final members = await api.get(HttpApi.roomBlacklist, {'roomId': roomId});
      if (!active || !stillOpen()) return;
      if (actorRole(actor)?.isOwnerOrManager != true ||
          members is! List ||
          !members.whereType<Map>().any(
            (row) =>
                roomInteractionMap(row['userBase'])['uid']?.toString() ==
                '$uid',
          )) {
        throw const NadyApiException(
          message: 'Room permission or member status changed',
        );
      }
      await api.post(HttpApi.roomRemoveBlacklist, {
        'roomId': roomId,
        'targetUid': uid,
      });
      return;
    }

    final target = await api.user(roomId, uid);
    if (!active || !stillOpen()) return;
    final threshold = roomModerationVipThreshold(action);
    if (threshold > 0 && (target.vipLevel ?? 0) >= threshold) {
      final actorInfo = await room.currentUser();
      if (!active || !stillOpen()) return;
      if (actorInfo?.uid != actor ||
          (actorInfo?.userLevel?.vipLevel ?? 0) < target.vipLevel!) {
        throw const NadyApiException(
          message: 'This member is protected by VIP privileges',
        );
      }
    }

    // Read the current seat and room role after all asynchronous validation.
    final seat = seatFor(uid);
    final role = actorRole(actor);
    if (!availableRoomModeration(
      actor: role,
      target: target,
      seat: seat,
    ).contains(action)) {
      throw const NadyApiException(
        message: 'Room permission or member status changed',
      );
    }
    final body = {'roomId': roomId, 'targetUid': uid};
    switch (action) {
      case RoomModerationAction.addAdmin:
        await api.post(HttpApi.roomAdminAdd, body);
      case RoomModerationAction.removeAdmin:
        await api.post(HttpApi.roomAdminRemove, body);
      case RoomModerationAction.silence:
      case RoomModerationAction.unsilence:
        if (action == RoomModerationAction.silence && (duration ?? 0) <= 0) {
          return;
        }
        await api.post(HttpApi.roomSilence, {
          ...body,
          'type': action == RoomModerationAction.silence ? 1 : 2,
          'timeType': duration,
        });
      case RoomModerationAction.inviteMic:
        await api.post(HttpApi.roomMicInvite, body);
      case RoomModerationAction.kickMic:
        await room.kickDownMic(position: seat!.position, targetUid: uid);
      case RoomModerationAction.muteMic:
      case RoomModerationAction.unmuteMic:
        await room.muteMicSeat(
          position: seat!.position,
          mute: action == RoomModerationAction.muteMic,
        );
      case RoomModerationAction.lockMic:
      case RoomModerationAction.unlockMic:
        await room.lockMicSeat(
          position: seat!.position,
          isLock: action == RoomModerationAction.lockMic,
        );
      case RoomModerationAction.kick:
      case RoomModerationAction.block:
        await api.post(HttpApi.roomKickOut, {
          ...body,
          'type': action == RoomModerationAction.block ? 2 : 1,
        });
      case RoomModerationAction.unblock:
        break;
    }
  }
}
