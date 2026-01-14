import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../configs/consts.dart';
import 'publish_page.dart';

class SelectMoodPage extends HookConsumerWidget {
  const SelectMoodPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.64,
      child: Column(
        children: [
          // Header: Select Mood
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              'Select Mood',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ),
          // GridView
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 60,
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, //横轴四个子widget
                  childAspectRatio: 1.0, //宽高比为1时，子widget
                ),
                children: moodImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final imagePath = entry.value;
                  return GestureDetector(
                    onTap: () {
                      // 关闭当前 SelectMoodPage 弹框
                      Navigator.pop(context);

                      // 打开新的 PublishPage 弹框
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        builder: (ctx) {
                          return PublishPage(moodIndex: index);
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}