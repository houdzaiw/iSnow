import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/http_api.dart';
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
      var value = source;
      for (final entry in values.entries) {
        final placeholder = '\${${entry.key}}';
        if (value.contains(placeholder) &&
            entry.key != 'nickname' &&
            entry.value.isEmpty) {
          throw StateError(
            'Invitation information is unavailable. Please retry.',
          );
        }
        value = value.replaceAll(placeholder, entry.value);
      }
      if (value.contains(r'${')) {
        throw StateError('This invitation template is unavailable');
      }
      return value;
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
        if (action != null)
          'shareChannel': action == RoomShareAction.system ? 'Others' : 'Copy',
      },
      fragment: resolve(target.fragment),
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
