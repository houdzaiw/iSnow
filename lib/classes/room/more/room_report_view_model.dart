import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../manager/api_error_message.dart';
import '../../../manager/http_api.dart';
import '../room_repository.dart';
import 'room_tools_models.dart';
import 'room_tools_repository.dart';

final roomReportRepositoryProvider = Provider(
  (ref) => RoomReportRepository(ref.watch(roomToolsRepositoryProvider)),
);

class RoomReportRepository {
  RoomReportRepository(this.api, {ImagePicker? picker})
    : picker = picker ?? ImagePicker();
  final RoomToolsRepository api;
  final ImagePicker picker;
  Future<List<String>> pick(int remaining) async =>
      (await picker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 85,
      )).take(remaining).map((file) => file.path).toList();
  Future<List<ToolJson>> uploadParams(int count) async =>
      toolList(await api.get(HttpApi.reportUploadParams, {'num': count}));
  Future<String> upload(String filePath, ToolJson param) async {
    const requiredKeys = [
      'path',
      'endpoint',
      'bucket',
      'securityToken',
      'accessKeySecret',
      'accessKeyId',
    ];
    if (requiredKeys.any(
      (key) => param[key] is! String || (param[key] as String).trim().isEmpty,
    )) {
      throw StateError('Invalid upload credentials');
    }
    final extension = filePath.split('.').last.toLowerCase();
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final key = '${param['path']}.${extension == 'png' ? 'png' : 'jpg'}';
    final endpoint = '${param['endpoint']}';
    final host = Uri.parse(
      endpoint.contains('://') ? endpoint : 'https://$endpoint',
    );
    final bucket = '${param['bucket']}';
    if (host.scheme != 'https' ||
        host.host.isEmpty ||
        bucket.isEmpty ||
        '${param['path']}'.isEmpty) {
      throw StateError('Invalid upload credentials');
    }
    final uri = host.replace(
      host: '$bucket.${host.host}',
      path: '/$key',
      query: null,
    );
    final date = HttpDate.format(DateTime.now().toUtc());
    final token = '${param['securityToken']}';
    final sign =
        'PUT\n\n$contentType\n$date\nx-oss-security-token:$token\n/$bucket/$key';
    final signature = base64Encode(
      crypto.Hmac(
        crypto.sha1,
        utf8.encode('${param['accessKeySecret']}'),
      ).convert(utf8.encode(sign)).bytes,
    );
    final bytes = await File(filePath).readAsBytes();
    await api.http.putSignedObject(uri.toString(), bytes, {
      'Date': date,
      'Content-Type': contentType,
      'Content-Length': bytes.length,
      'x-oss-security-token': token,
      'Authorization': 'OSS ${param['accessKeyId']}:$signature',
    });
    return key;
  }

  Future<void> submit(ToolJson body) async {
    await api.post(HttpApi.reportSubmit, body);
  }
}

class RoomReportState {
  const RoomReportState({
    this.reason,
    this.description = '',
    this.photos = const [],
    this.busy = false,
    this.error,
  });
  final int? reason;
  final String description;
  final List<String> photos;
  final bool busy;
  final String? error;
}

final roomReportViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomReportViewModel, RoomReportState, String>(
      (ref, roomId) => RoomReportViewModel(
        roomId,
        ref.watch(roomReportRepositoryProvider),
        ref.watch(roomRepositoryProvider),
      ),
    );

class RoomReportViewModel extends StateNotifier<RoomReportState> {
  RoomReportViewModel(this.roomId, this.repository, this.room)
    : super(const RoomReportState());
  final String roomId;
  final RoomReportRepository repository;
  final RoomRepository room;
  final _uploaded = <String, String>{};
  void _update({
    int? reason,
    bool clearReason = false,
    String? description,
    List<String>? photos,
    bool? busy,
    String? error,
  }) {
    if (mounted) {
      state = RoomReportState(
        reason: clearReason ? null : reason ?? state.reason,
        description: description ?? state.description,
        photos: photos ?? state.photos,
        busy: busy ?? state.busy,
        error: error,
      );
    }
  }

  void selectReason(int value) {
    if (!state.busy) _update(reason: value, clearReason: state.reason == value);
  }

  void describe(String value) {
    if (!state.busy) _update(description: value);
  }

  void removePhoto(String path) {
    if (!state.busy) {
      _update(photos: state.photos.where((photo) => photo != path).toList());
    }
  }

  Future<void> pickPhotos() async {
    if (state.busy || state.photos.length >= 4) return;
    _update(busy: true);
    try {
      final paths = await repository.pick(4 - state.photos.length);
      if (mounted) {
        _update(
          photos: [...state.photos, ...paths].take(4).toList(),
          busy: false,
        );
      }
    } catch (error) {
      _update(busy: false, error: userFacingErrorMessage(error));
    }
  }

  Future<bool> submit() async {
    if (state.busy) return false;
    final numericRoomId = int.tryParse(roomId);
    if (state.reason == null ||
        ![1, 2, 3, 4, 5].contains(state.reason) ||
        state.description.length > 200 ||
        numericRoomId == null) {
      _update(error: 'Select a report reason and check the form');
      return false;
    }
    final generation = room.roomGeneration;
    _update(busy: true);
    try {
      final missing = state.photos
          .where((path) => !_uploaded.containsKey(path))
          .toList();
      final params = missing.isEmpty
          ? const <ToolJson>[]
          : await repository.uploadParams(missing.length);
      if (params.length != missing.length) {
        throw StateError('Missing upload credentials');
      }
      for (var index = 0; index < missing.length; index++) {
        if (!mounted || generation != room.roomGeneration) return false;
        _uploaded[missing[index]] = await repository.upload(
          missing[index],
          params[index],
        );
      }
      if (!mounted || generation != room.roomGeneration) return false;
      await repository.submit({
        'reportType': 1,
        'reportId': numericRoomId,
        'categoriesList': [state.reason!],
        'description': state.description.trim(),
        'photosList': state.photos.map((path) => _uploaded[path]!).toList(),
      });
      return mounted && generation == room.roomGeneration;
    } catch (error) {
      _update(error: userFacingErrorMessage(error));
      return false;
    } finally {
      if (mounted) _update(busy: false, error: state.error);
    }
  }
}
