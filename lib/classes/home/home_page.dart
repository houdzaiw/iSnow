// dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:project/model/diary_entry.dart';
import 'dart:math';
import 'dart:async';
import '../../configs/consts.dart';
import '../../theme/app_theme.dart';

import 'capture_finished_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // moodImages is defined in lib/consts.dart

  final Random _random = Random();
  late List<MoodImageData> _randomMoodImages;
  late List<List<MoodImageData>> _waypointsList; // 存储多个路径点
  late AnimationController _animationController;
  late Animation<double> _animation;
  OverlayEntry? _overlayEntry;
  // Flag to prevent repeated triggering while animation/dialog is pending
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _generateRandomMoodImages();
    _waypointsList = [List.from(_randomMoodImages)];

    // 一次性动画，包含多个阶段，从快到慢
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000), // 总时长3秒
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // 从快到慢，开始快结束慢
    );

    _animationController.addListener(() {
      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 动画完成后显示弹框
        _showDialogAsync().then((_) {
          _isAnimating = false;
        });
      }
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

  void _onGoToMessageTap(BuildContext context) {
    _hideDialog();
    final entry = DiaryEntry()
      ..id = 100200
      ..date = DateTime.parse("2024-01-01")
      ..emoji = "😊"
      ..content = "这是今天捕捞到的一条心情。"
      ..description = "这是今天捕捞到的一条心情。"
      ..type = "edit"
      ..moodIndex = 0;
    context.push("/post_detail-view", extra: entry);
  }

  void _generateRandomMoodImages() {
    _randomMoodImages = moodImages.map((imagePath) {
      // 70-90%的图片显示在下方，10-30%显示在上方
      final isInBottomArea = _random.nextDouble() < 0.8; // 80%概率在下方
      final top = isInBottomArea
          ? 0.4 +
                _random.nextDouble() *
                    0.4 // 下方区域: 40%-80%
          : _random.nextDouble() * 0.4; // 上方区域: 0%-40%

      return MoodImageData(
        imagePath: imagePath,
        left: _random.nextDouble() * 0.7, // 0-70% of screen width
        top: top,
        rotation: _random.nextDouble() * 2 * pi, // 0-360 degrees in radians
      );
    }).toList();
  }

  void _generateWaypoints() {
    // 生成3个路径点（包括起点共4个点）
    const int waypointCount = 3;
    _waypointsList = [List.from(_randomMoodImages)]; // 起点

    for (int i = 0; i < waypointCount; i++) {
      // 每次随机选择50-80%的图片进行移动
      final animateCount =
          (moodImages.length * (0.5 + _random.nextDouble() * 0.3)).round();
      final animateIndices = <int>{};

      while (animateIndices.length < animateCount) {
        animateIndices.add(_random.nextInt(moodImages.length));
      }

      // 生成新的路径点
      final previousWaypoint = _waypointsList.last;
      final newWaypoint = List.generate(moodImages.length, (index) {
        if (animateIndices.contains(index)) {
          // 这个图片会移动到新位置
          final isInBottomArea = _random.nextDouble() < 0.8;
          final top = isInBottomArea
              ? 0.4 + _random.nextDouble() * 0.4
              : _random.nextDouble() * 0.4;

          return MoodImageData(
            imagePath: moodImages[index],
            left: _random.nextDouble() * 0.7,
            top: top,
            rotation: _random.nextDouble() * 2 * pi,
          );
        } else {
          // 保持上一个路径点的位置
          return previousWaypoint[index];
        }
      });

      _waypointsList.add(newWaypoint);
    }
  }

  void _animateMoodImages() {
    // Prevent re-entry while an animation/dialog is pending
    if (_isAnimating || _overlayEntry != null) return;
    _isAnimating = true;

    _generateWaypoints();

    // 开始动画
    _animationController.forward(from: 0);
  }

  /// Inserts the overlay and completes after the next frame so callers can
  /// be sure the dialog has been presented.
  Future<void> _showDialogAsync() {
    if (_overlayEntry != null) return Future.value();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: DialogOverlay(
          onClose: _hideDialog,
          onOpen: () => _onGoToMessageTap(context), // No-op for now
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);

    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }

  List<MoodImageData> _getInterpolatedMoodImages() {
    if (!_animationController.isAnimating || _waypointsList.length < 2) {
      return _randomMoodImages;
    }

    final progress = _animation.value;

    // 将动画分为3个阶段，速度由快到慢
    // 第1阶段: 0.0-0.2 (快，占20%时间，约0.6秒)
    // 第2阶段: 0.2-0.5 (中，占30%时间，约0.9秒)
    // 第3阶段: 0.5-1.0 (慢，占50%时间，约1.5秒)

    int startWaypointIndex;
    int endWaypointIndex;
    double segmentProgress;

    if (progress <= 0.2) {
      // 第1阶段：快速移动
      startWaypointIndex = 0;
      endWaypointIndex = 1;
      segmentProgress = progress / 0.2;
    } else if (progress <= 0.5) {
      // 第2阶段：中速移动
      startWaypointIndex = 1;
      endWaypointIndex = 2;
      segmentProgress = (progress - 0.2) / 0.3;
    } else {
      // 第3阶段：慢速移动
      startWaypointIndex = 2;
      endWaypointIndex = 3;
      segmentProgress = (progress - 0.5) / 0.5;
    }

    final startWaypoint = _waypointsList[startWaypointIndex];
    final endWaypoint = _waypointsList[endWaypointIndex];

    return List.generate(_randomMoodImages.length, (index) {
      final start = startWaypoint[index];
      final end = endWaypoint[index];

      return MoodImageData(
        imagePath: start.imagePath,
        left: start.left + (end.left - start.left) * segmentProgress,
        top: start.top + (end.top - start.top) * segmentProgress,
        rotation:
            start.rotation + (end.rotation - start.rotation) * segmentProgress,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: Container(
          margin: EdgeInsets.only(
            left: 22,
            right: 22,
            top: MediaQuery.of(context).padding.top + 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            border: Border.all(color: AppColors.calendarBorder, width: 3),
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.homeCardContent),
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
                }),

                // 底部背景图片
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    AppAssets.homeBottomCover,
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
                      AppAssets.homeCaptureButton,
                      width: 97,
                      height: 97,
                    ),
                  ),
                ),
              ],
            ),
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
