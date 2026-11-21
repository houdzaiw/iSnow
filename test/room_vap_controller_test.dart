import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vap_plus/flutter_vap_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_vap_controller_901');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late VapController controller;
  late List<String> calls;
  Completer<void>? configureGate;
  Completer<void>? stopGate;
  PlatformException? stopError;

  Future<void> event(String method) => messenger.handlePlatformMessage(
    channel.name,
    codec.encodeMethodCall(MethodCall(method)),
    (_) {},
  );

  setUp(() {
    calls = [];
    configureGate = stopGate = null;
    stopError = null;
    controller = VapController(viewId: 901);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'setFetchResource') await configureGate?.future;
      if (call.method == 'stop') {
        await stopGate?.future;
        if (stopError != null) throw stopError!;
      }
      return null;
    });
  });
  tearDown(() {
    if (configureGate?.isCompleted == false) configureGate!.complete();
    if (stopGate?.isCompleted == false) stopGate!.complete();
    controller.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('a started loop is not cut off by the completion timeout', (
    tester,
  ) async {
    Object? failure;
    var finished = false;
    unawaited(
      controller
          .playPath('/fixture.mp4', loop: true)
          .then((_) {
            finished = true;
          })
          .catchError((Object error) {
            failure = error;
          }),
    );
    await tester.pump();
    expect(calls, contains('playPath'));
    await event('onStart');
    await tester.pump(const Duration(seconds: 21));
    expect(failure, isNull);
    expect(finished, isFalse);
    await controller.stop();
    await tester.pump();
    expect(finished, isTrue);
  });

  testWidgets('stop settles playback only after the native stop reply', (
    tester,
  ) async {
    var finished = false;
    unawaited(
      controller
          .playPath('/fixture.mp4', loop: true)
          .then((_) => finished = true),
    );
    await tester.pump();
    await event('onStart');
    stopGate = Completer<void>();
    final stopped = controller.stop();
    await tester.pump();
    expect(finished, isFalse);
    stopGate!.complete();
    await stopped;
    await tester.pump();
    expect(finished, isTrue);
  });

  testWidgets('stop during configuration cannot start a late native play', (
    tester,
  ) async {
    configureGate = Completer<void>();
    var finished = false;
    unawaited(controller.playPath('/fixture.mp4').then((_) => finished = true));
    await tester.pump();
    expect(calls, ['setFetchResource']);
    await controller.stop();
    configureGate!.complete();
    await tester.pump();
    expect(calls, isNot(contains('playPath')));
    expect(finished, isTrue);
  });

  testWidgets('concurrent stop calls share one native release', (tester) async {
    stopGate = Completer<void>();
    final first = controller.stop();
    final second = controller.stop();
    await tester.pump();
    expect(calls.where((call) => call == 'stop'), hasLength(1));
    stopGate!.complete();
    await Future.wait([first, second]);
  });

  testWidgets('an unstarted loop still has a bounded startup deadline', (
    tester,
  ) async {
    Object? failure;
    unawaited(
      controller.playPath('/fixture.mp4', loop: true).catchError((
        Object error,
      ) {
        failure = error;
      }),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    expect(failure, isA<TimeoutException>());
  });

  testWidgets('finite completion settles once and cancels its watchdog', (
    tester,
  ) async {
    var completed = 0;
    unawaited(controller.playPath('/fixture.mp4').then((_) => completed++));
    await tester.pump();
    await event('onStart');
    await event('onComplete');
    await event('onComplete');
    await tester.pump(const Duration(seconds: 25));
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a finite playback timeout is reported as failure, not success', (
    tester,
  ) async {
    Object? failure;
    var completed = false;
    unawaited(
      controller
          .playPath('/fixture.mp4')
          .then((_) {
            completed = true;
          })
          .catchError((Object error) {
            failure = error;
          }),
    );
    await tester.pump();
    await event('onStart');
    await tester.pump(const Duration(seconds: 21));
    expect(failure, isA<TimeoutException>());
    expect(completed, isFalse);
  });

  testWidgets('a failed native stop reaches both callers without restarting', (
    tester,
  ) async {
    Object? playFailure;
    unawaited(
      controller.playPath('/fixture.mp4').catchError((Object error) {
        playFailure = error;
      }),
    );
    await tester.pump();
    stopError = PlatformException(code: 'release_failed');
    await expectLater(controller.stop(), throwsA(isA<PlatformException>()));
    await tester.pump();
    expect(playFailure, isA<PlatformException>());
    expect(calls.where((call) => call == 'playPath'), hasLength(1));
  });

  testWidgets('disposing during setup prevents a late native start', (
    tester,
  ) async {
    configureGate = Completer<void>();
    var finished = false;
    unawaited(controller.playPath('/fixture.mp4').then((_) => finished = true));
    await tester.pump();
    controller.dispose();
    configureGate!.complete();
    await tester.pump();
    expect(finished, isTrue);
    expect(calls, isNot(contains('playPath')));
  });
}
