import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/room_system_volume_manager.dart';
import 'package:volume_controller/volume_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'one native observer serves multiple listeners and releases on last cancel',
    () async {
      var starts = 0;
      var cancels = 0;
      final native = StreamController<double>.broadcast(
        onListen: () => starts++,
        onCancel: () => cancels++,
      );
      final manager = RoomSystemVolumeManager(
        read: () async => .6,
        write: (_) async {},
        observe: () => native.stream,
      );
      final first = <double>[];
      final second = <double>[];
      final a = manager.changes.listen(first.add);
      final b = manager.changes.listen(second.add);
      await _flush();
      expect(starts, 1);
      expect(first, [.6]);
      expect(second, [.6]);
      native.add(.9);
      await _flush();
      expect(first.last, .9);
      expect(second.last, .9);
      await a.cancel();
      expect(cancels, 0);
      await b.cancel();
      await _flush();
      expect(cancels, 1);
      await manager.dispose();
      await native.close();
    },
  );

  test(
    'coalesces writes but always commits and reads back the final hardware step',
    () async {
      final gate = Completer<void>();
      var value = .5;
      final writes = <double>[];
      final native = StreamController<double>.broadcast();
      final manager = RoomSystemVolumeManager(
        read: () async => value,
        observe: () => native.stream,
        write: (next) async {
          writes.add(next);
          if (writes.length == 1) await gate.future;
          value = (next * 10).round() / 10;
        },
      );
      final observed = <double>[];
      final subscription = manager.changes.listen(observed.add);
      await _flush();
      final first = manager.setVolume(.1);
      await _flush();
      final middle = manager.setVolume(.4);
      final last = manager.setVolume(.87);
      gate.complete();
      await first;
      await middle;
      await last;
      await _flush();
      expect(writes, [.1, .87]);
      expect(observed.last, .9);
      await subscription.cancel();
      await manager.dispose();
      await native.close();
    },
  );

  test(
    'hardware events win over stale initial read and cancelled reads stay silent',
    () async {
      final initial = Completer<double>();
      final native = StreamController<double>.broadcast();
      final manager = RoomSystemVolumeManager(
        read: () => initial.future,
        observe: () => native.stream,
        write: (_) async {},
      );
      final values = <double>[];
      final subscription = manager.changes.listen(values.add);
      await _flush();
      native.add(.8);
      await _flush();
      initial.complete(.1);
      await _flush();
      expect(values, [.8]);
      await subscription.cancel();
      native.add(.3);
      await _flush();
      expect(values, [.8]);
      await manager.dispose();
      await native.close();
    },
  );

  test(
    'read and write failures propagate without inventing a system volume',
    () async {
      final native = StreamController<double>.broadcast();
      final manager = RoomSystemVolumeManager(
        read: () async => throw StateError('read'),
        observe: () => native.stream,
        write: (_) async => throw StateError('write'),
      );
      final errors = <Object>[];
      final values = <double>[];
      final subscription = manager.changes.listen(
        values.add,
        onError: errors.add,
      );
      await _flush();
      expect(values, isEmpty);
      expect(errors.single, isA<StateError>());
      await expectLater(manager.setVolume(.5), throwsStateError);
      await subscription.cancel();
      await manager.dispose();
      await native.close();
    },
  );

  test(
    'pending initial read cannot retain the native observer after disposal',
    () async {
      final initial = Completer<double>();
      final native = StreamController<double>.broadcast();
      final manager = RoomSystemVolumeManager(
        read: () => initial.future,
        write: (_) async {},
        observe: () => native.stream,
      );
      final values = <double>[];
      final subscription = manager.changes.listen(values.add);
      await _flush();
      await subscription.cancel();
      await manager.dispose();
      expect(native.hasListener, isFalse);
      initial.complete(.8);
      await _flush();
      expect(values, isEmpty);
      await native.close();
    },
  );

  test(
    'local plugin awaits platform result and propagates write errors',
    () async {
      const channel = MethodChannel('com.kurenai7968.volume_controller.method');
      final gate = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            await gate.future;
            throw PlatformException(code: 'volume_unavailable');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      var completed = false;
      final write = VolumeController.instance.setVolume(.7);
      final failure = expectLater(
        write.whenComplete(() => completed = true),
        throwsA(isA<PlatformException>()),
      );
      await _flush();
      expect(completed, isFalse);
      gate.complete();
      await failure;
      expect(completed, isTrue);
    },
  );

  test(
    'observer failure is not hidden by a late successful initial read',
    () async {
      final initial = Completer<double>();
      final native = StreamController<double>.broadcast();
      final manager = RoomSystemVolumeManager(
        read: () => initial.future,
        write: (_) async {},
        observe: () => native.stream,
      );
      final values = <double>[];
      final errors = <Object>[];
      final subscription = manager.changes.listen(
        values.add,
        onError: errors.add,
      );
      await _flush();
      native.addError(StateError('observer unavailable'));
      await _flush();
      initial.complete(.7);
      await _flush();
      expect(values, isEmpty);
      expect(errors, hasLength(1));
      await subscription.cancel();
      await manager.dispose();
      await native.close();
    },
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
