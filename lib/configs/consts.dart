// Common constants used across the app

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

enum UserActionOption {
  delete('删除'),
  report('举报'),
  block('拉黑'),
  cancel('取消');

  final String label;
  const UserActionOption(this.label);
}

const List<String> moodImages = AppAssets.moodImages;

String setDateFormatter(DateTime date) {
  final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  final formattedDate = dateFormatter.format(date);
  return formattedDate;
}

/// 显示选择头像的底部弹框（相册或相机）
void showAvatarOptions(
  BuildContext context, {
  VoidCallback? onAlbumSelected,
  VoidCallback? onCameraSelected,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryPink,
              ),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                if (onAlbumSelected != null) {
                  onAlbumSelected();
                } else {
                  // 默认提示
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已选择相册')));
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryPink,
              ),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                if (onCameraSelected != null) {
                  onCameraSelected();
                } else {
                  // 默认提示
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已选择拍照')));
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '取消',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 显示用户操作的底部弹框（举报、屏蔽、取消，可选删除）
void showUserActionOptions(
  BuildContext context, {
  bool includeDelete = false,
  VoidCallback? onDeleteSelected,
  VoidCallback? onReportSelected,
  VoidCallback? onBlockSelected,
}) {
  // 根据 includeDelete 参数过滤选项
  final options = UserActionOption.values.where((option) {
    if (!includeDelete && option == UserActionOption.delete) {
      return false;
    }
    return true;
  }).toList();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
    backgroundColor: AppColors.cardBackground,
    builder: (context) {
      return Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isCancel = option == UserActionOption.cancel;
            return Column(
              children: [
                if (isCancel && options.length > 1)
                  const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    switch (option) {
                      case UserActionOption.delete:
                        if (onDeleteSelected != null) {
                          onDeleteSelected();
                        }
                        break;
                      case UserActionOption.report:
                        if (onReportSelected != null) {
                          onReportSelected();
                        }
                        break;
                      case UserActionOption.block:
                        if (onBlockSelected != null) {
                          onBlockSelected();
                        }
                        break;
                      case UserActionOption.cancel:
                        // Just close the modal
                        break;
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width - 48,
                    height: 55,
                    decoration: BoxDecoration(
                      color: isCancel
                          ? AppColors.neutralLight
                          : Colors.transparent,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    },
  );
}
