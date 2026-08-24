import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'create_room_state.dart';
import 'create_room_view_model.dart';

Future<String?> showCreateRoomSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: false,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.modalScrimStrong,
    builder: (_) => const CreateRoomSheet(),
  );
}

class CreateRoomSheet extends ConsumerWidget {
  const CreateRoomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRoomViewModelProvider);
    final notifier = ref.read(createRoomViewModelProvider.notifier);

    ref.listen<CreateRoomState>(createRoomViewModelProvider, (previous, next) {
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

    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewPadding.top - media.viewInsets.bottom;
    final sheetHeight = availableHeight < AppSpacing.createRoomSheetHeight
        ? availableHeight
        : AppSpacing.createRoomSheetHeight;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: sheetHeight,
          child: ClipRRect(
            borderRadius: AppRadius.sheetBorder,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.lanhuCreateRoomSheetBackground,
                    fit: BoxFit.fill,
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: _CreateRoomForm(
                    state: state,
                    onPickAvatar: () => _pickAvatar(context, notifier),
                    onTitleChanged: notifier.updateTitle,
                    onDescriptionChanged: notifier.updateDescription,
                    onSubmit: () => _submit(context, notifier),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(
    BuildContext context,
    CreateRoomViewModel notifier,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 88,
    );
    if (image == null) return;
    await notifier.uploadAvatar(image.path);
  }

  Future<void> _submit(
    BuildContext context,
    CreateRoomViewModel notifier,
  ) async {
    final roomId = await notifier.submit(
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (roomId == null || roomId.trim().isEmpty || !context.mounted) return;
    Navigator.of(context).pop(roomId.trim());
  }
}

class _CreateRoomForm extends StatelessWidget {
  const _CreateRoomForm({
    required this.state,
    required this.onPickAvatar,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onSubmit,
  });

  final CreateRoomState state;
  final VoidCallback onPickAvatar;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.createRoomTitleTop),
        Text(
          context.l10n.t('createRoom.title'),
          style: AppTextStyles.sheetTitle,
        ),
        const SizedBox(height: AppSpacing.createRoomAvatarTop),
        _RoomAvatarPicker(state: state, onTap: onPickAvatar),
        const SizedBox(height: AppSpacing.createRoomNameTop),
        _FormLabel(text: context.l10n.t('createRoom.name')),
        const SizedBox(height: AppSpacing.md),
        _SingleLineInput(
          initialValue: state.title,
          hintText: context.l10n.t('createRoom.nameHint'),
          countText: state.titleCountText,
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: AppSpacing.createRoomDescriptionTop),
        _FormLabel(text: context.l10n.t('createRoom.description')),
        const SizedBox(height: AppSpacing.md),
        _MultiLineInput(
          initialValue: state.description,
          hintText: context.l10n.t('createRoom.descriptionHint'),
          countText: state.descriptionCountText,
          onChanged: onDescriptionChanged,
        ),
        const SizedBox(height: AppSpacing.createRoomConfirmTop),
        _ConfirmButton(
          isSubmitting: state.isSubmitting,
          enabled: state.canSubmit,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _RoomAvatarPicker extends StatelessWidget {
  const _RoomAvatarPicker({required this.state, required this.onTap});

  final CreateRoomState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.t('createRoom.avatarTooltip'),
      child: InkWell(
        onTap: state.isUploadingAvatar ? null : onTap,
        borderRadius: AppRadius.fieldBorder,
        child: SizedBox(
          width: AppSpacing.createRoomAvatarSize,
          height: AppSpacing.createRoomAvatarSize,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: AppRadius.fieldBorder,
                child: SizedBox.expand(
                  child: _AvatarImage(
                    localPath: state.avatarLocalPath,
                    url: state.avatarUrl,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Image.asset(
                  AppAssets.lanhuCreateRoomCamera,
                  width: AppSpacing.createRoomCameraWidth,
                  height: AppSpacing.createRoomCameraHeight,
                ),
              ),
              if (state.isUploadingAvatar)
                const Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.overlay,
                    child: Center(
                      child: SizedBox(
                        width: AppSpacing.iconSizeMd,
                        height: AppSpacing.iconSizeMd,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.xxs,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.localPath, required this.url});

  final String? localPath;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final filePath = localPath;
    if (filePath != null && filePath.isNotEmpty) {
      return Image.file(File(filePath), fit: BoxFit.cover);
    }

    final source = url;
    if (source != null && source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Image.asset(
      AppAssets.lanhuCreateRoomAvatarSample,
      fit: BoxFit.cover,
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.createRoomHorizontalInset,
        0,
        AppSpacing.createRoomFieldRightInset,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: AppTextStyles.formLabel),
      ),
    );
  }
}

class _SingleLineInput extends StatelessWidget {
  const _SingleLineInput({
    required this.initialValue,
    required this.hintText,
    required this.countText,
    required this.onChanged,
  });

  final String initialValue;
  final String hintText;
  final String countText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      height: AppSpacing.createRoomFieldHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.createRoomCounterSpace,
              0,
            ),
            child: TextFormField(
              initialValue: initialValue,
              maxLength: 20,
              maxLines: 1,
              cursorColor: AppColors.primaryPink,
              style: AppTextStyles.sheetInput,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: AppTextStyles.sheetPlaceholder,
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
            right: AppSpacing.sm,
            child: Text(countText, style: AppTextStyles.sheetCounter),
          ),
        ],
      ),
    );
  }
}

class _MultiLineInput extends StatelessWidget {
  const _MultiLineInput({
    required this.initialValue,
    required this.hintText,
    required this.countText,
    required this.onChanged,
  });

  final String initialValue;
  final String hintText;
  final String countText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      height: AppSpacing.createRoomDescriptionHeight,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.createRoomCounterSpace,
              AppSpacing.xxl,
            ),
            child: TextFormField(
              initialValue: initialValue,
              maxLength: 200,
              maxLines: null,
              expands: true,
              cursorColor: AppColors.primaryPink,
              style: AppTextStyles.sheetInput,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: AppTextStyles.sheetPlaceholder,
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
            right: AppSpacing.sm,
            bottom: AppSpacing.lg,
            child: Text(countText, style: AppTextStyles.sheetCounter),
          ),
        ],
      ),
    );
  }
}

class _FieldFrame extends StatelessWidget {
  const _FieldFrame({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.createRoomHorizontalInset,
        0,
        AppSpacing.createRoomFieldRightInset,
        0,
      ),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.sheetInputBackground,
          borderRadius: AppRadius.fieldBorder,
        ),
        child: child,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.createRoomButtonHorizontalInset,
        0,
        AppSpacing.lg,
        0,
      ),
      child: SizedBox(
        height: AppSpacing.controlHeightLg,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.createRoomConfirmButton,
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
                      ? context.l10n.t('createRoom.submitting')
                      : context.l10n.t('createRoom.confirm'),
                  style: AppTextStyles.primaryButtonCompact,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
