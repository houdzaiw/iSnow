import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../theme/app_theme.dart';
import '../../wallet/wallet_page.dart';
import '../../web/web_bridge_view_model.dart';
import '../room_repository.dart';
import 'room_game_view_model.dart';
import 'room_tool_navigation.dart';
import 'room_tools_config.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';

bool _gameOpen = false;
Future<void> openRoomGame(
  BuildContext context,
  WidgetRef ref,
  String roomId,
  String url,
  String title,
) async {
  if (_gameOpen) return;
  _gameOpen = true;
  String? result;
  try {
    result = await pushRoomTool<String>(
      context,
      RoomGamePage(roomId: roomId, url: url, title: title),
    );
  } finally {
    _gameOpen = false;
  }
  if (context.mounted && (result == 'gift' || result == 'backpack')) {
    await openRoomToolGift(
      context,
      ref,
      roomId,
      backpack: result == 'backpack',
    );
  }
}

class RoomGamePage extends HookConsumerWidget {
  const RoomGamePage({
    super.key,
    required this.roomId,
    required this.url,
    required this.title,
  });
  final String roomId, url, title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      roomId: roomId,
      url: url,
      language: Localizations.localeOf(context).languageCode,
    );
    final launch = ref.watch(roomGameViewModelProvider(key));
    final request = launch.asData?.value;
    final controller = useMemoized(
      () => request == null ? null : WebViewController(),
      [request],
    );
    final ratio = useState<double?>(null);
    final failed = useState<String?>(null);
    final alive = useRef(true);
    final paying = useRef(false);
    final trusted = useRef(false);
    final webEpoch = useRef(0);
    final bridge = ref.read(webBridgeViewModelProvider);
    final integration = ref.watch(roomToolsConfigProvider);
    final room = ref.read(roomRepositoryProvider);
    final consumer = useMemoized(
      () => 'room-game-${identityHashCode(Object())}',
      [roomId, url],
    );
    final generation = useMemoized(() => room.roomGeneration, [roomId]);
    bool valid() =>
        alive.value &&
        context.mounted &&
        room.roomGeneration == generation &&
        room.roomState.currentRoomId == roomId &&
        room.roomState.isInRoom;
    Future<void> safeRun(String javascript) async {
      if (!valid() || !trusted.value || controller == null) return;
      try {
        await controller.runJavaScript(javascript);
      } catch (error) {
        debugPrint('[RoomGame] JavaScript call failed: $error');
      }
    }

    Future<void> callback(String type, String callbackKey, Object? data) async {
      if (!valid() || !trusted.value) return;
      await safeRun(
        'if(window.nadyBridgeCallback){window.nadyBridgeCallback(${jsonEncode(type)},${jsonEncode(callbackKey)},${jsonEncode(data is String ? data : jsonEncode(data))});}',
      );
    }

    Future<void> wallet() async {
      if (!valid() || !trusted.value || paying.value) return;
      paying.value = true;
      final epoch = webEpoch.value;
      try {
        final paid = await pushRoomTool<bool>(
          context,
          const WalletPage(returnOnPayment: true),
        );
        if (paid != true ||
            !valid() ||
            !trusted.value ||
            epoch != webEpoch.value) {
          return;
        }
        await callback('paymentCallerSuccess', '', const {});
        if (valid()) {
          await safeRun(
            "if(window.HttpTool&&window.HttpTool.NativeToJs){window.HttpTool.NativeToJs('recharge');}if(window.rechargeSuccess){window.rechargeSuccess();}",
          );
        }
      } finally {
        paying.value = false;
      }
    }

    Future<void> closeGame({bool? backpack}) async {
      if (!valid() || !trusted.value) return;
      Navigator.of(context).pop(
        backpack == null
            ? null
            : backpack
            ? 'backpack'
            : 'gift',
      );
    }

    Future<void> handle(String channel, JavaScriptMessage message) async {
      if (!valid() || !trusted.value) return;
      final map = toolMap(message.message);
      final type = '${map['type'] ?? map['name'] ?? ''}';
      final callbackKey = '${map['key'] ?? ''}';
      switch (type) {
        case 'apiCaller':
          final epoch = webEpoch.value;
          final result = await bridge.callApi(
            toolMap(map['data']),
            language: key.language,
            sourceUri: launch.asData?.value ?? Uri(),
          );
          if (epoch != webEpoch.value) return;
          await callback(
            result.isSuccess ? 'apiCaller' : 'apiCallerError',
            callbackKey,
            result.isSuccess ? result.data : result.error,
          );
        case 'openGiftPanel':
          await closeGame(backpack: false);
        case 'openGiftPanelBackPack':
          await closeGame(backpack: true);
        case 'paymentCaller':
        case 'clickRecharge':
        case 'recharge':
        case 'insufficient':
          await wallet();
        case 'close':
        case 'newTppClose':
        case 'closeGame':
          await closeGame();
        case 'getAppInfo':
          await callback(
            type,
            callbackKey,
            bridge.appInfo(statusBarHeight: MediaQuery.paddingOf(context).top),
          );
        case 'log':
          break;
        default:
          break;
      }
    }

    useEffect(() {
      if (request == null || controller == null) return null;
      alive.value = true;
      trusted.value = true;
      final features = ref.read(roomToolsControllerProvider(roomId).notifier);
      features.gameOpened(request.queryParameters['gameId']);
      final uid = features.uid;
      if (uid != null) unawaited(room.acquireGame(consumer, uid));
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.cardBackground)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              webEpoch.value++;
              trusted.value = integration.trustedGame(
                Uri.tryParse(url) ?? Uri(),
              );
            },
            onNavigationRequest: (navigation) {
              final next = Uri.tryParse(navigation.url);
              final allowed = next != null && integration.trustedGame(next);
              if (navigation.isMainFrame && allowed) trusted.value = true;
              return allowed
                  ? NavigationDecision.navigate
                  : NavigationDecision.prevent;
            },
            onWebResourceError: (error) {
              if (valid() && error.isForMainFrame == true) {
                failed.value = error.description;
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'nadyBridge',
          onMessageReceived: (message) =>
              unawaited(handle('nadyBridge', message)),
        )
        ..addJavaScriptChannel(
          'Flutter',
          onMessageReceived: (message) => unawaited(handle('Flutter', message)),
        )
        ..addJavaScriptChannel(
          'yomi',
          onMessageReceived: (message) => unawaited(handle('yomi', message)),
        )
        ..addJavaScriptChannel(
          'pay',
          onMessageReceived: (_) => unawaited(wallet()),
        )
        ..addJavaScriptChannel(
          'closeGame',
          onMessageReceived: (_) => unawaited(closeGame()),
        )
        ..addJavaScriptChannel(
          'webviewinfo',
          onMessageReceived: (message) {
            if (valid() && trusted.value) {
              ratio.value = gameHeightRatio(toolMap(message.message)['ratio']);
            }
          },
        )
        ..loadRequest(request);
      final subscription = room.socketMessages.listen((message) {
        if (!valid() ||
            !trusted.value ||
            message.event != 'FruitMachineEvent' ||
            !(message.channel == 'game' ||
                message.channel ==
                    'game:${ref.read(roomToolsControllerProvider(roomId).notifier).uid}')) {
          return;
        }
        unawaited(
          callback('longLinkCall', '', {
            'event': message.event,
            'payload': message.payload,
          }),
        );
      });
      final observer = _GameLifecycle((resumed) {
        if (valid() && trusted.value) {
          unawaited(
            safeRun(
              'if(window.appOn${resumed ? 'Resume' : 'Pause'}){window.appOn${resumed ? 'Resume' : 'Pause'}();}',
            ),
          );
        }
      });
      WidgetsBinding.instance.addObserver(observer);
      return () {
        alive.value = false;
        features.gameClosed();
        unawaited(room.releaseGame(consumer));
        WidgetsBinding.instance.removeObserver(observer);
        unawaited(subscription.cancel());
        for (final name in [
          'nadyBridge',
          'Flutter',
          'yomi',
          'pay',
          'closeGame',
          'webviewinfo',
        ]) {
          unawaited(controller.removeJavaScriptChannel(name));
        }
      };
    }, [request]);
    ref.listen(roomToolsControllerProvider(roomId), (_, next) {
      if (!next.sessionActive && alive.value) {
        alive.value = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) dismissOwnedRoomTool(context);
        });
      }
    });
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Image.asset(
            AppAssets.lanhuNavBack,
            width: AppSpacing.iconSizeMd,
          ),
        ),
      ),
      body: launch.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(roomGameViewModelProvider(key)),
            child: Text('$error'),
          ),
        ),
        data: (_) => controller == null
            ? const Center(child: CircularProgressIndicator())
            : failed.value != null
            ? Center(
                child: TextButton(
                  onPressed: () {
                    failed.value = null;
                    controller.reload();
                  },
                  child: Text(failed.value!),
                ),
              )
            : LayoutBuilder(
                builder: (_, constraints) => Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: ratio.value == null
                        ? null
                        : (size.width * ratio.value!).clamp(
                            0.0,
                            constraints.maxHeight,
                          ),
                    child: WebViewWidget(controller: controller),
                  ),
                ),
              ),
      ),
    );
  }
}

class _GameLifecycle with WidgetsBindingObserver {
  _GameLifecycle(this.changed);
  final void Function(bool) changed;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      changed(state == AppLifecycleState.resumed);
}
