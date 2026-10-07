import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../theme/app_theme.dart';
import '../models/room_gift_models.dart';
import '../models/room_gift_event_models.dart';

enum RoomGiftAnimationFormat { native, svga, mp4, vap, pag }

class RoomGiftAnimationResource {
  const RoomGiftAnimationResource({
    required this.format,
    required this.videoMode,
    this.bytes,
    this.file,
  });
  final RoomGiftAnimationFormat format;
  final int videoMode;
  final Uint8List? bytes;
  final File? file;
}

final roomGiftAssetResolverProvider = Provider<RoomGiftAssetResolver>(
  (ref) => RoomGiftAssetResolver(),
);
final roomGiftAnimationProvider = FutureProvider.autoDispose
    .family<RoomGiftAnimationResource, RoomGift>((ref, gift) {
      return ref.watch(roomGiftAssetResolverProvider).resolve(gift);
    });

/// Separate, bounded CDN file cache. Never sends Nady credentials to resource hosts.
class RoomGiftAssetResolver {
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

  static RoomGiftAnimationFormat formatFor(RoomGift gift) {
    final source =
        AppAssets.roomGiftLocalAnimations[gift.id] ?? gift.animationUrl ?? '';
    final path = Uri.tryParse(source)?.path.toLowerCase() ?? '';
    if (path.endsWith('.svga')) return RoomGiftAnimationFormat.svga;
    if (path.endsWith('.pag')) return RoomGiftAnimationFormat.pag;
    if (path.endsWith('.vap')) return RoomGiftAnimationFormat.vap;
    if (path.endsWith('.mp4')) {
      return gift.animationType == 6
          ? RoomGiftAnimationFormat.mp4
          : RoomGiftAnimationFormat.vap;
    }
    return RoomGiftAnimationFormat.native;
  }

  Future<RoomGiftAnimationResource> resolve(RoomGift gift) async {
    final format = formatFor(gift);
    final mode = (gift.videoMode ?? gift.direction ?? 1).clamp(0, 4);
    if (format == RoomGiftAnimationFormat.native) {
      return RoomGiftAnimationResource(format: format, videoMode: mode);
    }
    final source =
        AppAssets.roomGiftLocalAnimations[gift.id] ?? gift.animationUrl ?? '';
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
}
