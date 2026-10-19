import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/http_api.dart';
import '../../message/im_repository.dart';
import '../../message/message_view_model.dart';
import '../room_repository.dart';
import 'room_tools_config.dart';
import 'room_tools_models.dart';
import 'room_tools_repository.dart';

typedef RoomShareKey = ({String roomId, String language});
final roomShareViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomShareViewModel, RoomShareState, RoomShareKey>((ref, key) {
      final vm = RoomShareViewModel(
        key,
        ref.watch(roomToolsRepositoryProvider),
        ref.watch(roomRepositoryProvider),
        ref.watch(imRepositoryProvider),
      );
      Future.microtask(vm.load);
      return vm;
    });

class RoomShareState {
  const RoomShareState({
    this.loading = false,
    this.busy = false,
    this.materials = const [],
    this.recent = const [],
    this.friends = const [],
    this.error,
    this.query = '',
    this.hasMore = true,
  });
  final bool loading, busy, hasMore;
  final List<ToolJson> materials, recent, friends;
  final String? error;
  final String query;
}

class RoomShareViewModel extends StateNotifier<RoomShareState> {
  RoomShareViewModel(this.key, this.repository, this.room, this.im)
    : super(const RoomShareState());
  final RoomShareKey key;
  final RoomToolsRepository repository;
  final RoomRepository room;
  final ImRepository im;
  final _allRecent = <ToolJson>[];
  int _page = 1, _searchVersion = 0;
  int _friendsRequest = 0;
  bool _friendsLoading = false;
  ToolJson _invite = {};
  Timer? _search;
  static final _materials = <String, List<ToolJson>>{};
  void _update({
    bool? loading,
    bool? busy,
    List<ToolJson>? materials,
    List<ToolJson>? recent,
    List<ToolJson>? friends,
    String? error,
    String? query,
    bool? hasMore,
    bool clearError = false,
  }) {
    if (mounted) {
      state = RoomShareState(
        loading: loading ?? state.loading,
        busy: busy ?? state.busy,
        materials: materials ?? state.materials,
        recent: recent ?? state.recent,
        friends: friends ?? state.friends,
        error: clearError ? null : error ?? state.error,
        query: query ?? state.query,
        hasMore: hasMore ?? state.hasMore,
      );
    }
  }

  Future<void> load() async {
    if (!mounted || state.loading) return;
    _update(loading: true, clearError: true);
    try {
      final materials = _materials[key.language] ??= toolList(
        await repository.get(HttpApi.roomShareMaterials, {
          'appScene': 'ROOM_SHARE',
          'sub-scene': 'ROOM_SHARE',
          'language': key.language,
        }),
      );
      _update(materials: materials);
    } catch (error) {
      _update(error: userFacingErrorMessage(error));
    }
    if (!mounted) return;
    try {
      _invite = toolMap(await repository.get(HttpApi.roomInviteInfo));
    } catch (error) {
      _update(error: userFacingErrorMessage(error));
    }
    if (!mounted) return;
    try {
      final self = await room.currentUid();
      if (!mounted) return;
      final conversations = await im.fetchConversations();
      if (!mounted) return;
      _allRecent.clear();
      for (final conversation in conversations) {
        final id = int.tryParse(conversation.userID ?? '');
        if (id == null ||
            id <= 0 ||
            id == self ||
            const [10000, 10001, 10002, 10003].contains(id)) {
          continue;
        }
        _allRecent.add({
          'uid': id,
          'nick': conversation.showName ?? '$id',
          'avatar': conversation.faceUrl ?? '',
        });
      }
      _update(recent: List.of(_allRecent));
    } catch (error) {
      _update(error: userFacingErrorMessage(error));
    }
    await loadFriends(reset: true);
    if (mounted) _update(loading: false, error: state.error);
  }

  void search(String text) {
    _search?.cancel();
    _searchVersion++;
    final query = text.trim();
    _update(
      query: query,
      recent: _allRecent
          .where(
            (person) => '${person['nick']} ${person['uid']}'
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList(),
    );
    _search = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(loadFriends(reset: true)),
    );
  }

  Future<void> loadFriends({bool reset = false}) async {
    if (!mounted || !reset && (!state.hasMore || _friendsLoading)) return;
    _friendsLoading = true;
    final request = ++_friendsRequest;
    final version = _searchVersion;
    final page = reset ? 1 : _page + 1;
    try {
      final result = toolList(
        await repository.post(HttpApi.userFriends, {
          'pageNum': page,
          'pageSize': 20,
          'targetUid': 0,
          'searchKey': state.query,
        }),
      );
      if (!mounted || version != _searchVersion || request != _friendsRequest) {
        return;
      }
      _page = page;
      final users = <int, ToolJson>{};
      for (final entry in [
        ...(reset ? <ToolJson>[] : state.friends),
        ...result,
      ]) {
        final user = toolMap(entry['userBaseInfo']).isNotEmpty
            ? toolMap(entry['userBaseInfo'])
            : entry;
        if (toolInt(user['uid']) > 0) users[toolInt(user['uid'])] = user;
      }
      _update(friends: users.values.toList(), hasMore: result.length == 20);
    } catch (error) {
      if (request == _friendsRequest) {
        _update(error: userFacingErrorMessage(error));
      }
    } finally {
      if (request == _friendsRequest) _friendsLoading = false;
    }
  }

