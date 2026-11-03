import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';

import 'im_fakes.dart';

V2TimMessage systemNotice(
  String id, {
  Map<String, Object?>? payload,
  Object? timestamp = 1700000000,
  bool stringPayload = false,
  String type = 'SystemComplexIMMsg',
}) => imCustom(
  {
    'type': type,
    'timestamp': timestamp,
    'payload':
        payload ??
        {
          'titleMap': {'en': 'A message for you', 'zh': '给你的一条消息'},
          'textMap': {
            'en': 'First paragraph.\n\nSecond paragraph.',
            'zh': '第一段。\n\n第二段。',
          },
          'picUrl': 'https://images.example.test/$id.png',
          'linkUrl': 'https://example.test/details?notice=$id',
        },
  },
  uid: '10000',
  payloadAsString: stringPayload,
)..msgID = id;

/// In-memory cache files exercise the real image decoder without HTTP,
/// platform channels or an extra test dependency.
class SystemImageCacheFake implements BaseCacheManager {
  late FileInfo image;
  final requests = <String>[];
  final requestHeaders = <Map<String, String>?>[];
  bool fail = false;

  Future<void> prepare() async {
    final file = await MemoryCacheSystem().createFile('notice.png');
    await file.writeAsBytes(
      File('assets/lanhu/room/room_gift_campaign.png').readAsBytesSync(),
    );
    image = FileInfo(file, FileSource.Cache, DateTime(2030), 'fixture');
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    requests.add(url);
    requestHeaders.add(headers);
    if (fail) throw const HttpException('Image unavailable');
    yield image;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
