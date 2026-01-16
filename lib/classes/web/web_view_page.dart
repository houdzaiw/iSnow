
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends HookConsumerWidget {
  final String title;
  final String uri;

  const WebViewPage({
    super.key,
    required this.title,
    required this.uri,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(uri),
      );

    return CustomScaffold(
      title: title,
      body: WebViewWidget(controller: controller),
    );
  }
}