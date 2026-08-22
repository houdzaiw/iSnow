import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'create_party_models.dart';
import 'create_party_state.dart';
import 'create_party_view_model.dart';

class CreatePartyPage extends ConsumerWidget {
  const CreatePartyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPartyViewModelProvider);
    final notifier = ref.read(createPartyViewModelProvider.notifier);

    ref.listen<CreatePartyState>(createPartyViewModelProvider, (
      previous,
      next,
    ) {
      if (previous?.message == next.message &&
          previous?.messageKey == next.messageKey) {
        return;
      }
      final message = next.messageKey == null
          ? next.message
          : context.l10n.t(next.messageKey!);
      if (message == null || message.trim().isEmpty) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CreatePartyNavBar(onBack: () => context.pop()),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryPink,
                onRefresh: notifier.loadInitialData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.formCardSpacing,
                    AppSpacing.sm,
                    AppSpacing.section,
                  ),
                  children: [
                    _HostCard(host: state.host),
                    const SizedBox(height: AppSpacing.formCardSpacing),
                    _CoverCard(
                      state: state,
                      onPickCover: () => _pickCover(context, notifier),
                    ),
                    const SizedBox(height: AppSpacing.formCardSpacing),
                    _TopicCard(state: state, onChanged: notifier.updateTopic),
                    const SizedBox(height: AppSpacing.formCardSpacing),
                    _DescriptionCard(
                      state: state,
                      onChanged: notifier.updateDescription,
                    ),
                    const SizedBox(height: AppSpacing.formCardSpacing),
                    _TimeCard(
                      state: state,
                      onDurationChanged: notifier.updateDuration,
                      onStartTimeTap: () =>
                          _showStartTimeSheet(context, notifier),
                    ),
                    const SizedBox(height: AppSpacing.formCardSpacing),
                    _TagCard(state: state, onTap: () => _showTagSheet(context)),
                    const SizedBox(height: AppSpacing.xxxl),
                    _ConfirmButton(
                      isSubmitting: state.isSubmitting,
                      enabled: state.canSubmit,
                      onPressed: () => _submit(context, notifier),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCover(
    BuildContext context,
    CreatePartyViewModel notifier,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1300,
      maxHeight: 488,
      imageQuality: 88,
    );
    if (image == null) return;
    await notifier.uploadCover(image.path);
  }

  Future<void> _showStartTimeSheet(
    BuildContext context,
    CreatePartyViewModel notifier,
  ) async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      builder: (_) => const _StartTimeSheet(),
    );
    if (selected != null) {
      notifier.updateStartTime(selected);
    }
  }

  Future<void> _showTagSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      builder: (_) => const _TagSheet(),
    );
  }

  Future<void> _submit(
    BuildContext context,
    CreatePartyViewModel notifier,
  ) async {
    final success = await notifier.submit();
    if (!success || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('createParty.createSuccess'))),
    );
    context.pop(true);
  }
}

