import 'package:flutter/material.dart';

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
      color: Color.fromRGBO(0, 0, 0, 0.5), // 半透明黑色背景 (避免使用已弃用的 withOpacity)
      child: Center(
        child: Stack(
          clipBehavior: Clip.none, // 允许子元素溢出不被裁剪
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 58,
              height: 324,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                //居中
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 24),
                  Text("Tips", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Color(0xFF212121), decoration: TextDecoration.none)),
                  SizedBox(height: 20),
                  Text("Delete conversation", style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xFF212121), decoration: TextDecoration.none)),
                  SizedBox(height: 22),
                  Image.asset(
                    "assets/message/delete_message_icon.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 26),
                  Row(
                    children: [
                      SizedBox(width: 17),
                      Expanded(
                        child: GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            height: 53,
                            decoration: BoxDecoration(
                              color: Color(0xFFEDEDED),
                              borderRadius: BorderRadius.all(
                                Radius.circular(40)
                              ),
                            ),
                            child: Center(
                              child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Color(0xFF212121), decoration: TextDecoration.none)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 53,
                            decoration: BoxDecoration(
                              color: Color(0xFFF9E707),
                              borderRadius: BorderRadius.all(
                                  Radius.circular(40)
                              ),
                            ),
                            child: Center(
                              child: Text("Delete", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Color(0xFF212121), decoration: TextDecoration.none)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 17),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
            Positioned(
              right: -5,
              top: -5,
              child: GestureDetector(
                onTap: onCancel,
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
      ),
    );
  }
}