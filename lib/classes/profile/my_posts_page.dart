import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../manager/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/content_view.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/voice_view.dart';

class MyPostsPage extends HookConsumerWidget {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryEntriesAsyncValue = ref.watch(diaryEntriesProvider);

    return CustomScaffold(
      title: '我的帖子',
      body: diaryEntriesAsyncValue.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.soft,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Image.asset(
                        AppAssets.lanhuProudMood,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text('暂无帖子', style: AppTextStyles.bodyStrong),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: entries.length,
            itemBuilder: (_, index) {
              final entry = entries[index];
              if (entry.type == 'voice') {
                return VoiceView(entry: entry);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: AppRadius.cardBorder,
                  boxShadow: AppShadows.soft,
                ),
                child: ContentView(entry: entry),
              );
            },
          );
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text('帖子加载失败', style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
