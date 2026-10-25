import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'room_music_view_model.dart';

/// Shared by the room and playlist; only one host may claim a conflict dialog.
void listenRoomMusicTakeover(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) {
  final provider = roomMusicViewModelProvider(roomId);
  ref.listen(provider, (previous, next) async {
    final viewModel = ref.read(provider.notifier);
    if (!next.takeover || !viewModel.claimTakeoverDialog()) return;
    final revision = viewModel.takeoverRevision;
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.roomMoreSheet,
        title: Text(
          context.l10n.t('room.music.takeover'),
          style: AppTextStyles.roomMoreSectionTitle,
        ),
        content: Text(next.error ?? '', style: AppTextStyles.roomAudienceName),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.t('app.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.t('room.music.takeover')),
          ),
        ],
      ),
    );
    if (context.mounted && viewModel.mounted) {
      await viewModel.confirmTakeover(confirm == true, revision: revision);
    }
  });
}
