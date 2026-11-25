import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/profile_media_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.knottx.flutter_image_gallery_saver');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test(
    'gallery plugin uses Nady method channel without copying credentials',
    () async {
      final media = ProfileMediaManager(
        download: (_) async => File('/fixture/cache/image'),
      );
      await media.save(
        'https://images.example/test.png',
        isCurrent: () => true,
      );
      expect(calls.single.method, 'save_file');
      expect(calls.single.arguments, {'file_path': '/fixture/cache/image'});
    },
  );
  test(
    'close during download never saves image and invalid URLs are rejected',
    () async {
      final gate = Completer<File>();
      var active = true;
      final media = ProfileMediaManager(download: (_) => gate.future);
      final task = media.save(
        'https://images.example/test.png',
        isCurrent: () => active,
      );
      active = false;
      gate.complete(File('/fixture/image'));
      await task;
      expect(calls, isEmpty);
      for (final url in [
        'file:///secret',
        'javascript:alert(1)',
        'https://user:password@example.test/image',
      ]) {
        await expectLater(
          media.save(url, isCurrent: () => true),
          throwsArgumentError,
        );
      }
    },
  );
}
