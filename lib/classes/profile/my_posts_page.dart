import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../manager/providers.dart';
import '../../model/diary_entry.dart';
import '../../widgets/custom_scaffold.dart';
import '../../configs/consts.dart';

class MyPostsPage extends HookConsumerWidget {

  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryEntriesAsyncValue = ref.watch(diaryEntriesProvider);

    return CustomScaffold(
      title: 'My Posts',
      body: diaryEntriesAsyncValue.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: entries.length,
            itemBuilder: (_, index) {
              final entry = entries[index];
              if (entry.type == 'voice' ) {
                return _buildVoiceView(entry);
              }
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildContentView(entry),
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading posts',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(DiaryEntry entry) {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDate = dateFormatter.format(entry.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and emoji
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
                Text(
                  entry.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            if (entry.type == 'edit' && entry.description != null) ...[
              Text(
                entry.description ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Images preview
            if (entry.images != null && entry.images!.isNotEmpty) ...[
              _buildImagesPreview(entry.images!),
              const SizedBox(height: 8),
            ],

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: entry.type == 'voice'
                    ? const Color(0xFFF9E707).withValues(alpha: 0.2)
                    : const Color(0xFF212121).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.type == 'voice' ? '🎤 Voice' : '✏️ Text',
                style: TextStyle(
                  fontSize: 12,
                  color: entry.type == 'voice'
                      ? const Color(0xFFF9E707)
                      : const Color(0xFF212121),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesPreview(List<String> images) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(images[0]),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          images.length,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(images[index]),
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceView(DiaryEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // 显示心情图标
        Row(
          children: [
            Spacer(),
            Text(
              _dateFormatter(entry.date),
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
  Widget _buildContentView(DiaryEntry entry) {
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
              Text(
                _dateFormatter(entry.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB2B2B2),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        // 显示描述内容
        if (entry.description != null &&
            entry.description!.isNotEmpty)
          Text(
            entry.description!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF212121)),
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
  String _dateFormatter(DateTime date) {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final formattedDate = dateFormatter.format(date);
    return formattedDate;
  }
}


