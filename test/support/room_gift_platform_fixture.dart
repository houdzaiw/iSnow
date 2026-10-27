import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests exercise the native-unavailable fallback, not GPU rendering.
class RoomGiftPlatformFixture {
  static const _pag = MethodChannel('flutter_pag_plugin');
  static const _paths = MethodChannel('plugins.flutter.io/path_provider');
  final calls = <MethodCall>[];
  final unexpected = <MethodCall>[];

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_pag, (call) async {
      calls.add(call);
      if (call.method == 'initPag') {
        return {'textureId': -1, 'width': 0, 'height': 0};
      }
      unexpected.add(call);
      throw StateError('Unexpected PAG operation: ${call.method}');
    });
    messenger.setMockMethodCallHandler(_paths, (call) async {
      unexpected.add(call);
      throw StateError(
        'Widget tests must not open a real cache: ${call.method}',
      );
    });
  }

  void uninstall() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_pag, null);
    messenger.setMockMethodCallHandler(_paths, null);
  }
}
