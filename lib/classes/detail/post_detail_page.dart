import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/content_view.dart';

import '../../configs/consts.dart';
import '../../manager/app_Isar.dart';
import '../../manager/providers.dart';
import '../../model/diary_entry.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/voice_view.dart';

class PostDetailPage extends HookConsumerWidget {
  final DiaryEntry entry;
  const PostDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSad = useState(entry.sad ?? false);
    final isHappy = useState(entry.happy ?? false);

    Future<void> updateDatabase() async {
      final isar = await IsarDB.instance.db;
      await isar.writeTxn(() async {
        // 根据 id 查找数据库中的记录
        final existingEntry = await isar.diaryEntrys.get(entry.id);
        if (existingEntry != null) {
          // 更新 sad 和 happy 字段
          existingEntry.sad = isSad.value;
          existingEntry.happy = isHappy.value;
          // 保存更新后的记录
          await isar.diaryEntrys.put(existingEntry);
        }
        ref.read(diaryRefreshProvider.notifier).state++;
      });
    }

    final sad = isSad.value
        ? AppAssets.calendarFrustratedActive
        : AppAssets.calendarFrustrated;
    final happy = isHappy.value
        ? AppAssets.calendarRejoiceActive
        : AppAssets.calendarRejoice;

    return CustomScaffold(
      title: '心情详情',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _buildContainer(),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: AppRadius.cardBorder,
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    setDateFormatter(entry.date),
                    style: AppTextStyles.caption,
                  ),
                ),
                _ReactionButton(
                  asset: sad,
                  selected: isSad.value,
                  onTap: () {
                    isSad.value = !isSad.value;
                    if (isSad.value) {
                      isHappy.value = false;
                    }
                    updateDatabase();
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                _ReactionButton(
                  asset: happy,
                  selected: isHappy.value,
                  onTap: () {
                    isHappy.value = !isHappy.value;
                    if (isHappy.value) {
                      isSad.value = false;
                    }
                    updateDatabase();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer() {
    if (entry.type == 'voice') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppRadius.cardBorder,
          boxShadow: AppShadows.soft,
        ),
        child: VoiceView(entry: entry, isDetail: true),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppShadows.soft,
      ),
      child: ContentView(entry: entry, isDetail: true),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.fieldBackground
              : AppColors.cardBackground,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: selected ? AppColors.primaryPink : AppColors.divider,
          ),
        ),
        child: Center(child: Image.asset(asset, width: 22, height: 22)),
      ),
    );
  }
}
