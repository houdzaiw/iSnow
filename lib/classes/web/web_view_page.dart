import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import 'web_bridge_view_model.dart';

class WebViewPage extends HookConsumerWidget {
  final String title;
  final String uri;
  final bool hiddenAppBar;

  const WebViewPage({
    super.key,
    required this.title,
    required this.uri,
    this.hiddenAppBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(WebViewController.new);
    final pageTitle = useState(title);
    final hideAppBar = useState(hiddenAppBar);
    final progress = useState(0);
    final initialUri = useMemoized(() => Uri.tryParse(uri), [uri]);
    final bridgeViewModel = ref.read(webBridgeViewModelProvider);
    final language = initialUri?.queryParameters['language'];

    Future<void> callH5Function(
      String type,
      String paramsKey,
      Object? data,
    ) async {
      final dataString = data is String ? data : jsonEncode(data);
      final jsCode =
          '''
        if (window.nadyBridgeCallback) {
          window.nadyBridgeCallback(
            ${jsonEncode(type)},
            ${jsonEncode(paramsKey)},
            ${jsonEncode(dataString)}
          );
        }
      ''';
      await controller.runJavaScript(jsCode);
    }

    Future<void> handleBridgeMessage(JavaScriptMessage message) async {
      final params = _decodeMap(message.message);
      if (params == null) {
        debugPrint('WebView nadyBridge invalid message: ${message.message}');
        return;
      }

      final type = params['type']?.toString() ?? '';
      final paramsKey = params['key']?.toString() ?? '';
      final data = _asMap(params['data']) ?? const <String, dynamic>{};

      switch (type) {
        case 'apiCaller':
          final result = await bridgeViewModel.callApi(
            data,
            language: language,
          );
          if (result.isSuccess) {
            await callH5Function('apiCaller', paramsKey, result.data);
          } else {
            await callH5Function('apiCallerError', paramsKey, result.error);
          }
          break;
        case 'getAppInfo':
          await callH5Function(
            'getAppInfo',
            paramsKey,
            bridgeViewModel.appInfo(
              statusBarHeight: MediaQuery.paddingOf(context).top,
            ),
          );
          break;
        case 'paymentList':
          await callH5Function(
            'paymentList',
            paramsKey,
            bridgeViewModel.paymentList(data),
          );
          break;
        case 'changeAppBar':
          hideAppBar.value = _asBool(data['hide']);
          final nextTitle = data['title']?.toString();
          if (nextTitle != null && nextTitle.isNotEmpty) {
            pageTitle.value = nextTitle;
          }
          break;
        case 'close':
          if (context.mounted && context.canPop()) {
            context.pop();
          }
          break;
        case 'log':
          debugPrint('WebView log: ${jsonEncode(data)}');
          break;
        default:
          debugPrint('Unhandled WebView bridge message: $type');
          break;
      }
    }

    useEffect(() {
      final requestUri = initialUri;
      if (requestUri == null || !requestUri.hasScheme) {
        debugPrint('Invalid WebView url: $uri');
        return null;
      }

      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (value) {
              if (context.mounted) {
                progress.value = value;
              }
            },
            onPageFinished: (_) async {
              if (!context.mounted || pageTitle.value.isNotEmpty) return;
              final nextTitle = await controller.getTitle();
              if (nextTitle != null && nextTitle.isNotEmpty) {
                pageTitle.value = nextTitle;
              }
            },
            onWebResourceError: (error) {
              debugPrint(
                'WebView resource error: '
                '${error.errorCode} ${error.description}',
              );
            },
            onNavigationRequest: (request) {
              final nextUri = Uri.tryParse(request.url);
              final scheme = nextUri?.scheme;
              if (scheme == 'http' || scheme == 'https') {
                return NavigationDecision.navigate;
              }
              if (request.url == 'about:blank') {
                return NavigationDecision.navigate;
              }
              debugPrint(
                'Prevented non-http WebView navigation: ${request.url}',
              );
              return NavigationDecision.prevent;
            },
          ),
        )
        ..addJavaScriptChannel(
          'nadyBridge',
          onMessageReceived: handleBridgeMessage,
        )
        ..loadRequest(requestUri);

      return () {
        unawaited(controller.removeJavaScriptChannel('nadyBridge'));
      };
    }, [controller, uri]);

    final webViewBody = Stack(
      children: [
        WebViewWidget(controller: controller),
        if (progress.value > 0 && progress.value < 100)
          const LinearProgressIndicator(),
      ],
    );

    if (hideAppBar.value) {
      return Scaffold(
        backgroundColor: AppColors.cardBackground,
        body: webViewBody,
      );
    }

    return CustomScaffold(
      title: pageTitle.value,
      useGradientBackground: false,
      body: webViewBody,
    );
  }
}

Map<String, dynamic>? _decodeMap(String raw) {
  try {
    return _asMap(jsonDecode(raw));
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
