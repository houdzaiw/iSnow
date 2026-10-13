import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';

Future<bool?> showRoomChatClearDialog(BuildContext context) => showDialog<bool>(
  context: context,
  useRootNavigator: true,
  barrierColor: AppColors.roomExitScrim,
  builder: (dialogContext) => AlertDialog(
    key: const ValueKey('room-chat-clear-dialog'),
    backgroundColor: AppColors.roomMoreSheet,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
    title: Text(
      context.l10n.t('room.chat.clearConfirm'),
      style: AppTextStyles.roomMoreSectionTitle,
    ),
    actions: [
      TextButton(
        key: const ValueKey('room-chat-clear-cancel'),
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: Text(
          context.l10n.t('app.cancel'),
          style: AppTextStyles.roomAudienceName,
        ),
      ),
      TextButton(
        key: const ValueKey('room-chat-clear-confirm'),
        onPressed: () => Navigator.of(dialogContext).pop(true),
        child: Text(
          context.l10n.t('auth.confirm'),
          style: AppTextStyles.roomAudienceName.copyWith(
            color: AppColors.primaryPink,
          ),
        ),
      ),
    ],
  ),
);
