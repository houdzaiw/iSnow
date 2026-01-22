import 'dart:io';
import 'package:flutter/material.dart';

import '../configs/consts.dart';
import '../model/diary_entry.dart';

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
              Image.asset(
                moodImages[entry.moodIndex!],
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 8),
              Text(
                "This is my mood today",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const Spacer(),
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
        // 显示描述内容
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

