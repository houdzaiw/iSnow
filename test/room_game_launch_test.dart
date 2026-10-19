import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/room/more/room_game_view_model.dart';
import 'package:project/classes/room/more/room_tools_config.dart';
import 'package:project/classes/room/more/room_tools_repository.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/manager/http_api.dart';

import 'support/room_tools_fakes.dart';

void main() {
  for (final yomi in [false, true]) {
    test('game URL uses userNo, not account UID; yomi=$yomi', () async {
      final room = ToolsRoomFake();
      final api = ToolsApiFake();
      addTearDown(room.dispose);
      api.responses[HttpApi.gameToken] = 'game-token';
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(room),
          roomToolsRepositoryProvider.overrideWithValue(api),
          roomToolsConfigProvider.overrideWithValue(_GameConfig(yomi)),
        ],
      );
      addTearDown(container.dispose);
      final key = (
        roomId: '123',
        url:
            r'https://games.example/play?roomId=${roomId}&language=${language}&gameId=77#table',
        language: 'en',
      );
      final keep = container.listen(roomGameViewModelProvider(key), (_, _) {});
      addTearDown(keep.close);
      final uri = await container.read(roomGameViewModelProvider(key).future);
      expect(uri.queryParameters[yomi ? 'platUserId' : 'uid'], '987');
      expect(
        uri.queryParameters[yomi ? 'platAuthCode' : 'token'],
        'game-token',
      );
      expect(uri.queryParameters['roomId'], '123');
      expect(uri.fragment, 'table');
    });
  }
  test('late game token cannot launch in a replacement room session', () async {
    final room = ToolsRoomFake();
    final api = ToolsApiFake();
    addTearDown(room.dispose);
    api.heldPath = HttpApi.gameToken;
    api.gate = Completer();
    final container = ProviderContainer(
      overrides: [
        roomRepositoryProvider.overrideWithValue(room),
        roomToolsRepositoryProvider.overrideWithValue(api),
        roomToolsConfigProvider.overrideWithValue(_GameConfig(false)),
      ],
    );
    addTearDown(container.dispose);
    const key = (
      roomId: '123',
      url: 'https://games.example/play',
      language: 'en',
    );
    final keep = container.listen(roomGameViewModelProvider(key), (_, _) {});
    addTearDown(keep.close);
    final pending = container.read(roomGameViewModelProvider(key).future);
    await flushTools();
    room.generation++;
    api.gate!.complete('old-token');
    await expectLater(pending, throwsStateError);
  });
}

class _GameConfig extends RoomToolsConfig {
  const _GameConfig(this.yomi);
  final bool yomi;
  @override
  String get apiBase => 'https://api.example/simi';
  @override
  Set<String> get gameHosts => {'games.example'};
  @override
  Set<String> get yomiHosts => yomi ? {'games.example'} : {};
}
