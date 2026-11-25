import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import '../party/friends_activity/home_activity_navigation.dart';
import '../profile/mine/profile_menu_item.dart';
import '../profile/tools/profile_tools_widgets.dart';
import '../room/more/room_entry_flow.dart';
import '../room/more/room_game_page.dart';
import '../create_room/create_room_sheet.dart';
import 'profile_web_actions.dart';
import 'profile_web_checkout.dart';
import 'profile_web_share_sheet.dart';
import 'web_bridge_view_model.dart';
import 'web_page_bridge.dart';

class WebViewPage extends HookConsumerWidget {
  const WebViewPage({
    super.key,
    required this.title,
    required this.uri,
    this.hiddenAppBar = false,
  });
  final String title, uri;
  final bool hiddenAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenHomeSessionRoute(context, ref);
    final controller = useMemoized(WebViewController.new);
    final pageTitle = useState(title), hideBar = useState(hiddenAppBar);
    final progress = useState(0);
    final failure = useState<Object?>(null);
    final initialUri = useMemoized(() => Uri.tryParse(uri), [uri]);
    final api = ref.watch(webBridgeViewModelProvider);
    final actions = ref.watch(profileWebActionsProvider);
    final ownedRoutes = useMemoized(() => <Route<dynamic>>{});
    late WebPageBridge bridge;

    Future<T?> owned<T>(Route<T> route) async {
      ownedRoutes.add(route);
      try {
        return await Navigator.of(context, rootNavigator: true).push(route);
      } finally {
        ownedRoutes.remove(route);
      }
    }

    Future<Object?> native(WebNativeRequest request) async {
      bool current() =>
          context.mounted && bridge.alive && request.isCurrent?.call() != false;
      if (!current()) return null;
      switch (request.kind) {
        case WebNativeKind.bar:
          hideBar.value = request.hide;
          if (request.title?.isNotEmpty == true) {
            pageTitle.value = request.title!;
          }
        case WebNativeKind.closeDialog:
          final route = ownedRoutes.lastOrNull;
          if (route?.isActive == true) route!.navigator?.removeRoute(route);
        case WebNativeKind.close:
          if (ModalRoute.of(context)?.isCurrent == true && context.canPop()) {
            context.pop();
          }
        case WebNativeKind.picture:
          return owned<bool>(
            ModalBottomSheetRoute(
              builder: (c) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(c.l10n.t('tools.camera')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(c.l10n.t('tools.album')),
                    ),
                  ],
                ),
              ),
              isScrollControlled: false,
            ),
          );
        case WebNativeKind.share:
          return owned<Map<String, dynamic>>(
            ModalBottomSheetRoute(
              builder: (_) => ProfileWebShareSheet(
                request: request.share!,
                isCurrent: current,
              ),
              isScrollControlled: true,
            ),
          );
        case WebNativeKind.payment:
          return owned<bool>(
            DialogRoute(
              context: context,
              builder: (_) => ProfileWebCheckout(
                product: request.product!,
                isCurrent: current,
              ),
            ),
          );
        case WebNativeKind.game:
          await openRoomGame(context, ref, request.roomId!, request.title!, '');
        case WebNativeKind.lobby:
          final roomId = request.roomId ?? await showCreateRoomSheet(context);
          if (!context.mounted || !current() || roomId == null) return null;
          await enterSharedRoom(
            context,
            ref,
            roomId,
            requestedLobby: request.lobbyType,
            isCurrent: current,
          );
        case WebNativeKind.target:
          if (request.roomId != null) {
            await enterSharedRoom(
              context,
              ref,
              request.roomId!,
              isCurrent: current,
            );
          } else if (request.destination case final destination?) {
            if (destination.kind == ProfileDestinationKind.web) {
              await context.push(
                Uri(
                  path: '/web-view',
                  queryParameters: {'uri': destination.target, 'title': ''},
                ).toString(),
              );
            } else {
              await context.push(destination.target);
            }
          }
      }
      return null;
    }

    bridge = useMemoized(
      () => WebPageBridge(
        api: api,
        actions: actions,
        native: native,
        source: initialUri,
        statusBarHeight: () => MediaQuery.paddingOf(context).top,
        shareOrigin: () {
          final box = context.findRenderObject();
          return box is RenderBox
              ? box.localToGlobal(Offset.zero) & box.size
              : Rect.zero;
        },
        notice: (error, key) {
          if (context.mounted) {
            profileToolsNotice(context, error, key: key ?? 'tools.failed');
          }
        },
        callback: (type, key, payload) async {
          if (!context.mounted) return;
          final encoded = payload is String ? payload : jsonEncode(payload);
          try {
            await controller.runJavaScript(
              'if(window.nadyBridgeCallback){window.nadyBridgeCallback('
              '${jsonEncode(type)},${jsonEncode(key)},${jsonEncode(encoded)});}',
            );
          } catch (_) {
            /* Closing or navigating a WebView can cancel its callback. */
          }
        },
      ),
      [controller, uri, api, actions],
    );

    useEffect(() {
      final request = initialUri;
      if (request == null ||
          !{'http', 'https'}.contains(request.scheme) ||
          request.host.isEmpty ||
          request.userInfo.isNotEmpty) {
        Future.microtask(() {
          if (context.mounted) {
            failure.value = context.l10n.t('tools.unavailable');
          }
        });
        return null;
      }
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              bridge.navigate(url);
              if (context.mounted) failure.value = null;
            },
            onProgress: (value) {
              if (context.mounted) progress.value = value;
            },
            onPageFinished: (_) async {
              if (!context.mounted || pageTitle.value.isNotEmpty) return;
              final title = await controller.getTitle();
              if (context.mounted && title?.isNotEmpty == true) {
                pageTitle.value = title!;
              }
            },
            onWebResourceError: (error) {
              if (context.mounted && error.isForMainFrame == true) {
                failure.value = error.description;
              }
            },
            onNavigationRequest: (request) {
              final target = Uri.tryParse(request.url);
              if (target != null &&
                  {'http', 'https'}.contains(target.scheme) &&
                  target.userInfo.isEmpty) {
                if (request.isMainFrame) bridge.navigate(request.url);
                return NavigationDecision.navigate;
              }
              return request.url == 'about:blank'
                  ? NavigationDecision.navigate
                  : NavigationDecision.prevent;
            },
          ),
        )
        ..addJavaScriptChannel(
          'nadyBridge',
          onMessageReceived: (message) => bridge.handle(message.message),
        )
        ..loadRequest(request);
      return () {
        bridge.dispose();
        unawaited(controller.removeJavaScriptChannel('nadyBridge'));
        final routes = ownedRoutes.toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final route in routes.reversed) {
            if (route.isActive) route.navigator?.removeRoute(route);
          }
        });
      };
    }, [controller, uri, bridge]);

    final body = Stack(
      children: [
        WebViewWidget(controller: controller),
        if (progress.value > 0 && progress.value < 100)
          const LinearProgressIndicator(),
        if (failure.value != null)
          Positioned.fill(
            child: ColoredBox(
              color: ProfileToolsTheme.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileToolsError(
                      error: failure.value,
                      retry: controller.reload,
                    ),
                    TextButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: Text(context.l10n.t('tools.close')),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
    return hideBar.value
        ? Scaffold(backgroundColor: AppColors.cardBackground, body: body)
        : CustomScaffold(
            title: pageTitle.value,
            useGradientBackground: false,
            body: body,
          );
  }
}
