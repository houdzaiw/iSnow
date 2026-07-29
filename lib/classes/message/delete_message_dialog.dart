import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// 弹框图层类
class DeleteMessageDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeleteMessageDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.overlay,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none, // 允许子元素溢出不被裁剪
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 58,
              height: 324,
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.dialogBorder,
              ),
              child: Column(
                //居中
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    "提示",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "删除对话",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Image.asset(
                    AppAssets.messageDeleteIcon,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const SizedBox(width: 17),
                      Expanded(
                        child: GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            height: 53,
                            decoration: const BoxDecoration(
                              color: AppColors.neutralLight,
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: const Center(
                              child: Text(
                                "取消",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 53,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPink,
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: const Center(
                              child: Text(
                                "删除",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: AppColors.textInverse,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 17),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Positioned(
              right: -5,
              top: -5,
              child: GestureDetector(
                onTap: onCancel,
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
      ),
    );
  }
}
