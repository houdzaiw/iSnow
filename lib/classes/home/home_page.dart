// dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../../configs/consts.dart';

import 'capture_finished_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // moodImages is defined in lib/consts.dart

  final Random _random = Random();
  late List<MoodImageData> _randomMoodImages;
  late List<MoodImageData> _targetMoodImages;
  late AnimationController _animationController;
  late Animation<double> _animation;
  OverlayEntry? _overlayEntry;
  // Flag to prevent repeated triggering while animation/dialog is pending
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _generateRandomMoodImages();
    _targetMoodImages = List.from(_randomMoodImages);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut, // 弹跳效果
    );

    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _hideDialog();
    _animationController.dispose();
    super.dispose();
  }

  void _hideDialog() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _generateRandomMoodImages() {
    _randomMoodImages = moodImages.map((imagePath) {
      // 70-90%的图片显示在下方，10-30%显示在上方
      final isInBottomArea = _random.nextDouble() < 0.8; // 80%概率在下方
      final top = isInBottomArea
          ? 0.4 + _random.nextDouble() * 0.4  // 下方区域: 40%-80%
          : _random.nextDouble() * 0.4;        // 上方区域: 0%-40%

      return MoodImageData(
        imagePath: imagePath,
        left: _random.nextDouble() * 0.7, // 0-70% of screen width
        top: top,
        rotation: _random.nextDouble() * 2 * pi, // 0-360 degrees in radians
      );
    }).toList();
  }

  void _animateMoodImages() {
    // Prevent re-entry while an animation/dialog is pending
    if (_isAnimating || _overlayEntry != null) return;
    _isAnimating = true;

    // 随机选择30-50%的图片进行动画
    final animateCount = (moodImages.length * (0.3 + _random.nextDouble() * 0.2)).round();
    final animateIndices = <int>{};

    // 随机选择要动画的图片索引
    while (animateIndices.length < animateCount) {
      animateIndices.add(_random.nextInt(moodImages.length));
      animateIndices.add(_random.nextInt(moodImages.length));
    }

    // 生成新的目标位置（只为选中的图片生成新位置）
    _targetMoodImages = List.generate(moodImages.length, (index) {
      if (animateIndices.contains(index)) {
        // 这个图片会动画到新位置
        // 70-90%的图片显示在下方，10-30%显示在上方
        final isInBottomArea = _random.nextDouble() < 0.8; // 80%概率在下方
        final top = isInBottomArea
            ? 0.4 + _random.nextDouble() * 0.4  // 下方区域: 40%-80%
            : _random.nextDouble() * 0.4;        // 上方区域: 0%-40%

        return MoodImageData(
          imagePath: moodImages[index],
          left: _random.nextDouble() * 0.7,
          top: top,
          rotation: _random.nextDouble() * 2 * pi,
        );
      } else {
        // 这个图片保持原位置
        return _randomMoodImages[index];
      }
    });

    // 重置并开始动画
    _animationController.reset();
    _animationController.forward().then((_) async {
      // 动画完成后，更新起始位置为目标位置
      setState(() {
        _randomMoodImages = List.from(_targetMoodImages);
      });
      // 显示全屏弹框并等待弹框插入完成的下一帧
      await _showDialogAsync();
      // allow further animations/clicks after dialog has been shown
      _isAnimating = false;
    });
  }

  /// Inserts the overlay and completes after the next frame so callers can
  /// be sure the dialog has been presented.
  Future<void> _showDialogAsync() {
    if (_overlayEntry != null) return Future.value();

    _overlayEntry = OverlayEntry(
        builder: (context) => Positioned.fill(
          child: DialogOverlay(
            onClose: _hideDialog,
          ),
        )
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);

    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }

  List<MoodImageData> _getInterpolatedMoodImages() {
    if (!_animationController.isAnimating) {
      return _randomMoodImages;
    }

    return List.generate(_randomMoodImages.length, (index) {
      final start = _randomMoodImages[index];
      final end = _targetMoodImages[index];
      final t = _animation.value;

      return MoodImageData(
        imagePath: start.imagePath,
        left: start.left + (end.left - start.left) * t,
        top: start.top + (end.top - start.top) * t,
        rotation: start.rotation + (end.rotation - start.rotation) * t,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9E707),
      body: Container(
        margin: EdgeInsets.only(
          left: 22,
          right: 22,
          top: MediaQuery.of(context).padding.top + 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(
            color: const Color(0xFFFFB400),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(42),
          child: Stack(
            children: [
              // 随机展示mood图片
              ..._getInterpolatedMoodImages().map((moodData) {
                return Positioned(
                  left: moodData.left * MediaQuery.of(context).size.width,
                  top: moodData.top * MediaQuery.of(context).size.height,
                  child: Transform.rotate(
                    angle: moodData.rotation,
                    child: Image.asset(
                      moodData.imagePath,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }).toList(),

              // 底部背景图片
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/home/bottom_cover_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              // 右下角拍摄按钮
              Positioned(
                right: 8,
                bottom: 8,
                child: GestureDetector(
                  onTap: () {
                    // ignore taps while animating or when overlay is already shown
                    if (_isAnimating || _overlayEntry != null) return;
                    _animateMoodImages();
                  },
                  child: Image.asset(
                    'assets/home/capture_button.png',
                    width: 97,
                    height: 97,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class MoodImageData {
  final String imagePath;
  final double left;
  final double top;
  final double rotation;

  MoodImageData({
    required this.imagePath,
    required this.left,
    required this.top,
    required this.rotation,
  });
}
