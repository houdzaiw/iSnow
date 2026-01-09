// dart
import 'package:flutter/material.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _moodImages = [
    'assets/mood/model_01.png',
    'assets/mood/model_02.png',
    'assets/mood/model_03.png',
    'assets/mood/model_04.png',
    'assets/mood/model_05.png',
    'assets/mood/model_06.png',
    'assets/mood/model_07.png',
    'assets/mood/model_08.png',
    'assets/mood/model_09.png',
    'assets/mood/model_010.png',
    'assets/mood/model_011.png',
    'assets/mood/model_012.png',
    'assets/mood/model_013.png',
    'assets/mood/model_014.png',
    'assets/mood/model_015.png',
    'assets/mood/model_016.png',
    'assets/mood/model_017.png',
    'assets/mood/model_018.png',
    'assets/mood/model_019.png',
    'assets/mood/model_020.png',
  ];

  final Random _random = Random();
  late List<MoodImageData> _randomMoodImages;

  @override
  void initState() {
    super.initState();
    _generateRandomMoodImages();
  }

  void _generateRandomMoodImages() {
    _randomMoodImages = _moodImages.map((imagePath) {
      return MoodImageData(
        imagePath: imagePath,
        left: _random.nextDouble() * 0.7, // 0-70% of screen width
        top: _random.nextDouble() * 0.7, // 0-70% of screen height
        rotation: _random.nextDouble() * 2 * pi, // 0-360 degrees in radians
      );
    }).toList();
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
              ..._randomMoodImages.map((moodData) {
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
                child: Image.asset(
                  'assets/home/capture_button.png',
                  width: 97,
                  height: 97,
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
