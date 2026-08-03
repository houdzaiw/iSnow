// Common constants used across the app

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';

enum UserActionOption {
  delete('app.delete'),
  report('app.report'),
  block('app.block'),
  cancel('app.cancel');

  final String labelKey;
  const UserActionOption(this.labelKey);
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
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutralLight,
                borderRadius: AppRadius.pillBorder,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryPink,
              ),
              title: Text(
                context.l10n.t('picker.album'),
                style: AppTextStyles.bodyStrong,
              ),
              onTap: () {
                Navigator.pop(context);
                if (onAlbumSelected != null) {
                  onAlbumSelected();
                } else {
                  // 默认提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('picker.albumSelected')),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryPink,
              ),
              title: Text(
                context.l10n.t('picker.camera'),
                style: AppTextStyles.bodyStrong,
              ),
              onTap: () {
                Navigator.pop(context);
                if (onCameraSelected != null) {
                  onCameraSelected();
                } else {
                  // 默认提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.t('picker.cameraSelected')),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.t('app.cancel'),
                style: AppTextStyles.hint,
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
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutralLight,
                borderRadius: AppRadius.pillBorder,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...options.map((option) {
              final isCancel = option == UserActionOption.cancel;
              final isDelete = option == UserActionOption.delete;
              return Padding(
                padding: EdgeInsets.only(
                  top: isCancel && options.length > 1 ? AppSpacing.sm : 0,
                  bottom: AppSpacing.sm,
                ),
                child: GestureDetector(
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
                        break;
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCancel
                          ? AppColors.neutralLight
                          : AppColors.cardBackground,
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(
                        color: isDelete
                            ? AppColors.primaryPink
                            : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.l10n.t(option.labelKey),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: isDelete
                            ? AppColors.primaryPink
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