class _CreatePartyNavBar extends StatelessWidget {
  const _CreatePartyNavBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.controlHeightLg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl),
              child: _AssetButton(
                assetName: AppAssets.lanhuCreatePartyNavBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
              ),
            ),
          ),
          Text(
            context.l10n.t('createParty.title'),
            style: AppTextStyles.navTitleStrong,
          ),
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.host});

  final CreatePartyHost host;

  @override
  Widget build(BuildContext context) {
    final countryCode = host.countryCode;
    return _FormCard(
      child: Row(
        children: [
          _Avatar(url: host.avatar),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (countryCode != null && countryCode.isNotEmpty)
                      countryCode,
                    host.name,
                  ].join(' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'ID：${host.idText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.formFieldHint.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.state, required this.onPickCover});

  final CreatePartyState state;
  final VoidCallback onPickCover;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RequiredLabel(text: context.l10n.t('createParty.coverPicture')),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.t('createParty.coverRequirement'),
            style: AppTextStyles.formHelper,
          ),
          const SizedBox(height: AppSpacing.xxl),
          GestureDetector(
            onTap: state.isUploadingCover ? null : onPickCover,
            child: SizedBox(
              height: AppSpacing.formCoverHeight,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: AppRadius.fieldBorder,
                child: _CoverPreview(state: state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.state});

  final CreatePartyState state;

  @override
  Widget build(BuildContext context) {
    final localPath = state.coverLocalPath;
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }

    final coverUrl = state.coverUrl;
    if (coverUrl != null && coverUrl.startsWith('http')) {
      return CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover);
    }

    return ColoredBox(
      color: AppColors.formInputBackground,
      child: Center(
        child: state.isUploadingCover
            ? const SizedBox(
                width: AppSpacing.iconSizeMd,
                height: AppSpacing.iconSizeMd,
                child: CircularProgressIndicator(strokeWidth: AppSpacing.xxs),
              )
            : Image.asset(
                AppAssets.lanhuCreatePartyAddCover,
                width: AppSpacing.iconSizeLg,
                height: AppSpacing.iconSizeLg,
              ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.state, required this.onChanged});

  final CreatePartyState state;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RequiredLabel(text: context.l10n.t('createParty.topic')),
          const SizedBox(height: AppSpacing.xxl),
          _FieldBox(
            height: AppSpacing.formFieldHeight,
            child: _CountedTextField(
              maxLength: 50,
              hintText: context.l10n.t('createParty.topicHint'),
              countText: state.topicCountText,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.state, required this.onChanged});

  final CreatePartyState state;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RequiredLabel(text: context.l10n.t('createParty.description')),
          const SizedBox(height: AppSpacing.xxl),
          _FieldBox(
            height: AppSpacing.formTextAreaHeight,
            child: _CountedTextField(
              maxLength: 500,
              hintText: context.l10n.t('createParty.descriptionHint'),
              countText: state.descriptionCountText,
              maxLines: null,
              expands: true,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.state,
    required this.onDurationChanged,
    required this.onStartTimeTap,
  });

  final CreatePartyState state;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onStartTimeTap;

  static const List<int> _durations = [30, 60, 90, 120, 150, 180];

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RequiredLabel(text: context.l10n.t('createParty.time')),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onStartTimeTap,
            borderRadius: AppRadius.fieldBorder,
            child: Row(
              children: [
                Text(
                  context.l10n.t('createParty.startTime'),
                  style: AppTextStyles.formHelper,
                ),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  child: Text(
                    _formatMinuteTime(state.startTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.formHelper,
                  ),
                ),
                Image.asset(
                  AppAssets.lanhuCreatePartyChevronRight,
                  width: AppSpacing.iconSizeXs,
                  height: AppSpacing.iconSizeSm,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  context.l10n.t('createParty.duration'),
                  style: AppTextStyles.formHelper,
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final duration in _durations)
                      _DurationChip(
                        minutes: duration,
                        selected: state.durationMinutes == duration,
                        onTap: () => onDurationChanged(duration),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillBorder,
      child: Container(
        width: AppSpacing.formChipWidth,
        height: AppSpacing.formChipHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.chipSelectedBackground
              : AppColors.chipBackground,
          borderRadius: AppRadius.pillBorder,
          border: selected
              ? Border.all(color: AppColors.chipSelectedText)
              : null,
        ),
        child: Text(
          '$minutes min',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: selected ? AppTextStyles.chipSelected : AppTextStyles.chip,
        ),
      ),
    );
  }
}

class _TagCard extends StatelessWidget {
  const _TagCard({required this.state, required this.onTap});

  final CreatePartyState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedTags = state.selectedTags;
    final languageCode = Localizations.localeOf(context).languageCode;
    final subtitle = selectedTags.isEmpty
        ? context.l10n.t('createParty.tagHint')
        : selectedTags.map((tag) => tag.nameForLocale(languageCode)).join(', ');

    return _FormCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.fieldBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('createParty.tag'),
              style: AppTextStyles.formLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.formHelper.copyWith(
                decoration: selectedTags.isEmpty
                    ? TextDecoration.underline
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.isSubmitting,
    required this.enabled,
    required this.onPressed,
  });

  final bool isSubmitting;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.controlHeightLg,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.voiceBubble,
          borderRadius: AppRadius.pillBorder,
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: AppRadius.pillBorder,
            child: Center(
              child: Text(
                isSubmitting
                    ? context.l10n.t('createParty.submitting')
                    : context.l10n.t('createParty.confirm'),
                style: AppTextStyles.primaryButtonLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.fieldBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.formInputBackground,
        borderRadius: AppRadius.fieldBorder,
      ),
      child: child,
    );
  }
}

