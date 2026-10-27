import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'five Nady music images are bundled, unchanged, visible and documented',
    () async {
      const images = <String, (String, String)>{
        AppAssets.roomMusicSingle: (
          'room_music_single.webp',
          'abdf48a64bfdc987bc6281bc05d52e33f01f2705af3d62f053147f4cac09e249',
        ),
        AppAssets.roomMusicShuffle: (
          'room_music_random.webp',
          '7b0c86996c17c014caaf2948bd80217419ee88d10c4e41027c9304ca7ed6a923',
        ),
        AppAssets.roomMusicStop: (
          'room_music_close.webp',
          '7cdd9067b840a00d71b538bfc8c3346a4cf4e05af4395c222c95c4883e69a6f3',
        ),
        AppAssets.roomMusicDelete: (
          'room_music_player_delete.webp',
          '1c210f7837a43acd0c10d068aa2980fe0efec886b10bfc6cc715d161ea7f557c',
        ),
        AppAssets.roomMusicSearch: (
          'invite_details_search.webp',
          'f9b9c6b3f6f476f516f4c0a26ed6cc194b3f3ada393a45cb1b347842b6e890c9',
        ),
      };
      final bundle = await AssetManifest.loadFromAssetBundle(rootBundle);
      final manifest =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/lanhu/room/lanhu_room_assets_manifest.json',
                ),
              )
              as Map<String, dynamic>;
      expect(manifest.containsKey('music_controls_missing'), isFalse);
      expect(images, hasLength(5));
      for (final entry in images.entries) {
        final asset = entry.key;
        expect(asset, isNot(AppAssets.iconMissing));
        expect(asset, isNot(AppAssets.lanhuRoomIconMissing));
        expect(bundle.listAssets(), contains(asset));
        final source = manifest[asset.split('/').last] as String;
        expect(source, contains('Nady'));
        expect(source, contains(entry.value.$1));
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        expect(sha256.convert(bytes).toString(), entry.value.$2);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0));
        expect(frame.image.height, greaterThan(0));
        final pixels = (await frame.image.toByteData())!;
        expect(
          [for (var i = 3; i < pixels.lengthInBytes; i += 4) pixels.getUint8(i)]
              .any((alpha) => alpha > 0),
          isTrue,
        );
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
}
