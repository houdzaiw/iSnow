import 'package:flutter/material.dart';

import '../configs/consts.dart';
import '../model/diary_entry.dart';

class VoiceView extends StatelessWidget {
  final DiaryEntry entry;
  final bool isDetail;
  const VoiceView({super.key, required this.entry, this.isDetail = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // 显示心情图标
        Row(
          children: [
            Spacer(),
            isDetail ? SizedBox.shrink() :
            Text(
              setDateFormatter(entry.date),
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFB2B2B2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 显示语音播放控件占位符
        Row(
          children: [
            const SizedBox(width: 12),
            if (entry.moodIndex != null &&
                entry.moodIndex! >= 0 &&
                entry.moodIndex! < moodImages.length)
              Image.asset(
                moodImages[entry.moodIndex!],
                width: 40,
                height: 40,
              ),
            const SizedBox(width: 8),
            Container(
              width: 179,
              height: 41,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/calendar/speak_bg_image.png'),
                  fit: BoxFit.contain,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 18),
                  Image.asset('assets/calendar/speak_icon.png', width: 10, height: 16),
                  SizedBox(width: 4),
                  Text(
                    entry.description ?? '',
                    style: TextStyle(color: Color(0xFF212121)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

}

