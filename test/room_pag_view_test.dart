import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pag/pag.dart';
import 'package:project/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_pag_plugin');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Widget scene({VoidCallback? onInit}) => MaterialApp(
    home: Scaffold(
      body: PAGView.asset(
        AppAssets.roomGiftComboEffect,
        width: 100,
        height: 100,
        onInit: onInit,
        defaultBuilder: (_) => const Text('fallback'),
      ),
    ),
  );

  for (final response in <Object?>[
    null,
    {'textureId': -1},
    {'textureId': 'invalid'},
    <String, Object>{},
  ]) {
    testWidgets(
      'invalid native response $response keeps fallback and never releases a fake texture',
      (tester) async {
        final calls = <MethodCall>[];
        var initialized = 0;
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initPag') return response;
          throw StateError('Unexpected native call: ${call.method}');
        });
        await tester.pumpWidget(scene(onInit: () => initialized++));
        await tester.pump();
        expect(find.text('fallback'), findsOneWidget);
        expect(find.byType(Texture), findsNothing);
        expect(initialized, 0);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(calls.map((call) => call.method), ['initPag']);
        expect(PAGViewState.frameReadyHandlers, isEmpty);
        expect(PAGViewState.callbackHandlers, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('valid native texture renders and releases exactly once', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    var initialized = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initPag') {
        return {'textureId': 7, 'width': 200, 'height': 200};
      }
      if (call.method == 'release') return null;
      throw StateError('Unexpected native call: ${call.method}');
    });
    await tester.pumpWidget(scene(onInit: () => initialized++));
    await tester.pump();
    expect(tester.widget<Texture>(find.byType(Texture)).textureId, 7);
    expect(initialized, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls.map((call) => call.method), ['initPag', 'release']);
    expect(calls.last.arguments['textureId'], 7);
    expect(PAGViewState.frameReadyHandlers, isEmpty);
    expect(PAGViewState.callbackHandlers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a texture returned after widget disposal is still released', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initPag') return pending.future;
      if (call.method == 'release') return null;
      throw StateError('Unexpected native call: ${call.method}');
    });
    await tester.pumpWidget(scene());
    await tester.pumpWidget(const SizedBox());
    expect(calls.map((call) => call.method), ['initPag']);
    pending.complete({'textureId': 9, 'width': 200, 'height': 200});
    await tester.pump();
    expect(calls.map((call) => call.method), ['initPag', 'release']);
    expect(calls.last.arguments['textureId'], 9);
    expect(PAGViewState.frameReadyHandlers, isEmpty);
    expect(PAGViewState.callbackHandlers, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
