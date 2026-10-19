import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class RoomMicWave extends StatefulWidget {
  const RoomMicWave({super.key});
  @override
  State<RoomMicWave> createState() => _RoomMicWaveState();
}

class _RoomMicWaveState extends State<RoomMicWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: AppMotion.roomMiniWave,
  )..repeat();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: animation,
      builder: (_, _) => CustomPaint(painter: _WavePainter(animation.value)),
    ),
  );
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    for (final phase in [progress, (progress + 0.5) % 1]) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSpacing.roomMiniWaveStroke
        ..color = AppColors.roomMiniWave.withValues(
          alpha: (1 - phase) * AppSpacing.roomMiniWaveMaxOpacity,
        );
      canvas.drawCircle(
        size.center(Offset.zero),
        radius * (0.7 + phase * 0.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