class _CountedTextField extends StatelessWidget {
  const _CountedTextField({
    required this.maxLength,
    required this.hintText,
    required this.countText,
    required this.onChanged,
    this.maxLines = 1,
    this.expands = false,
  });

  final int maxLength;
  final String hintText;
  final String countText;
  final ValueChanged<String> onChanged;
  final int? maxLines;
  final bool expands;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: TextField(
            maxLength: maxLength,
            maxLines: maxLines,
            expands: expands,
            cursorColor: AppColors.primaryPink,
            style: AppTextStyles.formHelper,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: AppTextStyles.formFieldHint,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ),
        Positioned(
          right: AppSpacing.xxl,
          bottom: AppSpacing.sm,
          child: Text(countText, style: AppTextStyles.formFieldHint),
        ),
      ],
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.formLabel,
        children: [
          TextSpan(text: text),
          const TextSpan(text: '*', style: AppTextStyles.requiredMark),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: AppSpacing.avatarSizeMd,
        height: AppSpacing.avatarSizeMd,
        child: _NetworkOrAssetImage(
          url: url,
          assetName: AppAssets.lanhuCreatePartyAvatarSample,
        ),
      ),
    );
  }
}

class _NetworkOrAssetImage extends StatelessWidget {
  const _NetworkOrAssetImage({required this.url, required this.assetName});

  final String? url;
  final String assetName;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source != null && source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        placeholder: (_, __) => Image.asset(assetName, fit: BoxFit.cover),
        errorWidget: (_, __, ___) => Image.asset(assetName, fit: BoxFit.cover),
      );
    }
    return Image.asset(assetName, fit: BoxFit.cover);
  }
}

class _AssetButton extends StatelessWidget {
  const _AssetButton({
    required this.assetName,
    required this.tooltip,
    required this.onPressed,
  });

  final String assetName;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.pillBorder,
        child: SizedBox(
          width: AppSpacing.iconSizeXl,
          height: AppSpacing.iconSizeXl,
          child: Center(
            child: Image.asset(
              assetName,
              width: AppSpacing.iconSizeSm,
              height: AppSpacing.iconSizeSm,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartTimeSheet extends ConsumerWidget {
  const _StartTimeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPartyViewModelProvider);
    final start = _nextAvailableStartTime();
    final options = List.generate(
      16,
      (index) => start.add(Duration(minutes: 30 * index)),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('createParty.timeSheetTitle'),
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected =
                      _formatMinuteTime(option) ==
                      _formatMinuteTime(state.startTime);
                  return _SheetOption(
                    label: _formatMinuteTime(option),
                    selected: selected,
                    onTap: () => Navigator.of(context).pop(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSheet extends ConsumerWidget {
  const _TagSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPartyViewModelProvider);
    final notifier = ref.read(createPartyViewModelProvider.notifier);
    final languageCode = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('createParty.chooseTags'),
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.tags.isEmpty)
              _SheetOption(
                label: context.l10n.t('createParty.tagsLoadFailed'),
                selected: false,
                onTap: notifier.loadInitialData,
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final tag in state.tags)
                    _TagChip(
                      label: tag.nameForLocale(languageCode),
                      selected: state.selectedTagIds.contains(tag.id),
                      onTap: () => notifier.toggleTag(tag.id),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.xxl),
            _ConfirmButton(
              isSubmitting: false,
              enabled: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillBorder,
      child: Container(
        height: AppSpacing.formChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.chipSelectedBackground
              : AppColors.chipBackground,
          borderRadius: AppRadius.pillBorder,
          border: selected
              ? Border.all(color: AppColors.chipSelectedText)
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: selected ? AppTextStyles.chipSelected : AppTextStyles.chip,
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.fieldBorder,
      child: Container(
        height: AppSpacing.controlHeightMd,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.chipSelectedBackground
              : AppColors.formInputBackground,
          borderRadius: AppRadius.fieldBorder,
          border: selected
              ? Border.all(color: AppColors.chipSelectedText)
              : null,
        ),
        child: Text(
          label,
          style: selected
              ? AppTextStyles.chipSelected
              : AppTextStyles.formHelper,
        ),
      ),
    );
  }
}

DateTime _nextAvailableStartTime() {
  final now = DateTime.now();
  final minute = now.minute < 30 ? 30 : 60;
  return DateTime(now.year, now.month, now.day, now.hour, minute);
}

String _formatMinuteTime(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
