import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/classes/room/gift/event/room_gift_event_provider.dart';
import 'package:project/classes/room/gift/models/room_gift_models.dart';
import 'package:project/classes/room/room_repository.dart';
import 'package:project/classes/room/viewmodel/room_view_model.dart';
import 'package:project/manager/app_socket_manager.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/manager/room_agora_manager.dart';
import 'package:project/manager/room_manager.dart';
import 'package:project/model/room_socket_message.dart';
import 'package:project/model/user_profile.dart';

import 'room_gift_events_test.dart' show payload;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Client client;
  late AppSocketManager socket;
  late List<String> paths;
  late List<String> endpoints;
  late Map<String, Object?> responses;
  setUp(() {
    client = _Client();
    paths = [];
    endpoints = [];
    responses = {
      HttpApi.longLinkUrl: 'wss://room.dev.test/connection/websocket',
      HttpApi.longLinkToken: 'connection-token',
      HttpApi.roomSocketToken: 'channel-token',
    };
    socket = AppSocketManager.forTesting(
      clientFactory: (url, config) {
        endpoints.add(url);
        return client;
      },
      get: (path, {queryParameters}) async {
        paths.add(path);
        return {'code': 200, 'data': responses[path]};
      },
    );
  });
  tearDown(() async {
    await socket.close();
    socket.dispose();
    await client.disposeStreams();
  });

  test(
    'uses the API environment endpoint instead of the website host',
    () async {
      await socket.joinRoom('123');
      expect(paths.first, HttpApi.longLinkUrl);
      expect(endpoints.single, responses[HttpApi.longLinkUrl]);
      expect(socket.state.status, AppSocketStatus.ready);
      expect(socket.state.subscribedChannels, ['room:123', 'room']);
      await socket.joinRoom('123');
      expect(paths.where((path) => path == HttpApi.longLinkUrl), hasLength(1));
      expect(socket.state.status, AppSocketStatus.ready);
    },
  );

  test('does not connect to an invalid configuration response', () async {
    responses[HttpApi.longLinkUrl] = 'https://website.test';
    await expectLater(socket.joinRoom('123'), throwsA(isA<Exception>()));
    expect(endpoints, isEmpty);
    expect(socket.state.status, AppSocketStatus.error);
  });

  test('leaving during endpoint lookup does not resurrect the room', () async {
    final pending = Completer<dynamic>();
    final delayed = AppSocketManager.forTesting(
      clientFactory: (url, config) => throw StateError('Must not connect'),
      get: (path, {queryParameters}) => pending.future,
    );
    final joining = delayed.joinRoom('123');
    await delayed.leaveRoom('123');
    pending.complete({'code': 200, 'data': 'wss://room.test/socket'});
    await joining;
    expect(delayed.state.roomId, isNull);
    await delayed.close();
    delayed.dispose();
  });

  test(
    'leaving removes the SDK subscriptions so the same room can rejoin',
    () async {
      await socket.joinRoom('123');
      await socket.leaveRoom('123');
      expect(client.channels, isEmpty);
      await socket.joinRoom('123');
      expect(socket.state.roomChannelSubscribed, isTrue);
    },
  );

  test(
    'optional broadcast failure does not disable the room subscription',
    () async {
      client.failedChannel = 'room';
      await socket.joinRoom('123');
      expect(socket.state.status, AppSocketStatus.ready);
      expect(socket.state.roomChannelSubscribed, isTrue);
      expect(socket.state.broadcastChannelSubscribed, isFalse);
      expect(client.channels.keys, ['room:123']);
    },
  );

  test(
    'room subscription failure is reported instead of staying subscribing',
    () async {
      client.failedChannel = 'room:123';
      await expectLater(socket.joinRoom('123'), throwsStateError);
      expect(socket.state.status, AppSocketStatus.error);
      expect(socket.state.roomChannelSubscribed, isFalse);
    },
  );

  test(
    'reconnect restores the actual gift lifecycle and public-screen fanout',
    () async {
      final repository = _RoomRepository(socket);
      final container = ProviderContainer(
        overrides: [roomRepositoryProvider.overrideWithValue(repository)],
      );
      final roomProvider = roomViewModelProvider('123');
      final room = container.listen(roomProvider, (_, __) {});
      final giftProvider = roomGiftEventManagerProvider('123');
      await Future<void>.delayed(Duration.zero);
      // HTTP-confirmed Combo can render while the room is waiting for Socket.
      expect(container.read(giftProvider).isVisible, isTrue);
      await socket.joinRoom('123');
      final channel = client.channels['room:123']!;
      channel.publishGift('before');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(giftProvider).effects, hasLength(1));
      expect(
        container
            .read(roomProvider)
            .messages
            .where((entry) => entry.gift != null),
        hasLength(1),
      );

      client.reconnect();
      expect(socket.state.status, AppSocketStatus.connecting);
      expect(socket.state.roomChannelSubscribed, isFalse);
      expect(container.read(giftProvider).effects, isEmpty);
      client.markConnected();
      expect(socket.state.status, AppSocketStatus.subscribing);
      channel.markSubscribed();
      expect(socket.state.status, AppSocketStatus.ready);
      channel.publishGift('after');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(giftProvider).slots.whereType<Object>(),
        hasLength(1),
      );
      expect(container.read(giftProvider).flights, hasLength(1));
      expect(container.read(giftProvider).effects, hasLength(1));
      expect(
        container
            .read(roomProvider)
            .messages
            .where((entry) => entry.gift != null),
        hasLength(2),
      );
      room.close();
      container.dispose();
    },
  );
}

