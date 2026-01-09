import 'package:flutter/material.dart';


// 弹框图层类
class DialogOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const DialogOverlay({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5), // 半透明黑色背景
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 使用Stack来叠加头像和关闭按钮在图片上
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // 主图片capture_finished_pop.png，尺寸248x248
                  Image.asset(
                    'assets/home/capture_finished_pop.png',
                    width: 248,
                    height: 248,
                  ),
                  // 左边头像
                  Positioned(
                    left: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {}, // 防止点击头像时关闭弹框
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
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
                        'assets/base/close_button_image.png',
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Open按钮
              GestureDetector(
                onTap: () {
                  // TODO: 实现open按钮功能
                  onClose();
                },
                child: Container(
                  width: 153,
                  height: 53,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9E707),
                    borderRadius: BorderRadius.circular(26.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
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