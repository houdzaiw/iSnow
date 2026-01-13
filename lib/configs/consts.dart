// Common constants used across the app

import 'package:flutter/material.dart';

const List<String> moodImages = [
  'assets/mood/model_01.png',
  'assets/mood/model_02.png',
  'assets/mood/model_03.png',
  'assets/mood/model_04.png',
  'assets/mood/model_05.png',
  'assets/mood/model_06.png',
  'assets/mood/model_07.png',
  'assets/mood/model_08.png',
  'assets/mood/model_09.png',
  'assets/mood/model_010.png',
  'assets/mood/model_011.png',
  'assets/mood/model_012.png',
  'assets/mood/model_013.png',
  'assets/mood/model_014.png',
  'assets/mood/model_015.png',
  'assets/mood/model_016.png',
  'assets/mood/model_017.png',
  'assets/mood/model_018.png',
  'assets/mood/model_019.png',
  'assets/mood/model_020.png',
];

/// 显示选择头像的底部弹框（相册或相机）
void showAvatarOptions(BuildContext context, {
  VoidCallback? onAlbumSelected,
  VoidCallback? onCameraSelected,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Album'),
              onTap: () {
                Navigator.pop(context);
                if (onAlbumSelected != null) {
                  onAlbumSelected();
                } else {
                  // 默认提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Album selected')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                if (onCameraSelected != null) {
                  onCameraSelected();
                } else {
                  // 默认提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera selected')),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
