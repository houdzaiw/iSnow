import 'dart:async';
import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/http_api.dart';
import '../../../manager/room_share_manager.dart';
import '../../../model/room_share_models.dart';
import '../../message/im_repository.dart';
import '../../message/message_view_model.dart';
import '../room_repository.dart';
import 'room_share_repository.dart';
import 'room_share_state.dart';
import 'room_tools_models.dart';
import 'room_tools_repository.dart';

export 'room_share_state.dart';

typedef RoomShareKey = ({String roomId, String language});
final roomShareViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomShareViewModel, RoomShareState, RoomShareKey>((ref, key) {
      final vm = RoomShareViewModel(
        key,
        ref.watch(roomToolsRepositoryProvider),
        ref.watch(roomRepositoryProvider),
        ref.watch(imRepositoryProvider),
        sharing: ref.watch(roomShareRepositoryProvider),
        platform: ref.watch(roomShareManagerProvider),
      );
      Future.microtask(vm.load);
      return vm;
    });

class RoomShareViewModel extends StateNotifier<RoomShareState> {
  RoomShareViewModel(
    this.key,
    this.repository,
    this.room,
    this.im, {
    RoomShareRepository? sharing,
    RoomShareManager? platform,
  }) : sharing = sharing ?? RoomShareRepository(repository),
       platform = platform ?? RoomShareManager(),
       _generation = room.roomGeneration,
       super(const RoomShareState()) {
    room.addListener(_roomChanged);
    room.addAuthListener(close);
  }

  final RoomShareKey key;
  final RoomToolsRepository repository;
  final RoomShareRepository sharing;
  final RoomShareManager platform;
  final RoomRepository room;
  final ImRepository im;
  final int _generation;
  final _allRecent = <RoomShareContact>[];
  int _page = 1, _searchVersion = 0, _friendsRequest = 0;
  int? _uid;
  String _nickname = '', _inviteCode = '';
  bool _closed = false, _materialsLoading = false, _recentLoading = false;
  Future<bool>? _identity;
  Timer? _search;

  bool get _valid =>
      mounted &&
      !_closed &&
      room.roomGeneration == _generation &&
      room.roomState.currentRoomId == key.roomId &&
      room.roomState.isInRoom;

  void _roomChanged() {
    if (!_valid) close();
  }

  /// Invalidates work as soon as a sheet starts closing, not after its animation.
  void close() {
    if (_closed) return;
    _closed = true;
    _search?.cancel();
    _inviteCode = '';
    _allRecent.clear();
    if (mounted) {
      state = state.copyWith(
        isActive: false,
        busy: false,
        recent: [],
        friends: [],
        clearPreview: true,
      );
    }
  }

  Future<bool> _ensureIdentity() => _identity ??= _readIdentity();
  Future<bool> _readIdentity() async {
    try {
      final uid = await room.currentUid();
      if (!_valid) return false;
      final user = await room.currentUser();
      if (!_valid) return false;
      if (uid == null || uid <= 0 || user?.uid != uid) {
        throw StateError('Please log in again to share this room');
      }
      _uid = uid;
      _nickname = user?.nick ?? '';
      return true;
    } catch (_) {
      _identity = null;
      rethrow;
    }
  }

  Future<bool> _sameAccount() async {
    final uid = await room.currentUid();
    if (!_valid) return false;
    if (uid != _uid) {
      close();
      return false;
    }
    return true;
  }

  Future<void> load() async {
    if (!_valid) return;
    await Future.wait([
      loadMaterials(),
      loadRecent(),
      loadFriends(reset: true),
    ]);
  }

