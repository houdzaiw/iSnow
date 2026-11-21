import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';
import '../models/room_gift_event_models.dart';
import '../models/room_gift_effect_task.dart';
import '../models/room_lucky_animation_policy.dart';

enum RoomGiftAnimationFormat { native, svga, mp4, vap, pag }

class RoomGiftAnimationResource {
  const RoomGiftAnimationResource({
    required this.format,
    required this.videoMode,
    this.bytes,
    this.file,
    this.replacements = const {},
  });
  final RoomGiftAnimationFormat format;
  final int videoMode;
  final Uint8List? bytes;
  final File? file;
  final Map<String, String> replacements;
}

final roomGiftAssetResolverProvider = Provider<RoomGiftAssetResolver>(
  (ref) => RoomGiftAssetResolver(),
);
final roomGiftAnimationProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource, RoomGift>((ref, gift) {
      return ref.watch(roomGiftAssetResolverProvider).resolve(gift);
    });

final roomGiftTaskAnimationProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource, RoomGiftEffectTask>(
      (ref, task) => ref.watch(roomGiftAssetResolverProvider).resolveTask(task),
    );

/// Separate, bounded CDN file cache. Never sends Nady credentials to resource hosts.
class RoomGiftAssetResolver {
  Future<RoomGiftAnimationResource?> resolveLucky(
    RoomLuckyGiftResult result, {
    required RoomLuckyBubbleConfig config,
    required int? currentUid,
  }) async {
    final String? source;
    if (result.numberLevel > 0) {
      source = AppAssets.roomGiftLuckyNumbers[result.numberLevel];
    } else {
      final size = config.select(
        isSelf: result.sender.uid == currentUid,
        amount: result.amount,
        multiplier: result.multiplier,
      );
      source = size == null ? null : AppAssets.roomGiftLuckyBubbles[size.name];
    }
    if (source == null) return null;
    final resource = await resolveSource(
      source,
      format: RoomGiftAnimationFormat.vap,
    );
    if (resource.file == null) {
      throw const FormatException('Missing lucky resource');
    }
    final tags = await _vapTags(resource.file!);
    final replacements = <String, String>{
      if (tags.contains('text')) 'text': result.sender.name,
      if (tags.contains('Win')) 'Win': 'Win ${result.amount}',
      if (tags.contains('Times')) 'Times': '${result.multiplier.toInt()} times',
      if (tags.contains('Avatar'))
        'Avatar': (await resolveImage(result.sender.avatar)).path,
    };
    return RoomGiftAnimationResource(
      format: resource.format,
      videoMode: resource.videoMode,
      file: resource.file,
      bytes: resource.bytes,
      replacements: Map.unmodifiable(replacements),
    );
  }

  Future<RoomGiftAnimationResource> resolveTask(RoomGiftEffectTask task) async {
    final resource = await resolve(task.message.gift);
    if (resource.format != RoomGiftAnimationFormat.vap ||
        resource.file == null) {
      return resource;
    }
    final tags = await _vapTags(resource.file!);
    final replacements = <String, String>{};
    if (tags.contains('name')) {
      replacements['name'] = task.message.userInfo.name;
    }
    for (final (tag, source) in [
      ('user', task.message.userInfo.avatar),
      ('gift', task.giftIcon ?? task.message.gift.icon),
    ]) {
      if (tags.contains(tag)) {
        replacements[tag] = (await resolveImage(source)).path;
      }
    }
    return RoomGiftAnimationResource(
      format: resource.format,
      videoMode: resource.videoMode,
      bytes: resource.bytes,
      file: resource.file,
      replacements: Map.unmodifiable(replacements),
    );
  }

  /// Uses the same anonymous bounded file cache for native dynamic-image slots.
  Future<File> resolveImage(String source) async {
    try {
      return await _readFile(AppAssets.roomGiftLocalImages[source] ?? source);
    } catch (_) {
      return _readFile(AppAssets.iconMissing);
    }
  }

