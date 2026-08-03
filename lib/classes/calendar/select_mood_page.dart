import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../configs/consts.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'publish_page.dart';

class SelectMoodPage extends HookConsumerWidget {
  const SelectMoodPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.64,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
          ),
          child: Column(
            children: [
              Image.asset(
                AppAssets.lanhuCalendarDragHandle,
                width: 44,
                height: 4,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.l10n.t('publish.selectMood'),
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                  ),
                  children: moodImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imagePath = entry.value;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: AppColors.cardBackground,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.sheetBorder,
                          ),
                          builder: (ctx) {
                            return PublishPage(moodIndex: index);
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