  Future<void> loadMaterials() async {
    if (!_valid || _materialsLoading) return;
    _materialsLoading = true;
    state = state.copyWith(materialsLoading: true, clearMaterialsError: true);
    try {
      if (!await _ensureIdentity() || !_valid) return;
      final materials = await sharing.materials(key.language);
      if (!_valid) return;
      final index = state.materialIndex.clamp(
        0,
        materials.isEmpty ? 0 : materials.length - 1,
      );
      state = state.copyWith(materials: materials, materialIndex: index);
      if (materials.any((material) => material.needsInviteCode)) {
        final code = await sharing.inviteCode();
        if (!_valid) return;
        _inviteCode = code;
      }
      if (materials.isNotEmpty) selectMaterial(index);
    } catch (error) {
      if (_valid)
        state = state.copyWith(materialsError: userFacingErrorMessage(error));
    } finally {
      _materialsLoading = false;
      if (_valid) {
        state = state.copyWith(
          materialsLoading: false,
          materialsLoaded: true,
          tab: state.materials.isEmpty && state.tab == RoomShareTab.share
              ? RoomShareTab.recent
              : state.tab,
        );
      }
    }
  }

  void selectTab(RoomShareTab tab) {
    if (_valid) state = state.copyWith(tab: tab, clearError: true);
  }

  void selectMaterial(int index) {
    if (!_valid || state.busy || index < 0 || index >= state.materials.length)
      return;
    try {
      final preview = _content(state.materials[index]);
      state = state.copyWith(
        materialIndex: index,
        preview: preview,
        clearMaterialsError: true,
      );
    } catch (error) {
      state = state.copyWith(
        materialIndex: index,
        clearPreview: true,
        materialsError: userFacingErrorMessage(error),
      );
    }
  }

  RoomShareContent _content(
    RoomShareMaterial material, [
    RoomShareAction? action,
  ]) => sharing.content(
    material,
    uid: _uid!,
    nickname: _nickname,
    roomId: key.roomId,
    inviteCode: _inviteCode,
    action: action,
  );

  Future<void> loadRecent() async {
    if (!_valid || _recentLoading) return;
    _recentLoading = true;
    state = state.copyWith(recentLoading: true, clearRecentError: true);
    try {
      if (!await _ensureIdentity() || !_valid) return;
      final conversations = await im.fetchConversations();
      if (!_valid) return;
      _allRecent.clear();
      final users = <int>{};
      for (final conversation in conversations) {
        final id = int.tryParse(conversation.userID ?? '');
        if (conversation.type != 1 ||
            id == null ||
            id <= 0 ||
            id == _uid ||
            const [10000, 10001, 10002, 10003].contains(id) ||
            !users.add(id))
          continue;
        _allRecent.add(
          RoomShareContact(
            uid: id,
            nickname: conversation.showName ?? '$id',
            avatar: conversation.faceUrl ?? '',
          ),
        );
      }
      state = state.copyWith(recent: _filterRecent(state.query));
    } catch (error) {
      if (_valid)
        state = state.copyWith(recentError: userFacingErrorMessage(error));
    } finally {
      _recentLoading = false;
      if (_valid) state = state.copyWith(recentLoading: false);
    }
  }

  List<RoomShareContact> _filterRecent(String query) => _allRecent
      .where(
        (user) => '${user.nickname} ${user.uid}'.toLowerCase().contains(
          query.toLowerCase(),
        ),
      )
      .toList();

