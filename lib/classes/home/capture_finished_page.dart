import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';

// 弹框图层类
class DialogOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const DialogOverlay({super.key, required this.onClose, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.overlay,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 使用Stack来叠加头像和关闭按钮在图片上
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  AppAssets.lanhuCaptureResultCard,
                  width: 274,
                  height: 274,
                ),
                Positioned(
                  left: 77,
                  top: 71,
                  child: Image.asset(
                    AppAssets.lanhuProudMood,
                    width: 120,
                    height: 120,
                  ),
                ),
                Positioned(
                  left: 46,
                  right: 46,
                  bottom: 48,
                  child: Text(
                    context.l10n.t('home.captureTitle'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                // 左边头像
                Positioned(
                  left: 23,
                  top: 23,
                  child: GestureDetector(
                    onTap: () {}, // 防止点击头像时关闭弹框
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.avatarPlaceholder,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardBackground,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.textInverse,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                // 右边关闭按钮
                Positioned(
                  right: 20,
                  top: 20,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Image.asset(
                      AppAssets.lanhuCloseCircle,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {
                onOpen();
              },
              child: Container(
                width: 153,
                height: 53,
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: AppRadius.pillBorder,
                ),
                alignment: Alignment.center,
                child: Text(
                  context.l10n.t('home.open'),
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.textInverse,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
