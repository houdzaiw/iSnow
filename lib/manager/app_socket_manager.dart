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
  AppSocketManager._();

  static final AppSocketManager instance = AppSocketManager._();

  final HttpDioManager _httpManager = HttpDioManager();
  final StreamController<RoomSocketMessage> _messageController =
      StreamController<RoomSocketMessage>.broadcast();
  final Map<String, centrifuge.Subscription> _subscriptions = {};
  final Map<String, List<StreamSubscription<dynamic>>> _subscriptionListeners =
      {};
  final List<StreamSubscription<dynamic>> _clientListeners = [];

  centrifuge.Client? _client;
  String? _socketUrl;
  AppSocketState _state = const AppSocketState();

  AppSocketState get state => _state;
  Stream<RoomSocketMessage> get messages => _messageController.stream;

  Future<void> connect({required String url}) async {
    final client = _client;
    if (client != null && _socketUrl == url) {
      if (client.state == centrifuge.State.connected) {
        _setState(_state.copyWith(status: AppSocketStatus.connected));
        return;
      }
      if (client.state == centrifuge.State.connecting) {
        await client.ready();
        _setState(_state.copyWith(status: AppSocketStatus.connected));
        return;
      }
    }

    await close();
    _socketUrl = url;
    _setState(const AppSocketState(status: AppSocketStatus.connecting));

    final newClient = centrifuge.createClient(
      url,
      centrifuge.ClientConfig(getToken: (_) => _fetchConnectionToken()),
    );
    _client = newClient;
    _bindClient(newClient);

    try {
      await newClient.connect();
      await newClient.ready().timeout(const Duration(seconds: 12));
      _setState(_state.copyWith(status: AppSocketStatus.connected));
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

  Future<void> joinRoom(String roomId, {required String url}) async {
    await connect(url: url);
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
    await _subscribeChannel(client, roomChannel);

    var broadcastSubscribed = false;
    try {
      await _subscribeChannel(client, 'room');
      broadcastSubscribed = true;
    } catch (error) {
      debugPrint('Room broadcast socket subscribe failed: $error');
    }

    _setState(
      _state.copyWith(
        status: AppSocketStatus.ready,
        roomId: roomId,
        roomChannelSubscribed: true,
        broadcastChannelSubscribed: broadcastSubscribed,
        subscribedChannels: _subscriptions.keys.toList(growable: false),
      ),
    );
  }

  Future<void> leaveRoom(String roomId) async {
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
    await leaveCurrentRoomSubscriptions();
    await _client?.disconnect();
    _setState(const AppSocketState(status: AppSocketStatus.disconnected));
  }

  Future<void> close() async {
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

  Future<void> leaveCurrentRoomSubscriptions() async {
    final channels = _subscriptions.keys.toList(growable: false);
    for (final channel in channels) {
      await _unsubscribeChannel(channel);
    }
  }

  void _bindClient(centrifuge.Client client) {
    _clientListeners
      ..add(
        client.connected.listen(
          (_) => _setState(_state.copyWith(status: AppSocketStatus.connected)),
        ),
      )
      ..add(
        client.disconnected.listen(
          (_) =>
              _setState(_state.copyWith(status: AppSocketStatus.disconnected)),
        ),
      )
      ..add(
        client.error.listen(
          (event) => _setState(
            _state.copyWith(
              status: AppSocketStatus.error,
              errorMessage: event.error.toString(),
            ),
          ),
        ),
      );
  }

  Future<void> _subscribeChannel(
    centrifuge.Client client,
    String channel,
  ) async {
    if (_subscriptions.containsKey(channel)) return;

    final subscription = client.newSubscription(
      channel,
      centrifuge.SubscriptionConfig(
        getToken: (event) => _fetchChannelToken(event.channel),
      ),
    );

    final subscribed = subscription.subscribed.first.timeout(
      const Duration(seconds: 12),
    );
    final listeners = <StreamSubscription<dynamic>>[
      subscription.publication.listen(
        (event) => _handlePublication(channel, event),
      ),
      subscription.error.listen(
        (event) => _setState(
          _state.copyWith(
            status: AppSocketStatus.error,
            errorMessage: event.error.toString(),
          ),
        ),
      ),
    ];
    _subscriptions[channel] = subscription;
    _subscriptionListeners[channel] = listeners;

    try {
      await subscription.subscribe();
      await subscribed;
      _setState(
        _state.copyWith(
          subscribedChannels: _subscriptions.keys.toList(growable: false),
        ),
      );
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
  }

  void _handlePublication(String channel, centrifuge.PublicationEvent event) {
    final rawText = utf8.decode(event.data, allowMalformed: true);
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map) {
        _messageController.add(
          RoomSocketMessage.fromJson(
            decoded.cast<String, dynamic>(),
            channel: channel,
          ),
        );
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
    final response = await _httpManager.get(
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
    _state = value;
    notifyListeners();
  }
}

const Object _sentinel = Object();