  void search(String text) {
    if (!_valid) return;
    _search?.cancel();
    _searchVersion++;
    final query = text.trim();
    state = state.copyWith(
      query: query,
      recent: _filterRecent(query),
      friends: [],
      hasMore: true,
    );
    _search = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(loadFriends(reset: true)),
    );
  }

  Future<void> loadFriends({bool reset = false}) async {
    if (!_valid || !reset && (!state.hasMore || state.friendsLoading)) return;
    final request = ++_friendsRequest, version = _searchVersion;
    final page = reset ? 1 : _page + 1;
    state = state.copyWith(friendsLoading: true, clearFriendsError: true);
    try {
      if (!await _ensureIdentity() || !_valid) return;
      final result = toolList(
        await repository.post(HttpApi.userFriends, {
          'pageNum': page,
          'pageSize': 20,
          'targetUid': 0,
          'searchKey': state.query,
        }),
      );
      if (!_valid || version != _searchVersion || request != _friendsRequest)
        return;
      _page = page;
      final users = <int, RoomShareContact>{
        if (!reset)
          for (final user in state.friends) user.uid: user,
      };
      for (final entry in result) {
        final nested = toolMap(entry['userBaseInfo']);
        final user = nested.isEmpty ? entry : nested;
        final uid = toolInt(user['uid']);
        if (uid > 0 && uid != _uid)
          users[uid] = RoomShareContact(
            uid: uid,
            nickname: '${user['nick'] ?? uid}',
            avatar: '${user['avatar'] ?? ''}',
          );
      }
      state = state.copyWith(
        friends: users.values.toList(),
        hasMore: result.length == 20,
      );
    } catch (error) {
      if (_valid && request == _friendsRequest && version == _searchVersion) {
        state = state.copyWith(friendsError: userFacingErrorMessage(error));
      }
    } finally {
      if (_valid && request == _friendsRequest)
        state = state.copyWith(friendsLoading: false);
    }
  }

  ToolJson roomCard() {
    final raw = room.roomState.roomInfo?.raw ?? {};
    final nested = toolMap(raw['roomInfoDTO'] ?? raw['roomInfo']);
    final source = nested.isEmpty ? raw : nested;
    const allowed = [
      'roomUid',
      'roomNo',
      'avatar',
      'title',
      'roomTypeValue',
      'roomDesc',
      'roomLock',
      'quickWelcomeStr',
      'isFollow',
      'country',
      'roomGiftWeekVal',
    ];
    return {
      'roomId': int.tryParse(key.roomId) ?? key.roomId,
      for (final name in allowed)
        if (source.containsKey(name)) name: source[name],
      'roomPasswd': '',
    };
  }

  Future<bool> invite(int targetUid) async {
    if (!_valid || state.busy || targetUid <= 0) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (!await _ensureIdentity() || !_valid || targetUid == _uid)
        return false;
      final profile = toolMap(
        await repository.get(HttpApi.userHomepage, {'targetUid': targetUid}),
      );
      if (!_valid) return false;
      final user = toolMap(toolMap(profile['info'])['userBaseInfo']);
      if (user.isEmpty)
        throw StateError('Unable to verify invitation permission');
      if (toolInt(toolMap(user['userLevel'])['vipLevel']) >= 5) {
        final settings = toolMap(
          await repository.get(HttpApi.userVipSetting, {'uid': targetUid}),
        );
        if (!_valid) return false;
        if (!toolMap(settings['noDisturb']).containsKey('open')) {
          throw StateError('Unable to verify invitation permission');
        }
        if (toolBool(toolMap(settings['noDisturb'])['open'])) {
          throw StateError('This user does not accept invitations');
        }
      }
      if (!await _sameAccount()) return false;
      await im.sendRoomInvitation(targetUID: '$targetUid', room: roomCard());
      return _valid && await _sameAccount();
    } catch (error) {
      if (_valid) state = state.copyWith(error: userFacingErrorMessage(error));
      return false;
    } finally {
      if (_valid) state = state.copyWith(busy: false);
    }
  }

  Future<RoomShareOutcome> share(
    RoomShareAction action, {
    required Rect origin,
  }) async {
    if (!_valid || state.busy) return RoomShareOutcome.stale;
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (!await _ensureIdentity() || !_valid || state.materials.isEmpty)
        return RoomShareOutcome.stale;
      final content = _content(state.materials[state.materialIndex], action);
      final shortened = await sharing.shorten(content);
      if (!await _sameAccount()) return RoomShareOutcome.stale;
      if (action == RoomShareAction.copy) {
        await platform.copyText(shortened.text);
        return _valid ? RoomShareOutcome.copied : RoomShareOutcome.stale;
      }
      unawaited(sharing.reportShareAttempt());
      final result = await platform.shareText(
        text: shortened.text,
        origin: origin,
      );
      return _valid ? result : RoomShareOutcome.stale;
    } catch (error) {
      if (_valid) state = state.copyWith(error: userFacingErrorMessage(error));
      return RoomShareOutcome.failed;
    } finally {
      if (_valid) state = state.copyWith(busy: false);
    }
  }

  @override
  void dispose() {
    _closed = true;
    _search?.cancel();
    room.removeListener(_roomChanged);
    room.removeAuthListener(close);
    super.dispose();
  }
}