class _Client implements centrifuge.Client {
  @override
  centrifuge.State state = centrifuge.State.disconnected;
  final connectedEvents = StreamController<centrifuge.ConnectedEvent>.broadcast(
    sync: true,
  );
  final connectingEvents =
      StreamController<centrifuge.ConnectingEvent>.broadcast(sync: true);
  final disconnectedEvents =
      StreamController<centrifuge.DisconnectedEvent>.broadcast(sync: true);
  final errors = StreamController<centrifuge.ErrorEvent>.broadcast(sync: true);
  final Map<String, _Subscription> channels = {};
  final List<_Subscription> created = [];
  String? failedChannel;
  @override
  Stream<centrifuge.ConnectedEvent> get connected => connectedEvents.stream;
  @override
  Stream<centrifuge.ConnectingEvent> get connecting => connectingEvents.stream;
  @override
  Stream<centrifuge.DisconnectedEvent> get disconnected =>
      disconnectedEvents.stream;
  @override
  Stream<centrifuge.ErrorEvent> get error => errors.stream;
  @override
  Future<void> connect() async => markConnected();
  @override
  Future<void> ready() async {}
  @override
  Future<void> disconnect() async => state = centrifuge.State.disconnected;
  @override
  Future<void> close() => disconnect();
  @override
  centrifuge.Subscription newSubscription(
    String channel, [
    centrifuge.SubscriptionConfig? config,
  ]) {
    if (channels.containsKey(channel)) throw StateError('Duplicate channel');
    final sub = _Subscription(channel, fail: channel == failedChannel);
    created.add(sub);
    return channels[channel] = sub;
  }

  @override
  Future<void> removeSubscription(centrifuge.Subscription subscription) async =>
      channels.remove(subscription.channel);
  void markConnected() {
    state = centrifuge.State.connected;
    connectedEvents.add(centrifuge.ConnectedEvent('client', '1', const []));
  }

  void reconnect() {
    for (final sub in channels.values) {
      sub.state = centrifuge.SubscriptionState.subscribing;
      sub.subscribingEvents.add(centrifuge.SubscribingEvent(1, 'reconnecting'));
    }
    state = centrifuge.State.connecting;
    connectingEvents.add(centrifuge.ConnectingEvent(1, 'reconnecting'));
  }

  Future<void> disposeStreams() async {
    await connectedEvents.close();
    await connectingEvents.close();
    await disconnectedEvents.close();
    await errors.close();
    for (final sub in created) {
      await sub.disposeStreams();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Subscription implements centrifuge.Subscription {
  _Subscription(this.channel, {this.fail = false});
  final bool fail;
  @override
  final String channel;
  @override
  centrifuge.SubscriptionState state =
      centrifuge.SubscriptionState.unsubscribed;
  final subscribedEvents =
      StreamController<centrifuge.SubscribedEvent>.broadcast(sync: true);
  final subscribingEvents =
      StreamController<centrifuge.SubscribingEvent>.broadcast(sync: true);
  final unsubscribedEvents =
      StreamController<centrifuge.UnsubscribedEvent>.broadcast(sync: true);
  final publications = StreamController<centrifuge.PublicationEvent>.broadcast(
    sync: true,
  );
  final errors = StreamController<centrifuge.SubscriptionErrorEvent>.broadcast(
    sync: true,
  );
  @override
  Stream<centrifuge.SubscribedEvent> get subscribed => subscribedEvents.stream;
  @override
  Stream<centrifuge.SubscribingEvent> get subscribing =>
      subscribingEvents.stream;
  @override
  Stream<centrifuge.UnsubscribedEvent> get unsubscribed =>
      unsubscribedEvents.stream;
  @override
  Stream<centrifuge.PublicationEvent> get publication => publications.stream;
  @override
  Stream<centrifuge.SubscriptionErrorEvent> get error => errors.stream;
  @override
  Future<void> subscribe() async {
    if (fail) throw StateError('Rejected subscription');
    markSubscribed();
  }

  @override
  Future<void> ready() async {}
  @override
  Future<void> unsubscribe() async =>
      state = centrifuge.SubscriptionState.unsubscribed;
  void markSubscribed() {
    state = centrifuge.SubscriptionState.subscribed;
    subscribedEvents.add(
      centrifuge.SubscribedEvent(false, false, const [], null, false, false),
    );
  }

  void publishGift(String id) => publications.add(
    _Publication(
      utf8.encode(
        jsonEncode({
          'event': 'roomScreenSendGiftComboEvent',
          'payload': payload(combo: id),
          'msgId': id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ),
    ),
  );
  Future<void> disposeStreams() async {
    await subscribedEvents.close();
    await subscribingEvents.close();
    await unsubscribedEvents.close();
    await publications.close();
    await errors.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Publication implements centrifuge.PublicationEvent {
  _Publication(this.data);
  @override
  final List<int> data;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RoomRepository implements RoomRepository {
  _RoomRepository(this.socket);
  final AppSocketManager socket;
  @override
  Stream<RoomSocketMessage> get socketMessages => socket.messages;
  @override
  AppSocketState get socketState => socket.state;
  @override
  RoomState get roomState => const RoomState(
    status: RoomStatus.ready,
    currentRoomId: '123',
    isInRoom: true,
  );
  @override
  RoomAgoraState get agoraState => const RoomAgoraState();
  @override
  void addListener(VoidCallback listener) => socket.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => socket.removeListener(listener);
  @override
  RoomGiftAudience giftAudience(String roomId) =>
      const RoomGiftAudience(isInRoom: true, onlineCount: 2, recipients: []);
  @override
  Future<int?> currentUid() async => 10;
  @override
  Future<UserData?> currentUser() async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
