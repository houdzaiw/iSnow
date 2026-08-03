import 'package:flutter/material.dart';

import '../configs/consts.dart';
import '../model/diary_entry.dart';
import '../theme/app_theme.dart';
import 'voice_bubble.dart';

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
            const Spacer(),
            isDetail
                ? const SizedBox.shrink()
                : Text(
                    setDateFormatter(entry.date),
                    style: AppTextStyles.caption,
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
              Image.asset(moodImages[entry.moodIndex!], width: 40, height: 40),
            const SizedBox(width: 8),
            VoiceBubble(text: entry.description ?? ''),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
