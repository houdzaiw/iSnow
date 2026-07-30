import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VoiceBubble extends StatelessWidget {
  final String text;
  final double width;
  final double height;

  const VoiceBubble({
    super.key,
    required this.text,
    this.width = 179,
    this.height = 41,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + 9,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(14, 14),
              painter: _VoiceBubbleTailPainter(),
            ),
          ),
          Positioned(
            left: 9,
            top: 0,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                gradient: AppGradients.voiceBubble,
                borderRadius: AppRadius.pillBorder,
                border: Border.all(color: AppColors.neutralLight, width: 0.4),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Image.asset(
                    AppAssets.calendarSpeakIcon,
                    width: 10,
                    height: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    text,
                    style: AppTextStyles.bodyStrongSmall.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.voiceBubbleStart
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
