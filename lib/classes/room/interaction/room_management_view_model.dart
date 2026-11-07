import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/room_location_manager.dart';
import '../../../model/room_models.dart';
import '../../../model/room_user_info.dart';
import '../../../model/server_response.dart';
import '../../create_room/create_room_repository.dart';
import 'room_interaction_view_model.dart';
import 'room_management_repository.dart';
import 'room_moderation.dart';

enum RoomManagementSection {
  edit,
  lock,
  layout,
  location,
  background,
  admins,
  silenced,
  blocked,
}

typedef RoomManagementKey = ({
  RoomInteractionKey session,
  RoomManagementSection section,
});

final roomLocationManagerProvider = Provider(
  (ref) => const RoomLocationManager(),
);
final roomManagementProvider = StateNotifierProvider.autoDispose
    .family<RoomManagementViewModel, RoomManagementState, RoomManagementKey>(
      (ref, key) => RoomManagementViewModel(
        ref.watch(roomInteractionProvider(key.session).notifier),
        ref.watch(createRoomRepositoryProvider),
        ref.watch(roomLocationManagerProvider),
        key.section,
      ),
    );

class RoomManagementState {
  const RoomManagementState({
    this.busy = false,
    this.error,
    this.localImage,
    this.members = const [],
    this.backgrounds = const [],
    this.canUploadVip = false,
  });
  final bool busy, canUploadVip;
  final String? error, localImage;
  final List<RoomUserInfo> members;
  final List<RoomBackground> backgrounds;

  RoomManagementState copy({
    bool? busy,
    String? error,
    String? localImage,
    List<RoomUserInfo>? members,
    List<RoomBackground>? backgrounds,
    bool? canUploadVip,
  }) => RoomManagementState(
    busy: busy ?? this.busy,
    error: error,
    localImage: localImage ?? this.localImage,
    members: members ?? this.members,
    backgrounds: backgrounds ?? this.backgrounds,
    canUploadVip: canUploadVip ?? this.canUploadVip,
  );
}

class RoomManagementViewModel extends StateNotifier<RoomManagementState> {
  static const nameLimit = 30;
  static const descriptionLimit = 200;
  RoomManagementViewModel(
    this.session,
    this.upload,
    this.location,
    this.section,
  ) : super(const RoomManagementState()) {
    if (list != null || section == RoomManagementSection.background) {
      Future.microtask(load);
    }
  }
  final RoomInteractionViewModel session;
  final CreateRoomRepository upload;
  final RoomLocationManager location;
  final RoomManagementSection section;

  RoomManagementList? get list => switch (section) {
    RoomManagementSection.admins => RoomManagementList.admins,
    RoomManagementSection.silenced => RoomManagementList.silenced,
    RoomManagementSection.blocked => RoomManagementList.blocked,
    _ => null,
  };
  bool _closed = false;
  bool get active => mounted && !_closed && session.active;
  RoomInfo? get roomInfo => session.room.roomState.roomInfo;
  String get roomId => session.key.roomId;
  void close() => _closed = true;

  Future<int> _requireManager() async {
    final actor = await session.room.currentUid();
    _checkManager(actor);
    return actor!;
  }

  void _checkManager(int? actor) {
    if (!active || session.actorRole(actor)?.isOwnerOrManager != true) {
      throw const NadyApiException(message: 'Room permission changed');
    }
  }

  Future<bool> _run(Future<void> Function() task) async {
    if (!active || state.busy) return false;
    state = state.copy(busy: true);
    try {
      await task();
      if (active) state = state.copy(busy: false);
      return active;
    } catch (error) {
      if (active) {
        state = state.copy(busy: false, error: userFacingErrorMessage(error));
      }
      return false;
    }
  }

  Future<bool> load() => _run(() async {
    final actor = await _requireManager();
    if (list case final kind?) {
      final members = await session.api.members(roomId, kind);
      if (active) state = state.copy(members: members);
    } else if (section == RoomManagementSection.background) {
      final owner = roomInfo?.roomOwnerUid;
      if (owner == null || owner <= 0) {
        throw const NadyApiException(message: 'Room owner is unavailable');
      }
      final rows = await session.api.backgrounds(owner);
      if (!active) return;
      final user = await session.room.currentUser();
      if (active) {
        state = state.copy(
          backgrounds: rows,
          canUploadVip:
              actor == owner &&
              user?.uid == actor &&
              (user?.userLevel?.vipLevel ?? 0) >= 1,
        );
      }
    }
  });

