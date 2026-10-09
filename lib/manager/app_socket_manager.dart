import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';

import '../model/room_socket_message.dart';
import '../model/server_response.dart';
import 'http_api.dart';
import 'http_dio_manager.dart';

enum AppSocketStatus {
  idle,
  connecting,
  connected,
  subscribing,
  ready,
  disconnected,
  error,
}

class AppSocketState {
  const AppSocketState({
    this.status = AppSocketStatus.idle,
    this.roomId,
    this.roomChannelSubscribed = false,
    this.broadcastChannelSubscribed = false,
    this.subscribedChannels = const [],
    this.errorMessage,
  });

  final AppSocketStatus status;
  final String? roomId;
  final bool roomChannelSubscribed;
  final bool broadcastChannelSubscribed;
  final List<String> subscribedChannels;
  final String? errorMessage;

  bool get isConnected =>
      status == AppSocketStatus.connected ||
      status == AppSocketStatus.subscribing ||
      status == AppSocketStatus.ready;

  AppSocketState copyWith({
    AppSocketStatus? status,
    String? roomId,
    bool? clearRoomId,
    bool? roomChannelSubscribed,
    bool? broadcastChannelSubscribed,
    List<String>? subscribedChannels,
    Object? errorMessage = _sentinel,
  }) {
    return AppSocketState(
      status: status ?? this.status,
      roomId: clearRoomId == true ? null : roomId ?? this.roomId,
      roomChannelSubscribed:
          roomChannelSubscribed ?? this.roomChannelSubscribed,
      broadcastChannelSubscribed:
          broadcastChannelSubscribed ?? this.broadcastChannelSubscribed,
      subscribedChannels: subscribedChannels ?? this.subscribedChannels,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AppSocketManager extends ChangeNotifier {
  AppSocketManager._({
    centrifuge.Client Function(String, centrifuge.ClientConfig)? clientFactory,
    Future<dynamic> Function(String, {Map<String, dynamic>? queryParameters})?
    get,
  }) : _clientFactory = clientFactory ?? centrifuge.createClient,
       _get = get;

  @visibleForTesting
  AppSocketManager.forTesting({
    required centrifuge.Client Function(String, centrifuge.ClientConfig)
    clientFactory,
    required Future<dynamic> Function(
      String, {
      Map<String, dynamic>? queryParameters,
    })
    get,
  }) : this._(clientFactory: clientFactory, get: get);

  static final AppSocketManager instance = AppSocketManager._();

  final HttpDioManager _httpManager = HttpDioManager();
  final centrifuge.Client Function(String, centrifuge.ClientConfig)
  _clientFactory;
  final Future<dynamic> Function(
    String, {
    Map<String, dynamic>? queryParameters,
  })?
  _get;
  final StreamController<RoomSocketMessage> _messageController =
      StreamController<RoomSocketMessage>.broadcast();
  final Map<String, centrifuge.Subscription> _subscriptions = {};
  final Map<String, List<StreamSubscription<dynamic>>> _subscriptionListeners =
      {};
  final List<StreamSubscription<dynamic>> _clientListeners = [];

  centrifuge.Client? _client;
  String? _socketUrl;
  int _roomJoinGeneration = 0;
  AppSocketState _state = const AppSocketState();

  AppSocketState get state => _state;
  Stream<RoomSocketMessage> get messages => _messageController.stream;

  Future<void> connect({required String url}) async {
    final client = _client;
    if (client != null && _socketUrl == url) {
      if (client.state == centrifuge.State.connected) {
        _syncConnectedState();
        return;
      }
      if (client.state == centrifuge.State.connecting) {
        await client.ready().timeout(const Duration(seconds: 12));
        _syncConnectedState();
        return;
      }
    }

    await close(invalidateRoomJoin: false);
    _socketUrl = url;
    _setState(const AppSocketState(status: AppSocketStatus.connecting));

    final newClient = _clientFactory(
      url,
      centrifuge.ClientConfig(getToken: (_) => _fetchConnectionToken()),
    );
    _client = newClient;
    _bindClient(newClient);

    try {
      await newClient.connect().timeout(const Duration(seconds: 12));
      await newClient.ready().timeout(const Duration(seconds: 12));
      _syncConnectedState();
    } catch (error) {
      _setState(
        _state.copyWith(
          status: AppSocketStatus.error,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId, {String? url}) async {
    final generation = ++_roomJoinGeneration;
    try {
      // Nady resolves this from the API environment, not the website host.
      final endpoint =
          url ?? _socketUrl ?? await _fetchString(HttpApi.longLinkUrl);
      if (!_isActiveRoomJoin(generation)) return;
      final uri = Uri.tryParse(endpoint);
      if (uri == null ||
          !{'ws', 'wss'}.contains(uri.scheme) ||
          uri.host.isEmpty) {
        throw const NadyApiException(message: 'Invalid WebSocket endpoint');
      }
      _log('connect endpoint=${uri.scheme}://${uri.host}${uri.path}');
      await connect(url: endpoint);
    } catch (error) {
      if (_isActiveRoomJoin(generation)) {
        _setState(
          _state.copyWith(
            status: AppSocketStatus.error,
            errorMessage: error.toString(),
          ),
        );
      }
      rethrow;
    }
    if (!_isActiveRoomJoin(generation)) return;
    final client = _client;
    if (client == null) {
      throw const NadyApiException(message: 'Socket client is not ready');
    }

    _setState(
      _state.copyWith(
        status: AppSocketStatus.subscribing,
        roomId: roomId,
        roomChannelSubscribed: false,
        broadcastChannelSubscribed: false,
        subscribedChannels: const [],
        errorMessage: null,
      ),
    );

    final roomChannel = 'room:$roomId';
    try {
      await _subscribeChannel(client, roomChannel);
    } catch (error) {
      if (_isActiveRoomJoin(generation)) {
        _setState(
          _state.copyWith(
            status: AppSocketStatus.error,
            errorMessage: error.toString(),
          ),
        );
      }
      rethrow;
    }
    if (!_isActiveRoomJoin(generation)) {
      await _unsubscribeChannel(roomChannel);
      return;
    }

    try {
      await _subscribeChannel(client, 'room');
    } catch (error) {
      _log('optional channel=room subscribe failed: $error');
    }
    if (!_isActiveRoomJoin(generation)) {
      await _unsubscribeChannel(roomChannel);
      return;
    }

    _syncConnectedState();
  }

  Future<void> leaveRoom(String roomId) async {
    _roomJoinGeneration += 1;
    await _unsubscribeChannel('room:$roomId');
    await _unsubscribeChannel('room');
    _setState(
      _state.copyWith(
        status: _client?.state == centrifuge.State.connected
            ? AppSocketStatus.connected
            : AppSocketStatus.disconnected,
        clearRoomId: true,
        roomChannelSubscribed: false,
        broadcastChannelSubscribed: false,
        subscribedChannels: const [],
        errorMessage: null,
      ),
    );
  }

  Future<void> disconnect() async {
    _roomJoinGeneration += 1;
    await leaveCurrentRoomSubscriptions();
    await _client?.disconnect();
    _setState(const AppSocketState(status: AppSocketStatus.disconnected));
  }

  Future<void> close({bool invalidateRoomJoin = true}) async {
    if (invalidateRoomJoin) {
      _roomJoinGeneration += 1;
    }
    await leaveCurrentRoomSubscriptions();
    for (final listener in _clientListeners) {
      await listener.cancel();
    }
    _clientListeners.clear();
    await _client?.close();
    _client = null;
    _socketUrl = null;
    _setState(const AppSocketState(status: AppSocketStatus.idle));
  }

  bool _isActiveRoomJoin(int generation) {
    return generation == _roomJoinGeneration;
  }

  Future<void> leaveCurrentRoomSubscriptions() async {
    final channels = _subscriptions.keys.toList(growable: false);
    for (final channel in channels) {
      await _unsubscribeChannel(channel);
    }
  }

  void _bindClient(centrifuge.Client client) {
    _clientListeners
      ..add(
        client.connected.listen((_) {
          if (identical(client, _client)) _syncConnectedState();
        }),
      )
      ..add(
        client.connecting.listen((_) {
          if (!identical(client, _client)) return;
          _setState(
            _state.copyWith(
              status: AppSocketStatus.connecting,
              roomChannelSubscribed: false,
              broadcastChannelSubscribed: false,
              subscribedChannels: const [],
            ),
          );
        }),
      )
      ..add(
        client.disconnected.listen((_) {
          if (!identical(client, _client)) return;
          _setState(
            _state.copyWith(
              status: AppSocketStatus.disconnected,
              roomChannelSubscribed: false,
              broadcastChannelSubscribed: false,
              subscribedChannels: const [],
            ),
          );
        }),
      )
      ..add(
        client.error.listen((event) {
          if (!identical(client, _client)) return;
          _log('connection error: ${event.error}');
          _setState(
            _state.copyWith(
              status: AppSocketStatus.error,
              errorMessage: event.error.toString(),
            ),
          );
        }),
      );
  }

  Future<void> _subscribeChannel(
    centrifuge.Client client,
    String channel,
  ) async {
    final existing = _subscriptions[channel];
    if (existing != null) {
      await existing.ready().timeout(const Duration(seconds: 12));
      _syncConnectedState();
      return;
    }

    final subscription = client.newSubscription(
      channel,
      centrifuge.SubscriptionConfig(
        getToken: (event) => _fetchChannelToken(event.channel),
      ),
    );

    final listeners = <StreamSubscription<dynamic>>[
      subscription.subscribed.listen((_) => _syncConnectedState()),
      subscription.subscribing.listen((_) => _syncConnectedState()),
      subscription.unsubscribed.listen((event) {
        _log('unsubscribed channel=$channel code=${event.code}');
        _syncConnectedState();
      }),
      subscription.publication.listen(
        (event) => _handlePublication(channel, event),
      ),
      subscription.error.listen((event) {
        _log('subscription error channel=$channel: ${event.error}');
        // Optional broadcasts must not disable the live room channel.
        _syncConnectedState();
      }),
    ];
    _subscriptions[channel] = subscription;
    _subscriptionListeners[channel] = listeners;

    try {
      await subscription.subscribe().timeout(const Duration(seconds: 12));
      await subscription.ready().timeout(const Duration(seconds: 12));
      _syncConnectedState();
    } catch (_) {
      await _unsubscribeChannel(channel);
      rethrow;
    }
  }

  Future<void> _unsubscribeChannel(String channel) async {
    final subscription = _subscriptions.remove(channel);
    final listeners = _subscriptionListeners.remove(channel);
    if (listeners != null) {
      for (final listener in listeners) {
        await listener.cancel();
      }
    }
    await subscription?.unsubscribe();
    if (subscription != null) await _client?.removeSubscription(subscription);
    _syncConnectedState();
  }

  void _syncConnectedState() {
    final connected = _client?.state == centrifuge.State.connected;
    final channels = connected
        ? _subscriptions.entries
              .where(
                (entry) =>
                    entry.value.state ==
                    centrifuge.SubscriptionState.subscribed,
              )
              .map((entry) => entry.key)
              .toList(growable: false)
        : <String>[];
    final roomReady =
        _state.roomId != null && channels.contains('room:${_state.roomId}');
    _setState(
      _state.copyWith(
        status: !connected
            ? (_client?.state == centrifuge.State.connecting
                  ? AppSocketStatus.connecting
                  : AppSocketStatus.disconnected)
            : roomReady
            ? AppSocketStatus.ready
            : _state.roomId != null
            ? AppSocketStatus.subscribing
            : AppSocketStatus.connected,
        roomChannelSubscribed: roomReady,
        broadcastChannelSubscribed: channels.contains('room'),
        subscribedChannels: channels,
        errorMessage: null,
      ),
    );
  }

  void _handlePublication(String channel, centrifuge.PublicationEvent event) {
    final rawText = utf8.decode(event.data, allowMalformed: true);
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map) {
        final message = RoomSocketMessage.fromJson(
          decoded.cast<String, dynamic>(),
          channel: channel,
        );
        _log(
          'receive channel=$channel event=${message.event} '
          'msgId=${message.msgId} timestamp=${message.timestamp} '
          'payloadType=${message.payload.runtimeType} bytes=${event.data.length}',
        );
        _messageController.add(message);
        return;
      }
      _messageController.add(
        RoomSocketMessage(
          channel: channel,
          event: '',
          payload: decoded,
          raw: {'payload': decoded},
        ),
      );
    } catch (error) {
      debugPrint('Room socket publication parse failed: $error');
      _messageController.add(
        RoomSocketMessage(
          channel: channel,
          event: '',
          payload: rawText,
          raw: {'payload': rawText},
        ),
      );
    }
  }

  Future<String> _fetchConnectionToken() {
    return _fetchString(HttpApi.longLinkToken);
  }

  Future<String> _fetchChannelToken(String channel) {
    return _fetchString(
      HttpApi.roomSocketToken,
      queryParameters: {'channel': channel},
    );
  }

  Future<String> _fetchString(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await (_get ?? _httpManager.get)(
      path,
      queryParameters: queryParameters,
    );
    final server = NadyServerResponse<String>.fromJson(
      _asMap(response),
      _stringFromJson,
    );
    if (!server.isSuccess) throw server.toException();
    final value = server.data;
    if (value == null || value.isEmpty) {
      throw NadyApiException(message: 'Empty response data for $path');
    }
    return value;
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  String _stringFromJson(Object? json) {
    if (json is Map) {
      return json['token']?.toString() ??
          json['value']?.toString() ??
          json['data']?.toString() ??
          '';
    }
    return json?.toString() ?? '';
  }

  void _setState(AppSocketState value) {
    if (value.status != _state.status ||
        value.roomChannelSubscribed != _state.roomChannelSubscribed ||
        value.broadcastChannelSubscribed != _state.broadcastChannelSubscribed) {
      _log(
        'state=${value.status.name} roomId=${value.roomId} '
        'channels=${value.subscribedChannels}',
      );
    }
    _state = value;
    notifyListeners();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[RoomSocket] $message');
  }
}

const Object _sentinel = Object();
