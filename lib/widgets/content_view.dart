import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project/manager/user_manager.dart';
import 'package:project/widgets/voice_view.dart';

import '../configs/consts.dart';
import '../model/diary_entry.dart';
import 'app_network_image.dart';

class ContentView extends StatelessWidget {
  final DiaryEntry entry;
  final bool isDetail;
  const ContentView({super.key, required this.entry, this.isDetail = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示心情图标
        if (entry.moodIndex != null &&
            entry.moodIndex! >= 0 &&
            entry.moodIndex! < moodImages.length)
          Row(
            children: [
              AppNetworkImage(
                url: entry.userAvatar ?? UserManager.shared.avatar ?? defaultAvatar,
                width: 40,
                height: 40,
                radius: 20,
              ),
              const SizedBox(width: 8),
              Text(
                entry.userNickname ?? UserManager.shared.nick ??"This is my mood today",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const Spacer(),
              Image.asset(
                moodImages[entry.moodIndex!],
                width: 45,
                height: 45,
              ),
            ],
          ),
        const SizedBox(height: 8),
        // 显示描述内容
        (entry.type == 'voice') ? _buildVoiceWidget() : _buildTextWidget(),
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
        )
      ],
    );
  }

  Container _buildVoiceWidget() {
    return Container(
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
    );
  }

  Column _buildTextWidget() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.description != null && entry.description!.isNotEmpty)
            Text(
              entry.description!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF212121),
              ),
            ),
          // 显示图片
          if (entry.images != null && entry.images!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.images!.take(4).map((imagePath) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // 如果图片加载失败，显示占位图
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
  }
}

