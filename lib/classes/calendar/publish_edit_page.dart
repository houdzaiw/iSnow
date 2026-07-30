import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../configs/consts.dart';
import '../../theme/app_theme.dart';

class PublishEditPage extends HookConsumerWidget {
  final int? moodIndex;
  final Function(String description, List<String> imagePaths)? onSave;

  const PublishEditPage({super.key, this.moodIndex, this.onSave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImages = useState<List<XFile>>([]);
    final textController = useTextEditingController();

    // 监听数据变化，自动调用 onSave 回调
    useEffect(() {
      void listener() {
        if (onSave != null) {
          final description = textController.text;
          final imagePaths = selectedImages.value.map((e) => e.path).toList();
          onSave!(description, imagePaths);
        }
      }

      textController.addListener(listener);

      return () {
        textController.removeListener(listener);
      };
    }, [textController]);

    // 监听图片变化
    useEffect(() {
      if (onSave != null) {
        final description = textController.text;
        final imagePaths = selectedImages.value.map((e) => e.path).toList();
        onSave!(description, imagePaths);
      }
      return null;
    }, [selectedImages.value]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('填写心情', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: textController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '今天发生了什么...',
              hintStyle: AppTextStyles.hint.copyWith(fontSize: 18),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: AppRadius.cardBorder,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardBorder,
                borderSide: const BorderSide(color: AppColors.calendarBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardBorder,
                borderSide: const BorderSide(
                  color: AppColors.primaryPink,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.xl),
            ),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: () {
              // 检查是否已达到最大数量
              if (selectedImages.value.length >= 4) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('最多只能选择4张图片')));
                return;
              }

              showAvatarOptions(
                context,
                onAlbumSelected: () async {
                  final ImagePicker picker = ImagePicker();
                  // 从相册选择多张图片
                  final List<XFile> images = await picker.pickMultiImage();
                  if (!context.mounted) return;
                  if (images.isNotEmpty) {
                    // 计算还可以选择的数量
                    final remainingSlots = 4 - selectedImages.value.length;
                    final imagesToAdd = images.take(remainingSlots).toList();
                    selectedImages.value = [
                      ...selectedImages.value,
                      ...imagesToAdd,
                    ];

                    // 如果用户选择的图片超过剩余数量，提示用户
                    if (images.length > remainingSlots) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('最多只能选择4张图片，已添加${imagesToAdd.length}张'),
                        ),
                      );
                    }
                  }
                },
                onCameraSelected: () async {
                  final ImagePicker picker = ImagePicker();
                  // 使用相机拍照
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (!context.mounted) return;
                  if (photo != null) {
                    selectedImages.value = [...selectedImages.value, photo];
                  }
                },
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.calendarBorder),
              ),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Image.asset(
                    AppAssets.calendarSelectImageButton,
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (selectedImages.value.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: selectedImages.value.map((image) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
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
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: const BoxDecoration(
                            color: AppColors.overlay,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textInverse,
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
