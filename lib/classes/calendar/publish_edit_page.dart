
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../configs/consts.dart';

class PublishEditPage extends HookConsumerWidget {
  final int? moodIndex;
  const PublishEditPage({super.key,  this.moodIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImages = useState<List<XFile>>([]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 标题
          const Text(
            'Input Mood',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 16),
          // 2. 输入框
          TextField(
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'What Happened Today...',
              hintStyle: const TextStyle(
                color: Color(0xFFB2B2B2),
                fontSize: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFF9E707),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          // 3. 图片选择按钮
          GestureDetector(
            onTap: () {
              // 检查是否已达到最大数量
              if (selectedImages.value.length >= 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('最多只能选择4张图片')),
                );
                return;
              }

              showAvatarOptions(
                context,
                onAlbumSelected: () async {
                  final ImagePicker picker = ImagePicker();
                  // 从相册选择多张图片
                  final List<XFile> images = await picker.pickMultiImage();
                  if (images.isNotEmpty) {
                    // 计算还可以选择的数量
                    final remainingSlots = 4 - selectedImages.value.length;
                    final imagesToAdd = images.take(remainingSlots).toList();
                    selectedImages.value = [...selectedImages.value, ...imagesToAdd];

                    // 如果用户选择的图片超过剩余数量，提示用户
                    if (images.length > remainingSlots) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('最多只能选择4张图片，已添加${imagesToAdd.length}张')),
                      );
                    }
                  }
                },
                onCameraSelected: () async {
                  final ImagePicker picker = ImagePicker();
                  // 使用相机拍照
                  final XFile? photo =
                      await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    selectedImages.value = [...selectedImages.value, photo];
                  }
                },
              );
            },
            child: Image.asset(
              'assets/calendar/select_image_button.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          // 4. 显示已选择的图片
          if (selectedImages.value.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedImages.value.map((image) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // 删除按钮
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          selectedImages.value = selectedImages.value
                              .where((img) => img.path != image.path)
                              .toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}