  ToolJson roomCard() {
    final info = room.roomState.roomInfo;
    final raw = info?.raw ?? {};
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

  bool _valid(int generation) =>
      mounted &&
      room.roomGeneration == generation &&
      room.roomState.currentRoomId == key.roomId &&
      room.roomState.isInRoom;
  Future<bool> invite(int targetUid) async {
    if (state.busy || targetUid <= 0) return false;
    final generation = room.roomGeneration;
    _update(busy: true, clearError: true);
    try {
      if (!_valid(generation)) return false;
      final profile = toolMap(
        await repository.get(HttpApi.userHomepage, {'targetUid': targetUid}),
      );
      final user = toolMap(toolMap(profile['info'])['userBaseInfo']);
      if (user.isEmpty) {
        throw StateError('Unable to verify invitation permission');
      }
      final vip = toolInt(toolMap(user['userLevel'])['vipLevel']);
      if (vip >= 5) {
        final settings = toolMap(
          await repository.get(HttpApi.userVipSetting, {'uid': targetUid}),
        );
        if (!toolMap(settings['noDisturb']).containsKey('open')) {
          throw StateError('Unable to verify invitation permission');
        }
        if (toolBool(toolMap(settings['noDisturb'])['open'])) {
          throw StateError('This user does not accept invitations');
        }
      }
      if (!_valid(generation)) return false;
      await im.sendRoomInvitation(targetUID: '$targetUid', room: roomCard());
      return _valid(generation);
    } catch (error) {
      _update(error: userFacingErrorMessage(error));
      return false;
    } finally {
      if (mounted) _update(busy: false, error: state.error);
    }
  }

  Future<String> _replace(String value) async {
    final user = await room.currentUser();
    final values = {
      'nickname': user?.nick ?? '',
      'shareUid': '${user?.uid ?? ''}',
      'shareRoomId': key.roomId,
      'inviteCode': '${_invite['inviteCode'] ?? ''}',
    };
    for (final entry in values.entries) {
      value = value.replaceAll('\${${entry.key}}', entry.value);
    }
    return value;
  }

  Future<String?> share(
    ToolJson material,
    String channel, {
    Rect? origin,
  }) async {
    if (state.busy) return null;
    final generation = room.roomGeneration;
    _update(busy: true, clearError: true);
    try {
      final base = const RoomToolsConfig().inviteBase;
      final uri = Uri.tryParse(base);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw StateError('iSnow share domain is not configured');
      }
      final copy = await _replace('${material['copyText'] ?? ''}');
      var jump = await _replace('${material['jumpLink'] ?? ''}');
      final jumpUri = Uri.tryParse(jump);
      if (jumpUri?.scheme == 'nady') {
        final scheme = const RoomToolsConfig().shareScheme;
        if (scheme.isEmpty) {
          throw StateError('iSnow share scheme is not configured');
        }
        jump = jumpUri!.replace(scheme: scheme).toString();
      }
      if (!_valid(generation)) return null;
      final longUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'og_title': 'iSnow',
          'og_description': copy,
          'og_image': '${material['imageUrl'] ?? ''}',
          'og_url': jump,
          'shareChannel': channel,
        },
      );
      var link = longUri.toString();
      try {
        final links = toolList(
          await repository.post(HttpApi.roomShareShortLinks, {
            'shortBaseUrl': uri.origin,
            'originalShareUrls': [link],
          }),
        );
        final short = Uri.tryParse('${links.firstOrNull?['shortUrl'] ?? ''}');
        if (short?.scheme == 'https' && short!.host.isNotEmpty) {
          link = short.toString();
        }
      } catch (_) {
        /* A valid long link remains shareable. */
      }
      if (!_valid(generation)) return null;
      final text = ['Facebook', 'Messenger'].contains(channel)
          ? link
          : '$copy\n$link';
      if (channel == 'Copy' ||
          channel == 'Facebook' ||
          channel == 'Messenger') {
        await Clipboard.setData(ClipboardData(text: text));
        return 'copied';
      }
      Uri? target;
      if (channel == 'WhatsApp') {
        target = Uri(
          scheme: 'whatsapp',
          host: 'send',
          queryParameters: {'text': text},
        );
      }
      if (channel == 'Telegram') {
        target = Uri(
          scheme: 'tg',
          host: 'msg',
          queryParameters: {'text': text},
        );
      }
      if (channel == 'X') {
        target = Uri.https('twitter.com', '/intent/tweet', {'text': text});
      }
      if (target != null) {
        try {
          if (await launchUrl(target, mode: LaunchMode.externalApplication)) {
            return 'opened';
          }
        } catch (_) {
          /* Fall back to the system sheet when the app is absent. */
        }
      }
      final result = await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
      return result.status == ShareResultStatus.success
          ? 'shared'
          : result.status == ShareResultStatus.dismissed
          ? 'cancelled'
          : 'opened';
    } catch (error) {
      _update(error: userFacingErrorMessage(error));
      return null;
    } finally {
      if (mounted) _update(busy: false, error: state.error);
    }
  }

  @override
  void dispose() {
    _search?.cancel();
    super.dispose();
  }
}