  Future<bool> choosePhoto() => _run(() async {
    await _requireManager();
    final selected = await _pick();
    if (active && selected != null) state = state.copy(localImage: selected);
  });

  Future<String?> _pick() async => (await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 900,
    imageQuality: 85,
  ))?.path;

  Future<bool> saveInfo(String title, String description) => _run(() async {
    if (title.trim().isEmpty) {
      throw const NadyApiException(message: 'Enter a room name');
    }
    final actor = await _requireManager();
    final file = state.localImage;
    final avatar = file == null ? null : await upload.uploadAvatar(file);
    _checkManager(actor);
    await session.api.updateRoom(
      roomId,
      locked: _roomLocked(),
      title: title.trim(),
      description: description.trim(),
      avatar: avatar,
    );
    if (active) await session.room.refreshRoomData();
  });

  bool _roomLocked() {
    final locked = roomInfo?.roomLock;
    if (locked == null) {
      throw const NadyApiException(message: 'Room settings are unavailable');
    }
    return locked;
  }

  Future<bool> lock(bool enabled, String password) => _run(() async {
    await _requireManager();
    if (enabled && !RegExp(r'^\d{4}$').hasMatch(password)) {
      throw const NadyApiException(message: 'Enter a four digit password');
    }
    await session.api.updateRoom(
      roomId,
      locked: enabled,
      password: enabled ? password : '',
    );
    if (active) await session.room.refreshRoomData();
  });

  Future<bool> layout(int type) => _run(() async {
    final actor = await _requireManager();
    if (type < 1 || type > 6) return;
    if (type > 2) {
      final user = await session.room.currentUser();
      _checkManager(actor);
      final isVip = user?.uid == actor && (user?.userLevel?.vipLevel ?? 0) > 0;
      final agentLayout =
          type < 6 &&
          user?.uid == actor &&
          const {1, 3}.contains(user?.roleType);
      if (!isVip && !agentLayout) {
        throw const NadyApiException(
          message: 'VIP is required for this mic layout',
        );
      }
    }
    await session.api.changeLayout(roomId, type);
    if (active) await session.room.refreshRoomData();
  });

  Future<bool> setLocation(bool enabled) => _run(() async {
    final actor = await _requireManager();
    final info = roomInfo;
    final saved = info?.latitude != null && info?.longitude != null;
    final position = enabled && !saved
        ? await location.currentLocation()
        : null;
    _checkManager(actor);
    await session.api.updateRoom(
      roomId,
      locked: _roomLocked(),
      locationEnabled: enabled,
      location: position,
    );
    if (active) await session.room.refreshRoomData();
  });

  Future<bool> setBackground(RoomBackground background) async {
    final result = await _run(() async {
      await _requireManager();
      final owner = roomInfo?.roomOwnerUid;
      if (owner == null || owner <= 0) return;
      await session.api.useBackground(owner, background);
      if (active) await session.room.refreshRoomData();
    });
    if (result && active) await load();
    return result;
  }

  Future<bool> setCustomBackground() async {
    final result = await _run(() async {
      final actor = await _requireManager();
      final owner = roomInfo?.roomOwnerUid;
      final user = await session.room.currentUser();
      if (actor != owner ||
          user?.uid != actor ||
          (user?.userLevel?.vipLevel ?? 0) < 1) {
        return;
      }
      _checkManager(actor);
      final path = await _pick();
      if (path == null) return;
      _checkManager(actor);
      final url = await upload.uploadRoomBackground(path);
      _checkManager(actor);
      await session.api.uploadVipBackground(actor, url);
      if (active) await session.room.refreshRoomData();
    });
    if (result && active) await load();
    return result;
  }

  bool canRemove(int? actor, RoomUserInfo target) =>
      actor != target.uid &&
      (list?.action == RoomModerationAction.unblock
          ? session.actorRole(actor)?.isOwnerOrManager == true
          : availableRoomModeration(
              actor: session.actorRole(actor),
              target: target,
              seat: session.seatFor(target.uid),
            ).contains(list?.action));

  Future<void> remove(int uid) async {
    final kind = list;
    if (kind == null) return;
    final result = await _run(
      () => session.moderate(uid, kind.action, stillOpen: () => active),
    );
    if (result && active) await load();
  }
}
