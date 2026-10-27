import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
import '../../../model/room_models.dart';
import '../../../model/room_share_models.dart';
import 'room_tools_config.dart';
import 'room_tools_models.dart';
import 'room_tools_repository.dart';

final roomShareRepositoryProvider = Provider(
  (ref) => RoomShareRepository(
    ref.watch(roomToolsRepositoryProvider),
    config: ref.watch(roomToolsConfigProvider),
  ),
);

class RoomShareRepository {
  RoomShareRepository(this.api, {this.config = const RoomToolsConfig()});
  final RoomToolsRepository api;
  final RoomToolsConfig config;
  final _cache = <(String, String), List<RoomShareMaterial>>{};
  final _pending = <(String, String), Future<List<RoomShareMaterial>>>{};

  Future<List<RoomShareMaterial>> materials(String language) async {
    final key = (config.apiBase, language);
    final cached = _cache[key];
    if (cached != null) return cached;
    return _pending.putIfAbsent(key, () async {
      try {
        final data = await api.get(HttpApi.roomShareMaterials, {
          'appScene': 'ROOM_SHARE',
          'sub-scene': 'ROOM_SHARE',
          'language': language,
        });
        final list =
            toolList(data)
                .map(RoomShareMaterial.fromJson)
                .where((material) => material.jumpLink.isNotEmpty)
                .toList()
              ..sort((a, b) => a.sortNo.compareTo(b.sortNo));
        final result = List<RoomShareMaterial>.unmodifiable(list);
        if (result.isNotEmpty) _cache[key] = result;
        return result;
      } finally {
        _pending.remove(key);
      }
    });
  }

  Future<String> inviteCode() async =>
      '${toolMap(await api.get(HttpApi.roomInviteInfo))['inviteCode'] ?? ''}';

  Future<RoomShareContactsPage> friends({
    required int page,
    required String query,
    required int selfUid,
  }) async {
    final data = toolList(
      await api.post(HttpApi.userFriends, {
        'pageNum': page,
        'pageSize': 20,
        'targetUid': 0,
        'searchKey': query,
      }),
    );
    final users = <RoomShareContact>[];
    for (final entry in data) {
      final nested = toolMap(entry['userBaseInfo']);
      final user = nested.isEmpty ? entry : nested;
      final uid = toolInt(user['uid']);
      if (uid > 0 && uid != selfUid) {
        users.add(
          RoomShareContact(
            uid: uid,
            nickname: '${user['nick'] ?? uid}',
            avatar: '${user['avatar'] ?? ''}',
          ),
        );
      }
    }
    return RoomShareContactsPage(users: users, hasMore: data.length == 20);
  }

  Future<int> recipientVipLevel(int uid) async {
    final profile = toolMap(
      await api.get(HttpApi.userHomepage, {'targetUid': uid}),
    );
    final user = toolMap(toolMap(profile['info'])['userBaseInfo']);
    if (user.isEmpty) {
      throw StateError('Unable to verify invitation permission');
    }
    return toolInt(toolMap(user['userLevel'])['vipLevel']);
  }

  Future<bool> acceptsVipInvitations(int uid) async {
    final settings = toolMap(
      await api.get(HttpApi.userVipSetting, {'uid': uid}),
    );
    final noDisturb = toolMap(settings['noDisturb']);
    if (!noDisturb.containsKey('open')) {
      throw StateError('Unable to verify invitation permission');
    }
    return !toolBool(noDisturb['open']);
  }

  ToolJson roomCard(RoomInfo? info, String roomId) {
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
      'roomId': int.tryParse(roomId) ?? roomId,
      for (final name in allowed)
        if (source.containsKey(name)) name: source[name],
      'roomPasswd': '',
    };
  }

  /// Resolve individual URI components so nicknames cannot inject parameters.
  RoomShareContent content(
    RoomShareMaterial material, {
    required int uid,
    required String nickname,
    required String roomId,
    required String inviteCode,
    RoomShareAction? action,
  }) {
    final values = {
      'nickname': nickname,
      'shareUid': '$uid',
      'shareRoomId': roomId,
      'inviteCode': inviteCode,
    };
    String resolve(String source) {
      return source.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (match) {
        final key = match.group(1)!;
        final value = values[key];
        if (value == null) {
          throw StateError('This invitation template is unavailable');
        }
        if (key != 'nickname' && value.isEmpty) {
          throw StateError(
            'Invitation information is unavailable. Please retry.',
          );
        }
        return value;
      });
    }

    final base = Uri.tryParse(config.inviteBase);
    if (base == null || !_webUri(base)) {
      throw StateError('The share page address is not configured correctly');
    }
    final target = Uri.tryParse(material.jumpLink);
    final scheme = config.shareScheme.trim();
    if (target == null ||
        target.userInfo.isNotEmpty ||
        target.host.isEmpty ||
        !{
          'http',
          'https',
          'nady',
          if (scheme.isNotEmpty) scheme,
        }.contains(target.scheme)) {
      throw StateError('This invitation link is unavailable');
    }
    var jump = target.replace(
      pathSegments: target.pathSegments.map(resolve),
      queryParameters: {
        for (final entry in target.queryParametersAll.entries)
          resolve(entry.key): entry.value.map(resolve).toList(),
        if (action != null) 'shareChannel': action.channelName,
      },
      fragment: resolve(Uri.decodeComponent(target.fragment)),
    );
    if (target.scheme == 'nady' && scheme.isNotEmpty) {
      jump = jump.replace(scheme: scheme);
    }
    final description = resolve(material.copyText);
    return RoomShareContent(
      description: description,
      link: base.replace(
        queryParameters: {
          ...base.queryParametersAll,
          'og_title': 'iSnow',
          'og_description': description,
          'og_image': material.imageUrl,
          'og_url': jump.toString(),
        },
      ),
    );
  }

  bool _webUri(Uri uri) =>
      uri.hasAuthority &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      (uri.scheme == 'https' || config.allowHttpShare && uri.scheme == 'http');

  Future<RoomShareContent> shorten(RoomShareContent content) async {
    try {
      final links = toolList(
        await api.post(HttpApi.roomShareShortLinks, {
          'shortBaseUrl': content.link.origin,
          'originalShareUrls': [content.link.toString()],
        }),
      );
      final short = Uri.tryParse(
        '${links.firstOrNull?['shortUrl'] ?? ''}'.trim(),
      );
      if (short != null && _webUri(short)) return content.withLink(short);
    } catch (_) {
      // The validated long invitation remains usable when shortening fails.
    }
    return content;
  }

  Future<void> reportShareAttempt() async {
    try {
      await api.post(HttpApi.roomShareReport, {});
    } catch (_) {
      debugPrint('[RoomShare] share attempt report failed');
    }
  }
}
