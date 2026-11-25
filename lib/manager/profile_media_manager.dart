import 'dart:io';

import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final profileMediaManagerProvider = Provider((ref) => ProfileMediaManager());

class ProfileMediaManager {
  ProfileMediaManager({
    Future<File> Function(String)? download,
    Future<void> Function(String)? saveFile,
  }) : _download =
           download ??
           CachedNetworkImageProvider.defaultCacheManager.getSingleFile,
       _saveFile = saveFile ?? FlutterImageGallerySaver.saveFile;
  final Future<File> Function(String) _download;
  final Future<void> Function(String) _saveFile;
  Future<String?> pick({required bool camera}) async =>
      (await ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
      ))?.path;
  Future<void> save(String url, {required bool Function() isCurrent}) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty) {
      throw ArgumentError('Invalid image URL');
    }
    if (!isCurrent()) return;
    final file = await _download(url);
    if (!isCurrent()) return;
    await _saveFile(file.path);
  }
}