  Future<Set<String>> _vapTags(File file) async {
    final bytes = await file.readAsBytes();
    for (var i = 4; i < bytes.length - 4; i++) {
      if (bytes[i] != 118 ||
          bytes[i + 1] != 97 ||
          bytes[i + 2] != 112 ||
          bytes[i + 3] != 99) {
        continue;
      }
      final size = ByteData.sublistView(bytes, i - 4, i).getUint32(0);
      if (size < 8 || i - 4 + size > bytes.length) continue;
      try {
        final json = giftMap(
          jsonDecode(utf8.decode(bytes.sublist(i + 4, i - 4 + size))),
        );
        final src = json['src'];
        return src is List
            ? src
                  .map(giftMap)
                  .map((value) => '${value['srcTag'] ?? ''}')
                  .toSet()
            : {};
      } catch (_) {
        /* Not a VAP configuration atom. */
      }
    }
    return {};
  }

  static RoomGift luckyAnimation(RoomLuckyGiftResult result) => RoomGift(
    id: result.isJackpot ? -2 : -1,
    name: 'Lucky gift',
    icon: '',
    price: 0,
    isCombo: 0,
    tabId: 0,
    animationUrl: result.isJackpot
        ? AppAssets.roomGiftJackpotEffect
        : AppAssets.roomGiftLuckyEffect,
  );
  static final _cache = CacheManager(
    Config(
      'roomGiftEffectsV1',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 60,
    ),
  );
  static const maxResourceBytes = 32 * 1024 * 1024;

  Future<void> evict(RoomGift gift) async {
    final source =
        AppAssets.roomGiftLocalAnimations[gift.id] ?? gift.animationUrl ?? '';
    if (source.isNotEmpty) await _cache.removeFile(source);
  }

  static RoomGiftAnimationFormat formatFor(RoomGift gift) => formatForSource(
    AppAssets.roomGiftLocalAnimations[gift.id] ?? gift.animationUrl ?? '',
    mp4: gift.animationType == 6,
  );

  static RoomGiftAnimationFormat formatForSource(
    String source, {
    bool mp4 = false,
  }) {
    final path = Uri.tryParse(source)?.path.toLowerCase() ?? '';
    if (path.endsWith('.svga')) return RoomGiftAnimationFormat.svga;
    if (path.endsWith('.pag')) return RoomGiftAnimationFormat.pag;
    if (path.endsWith('.vap')) return RoomGiftAnimationFormat.vap;
    if (path.endsWith('.mp4')) {
      return mp4 ? RoomGiftAnimationFormat.mp4 : RoomGiftAnimationFormat.vap;
    }
    return RoomGiftAnimationFormat.native;
  }

  Future<RoomGiftAnimationResource> resolve(RoomGift gift) => resolveSource(
    AppAssets.roomGiftLocalAnimations[gift.id] ?? gift.animationUrl ?? '',
    format: formatFor(gift),
    mode: (gift.videoMode ?? gift.direction ?? 1).clamp(0, 4),
  );

  /// Shares the bounded, anonymous CDN cache with other room artwork.
  Future<RoomGiftAnimationResource> resolveSource(
    String source, {
    required RoomGiftAnimationFormat format,
    int mode = 1,
  }) async {
    if (format == RoomGiftAnimationFormat.native) {
      return RoomGiftAnimationResource(format: format, videoMode: mode);
    }
    final file = await _readFile(source);
    return RoomGiftAnimationResource(
      format: format,
      videoMode: mode,
      file: file,
      bytes:
          format == RoomGiftAnimationFormat.svga ||
              format == RoomGiftAnimationFormat.pag
          ? await file.readAsBytes()
          : null,
    );
  }

  Future<File> _readFile(String source) async {
    File file;
    if (source.startsWith('assets/')) {
      final bytes = (await rootBundle.load(source)).buffer.asUint8List();
      file = await _cache.putFile(
        source,
        bytes,
        fileExtension: Uri.parse(source).path.split('.').last,
      );
    } else {
      final uri = Uri.tryParse(source);
      if (uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme)) {
        throw const FormatException('Invalid gift animation URL');
      }
      file = await _cache
          .getSingleFile(source)
          .timeout(const Duration(seconds: 15));
    }
    if (await file.length() > maxResourceBytes) {
      await _cache.removeFile(source);
      throw const FormatException('Gift resource too large');
    }
    return file;
  }
}
