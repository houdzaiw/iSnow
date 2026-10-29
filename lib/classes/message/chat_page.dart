import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../configs/consts.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_scaffold.dart';
import 'chat_content.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key, required this.targetUID, this.title});
  final String targetUID;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomScaffold(
    title: title?.trim().isNotEmpty == true
        ? title!.trim()
        : targetUID.isEmpty
        ? context.l10n.t('chat.title')
        : targetUID,
    rightIconPath: AppAssets.moreButton,
    onRightIconTap: () => showUserActionOptions(context, includeDelete: false),
    body: targetUID.trim().isEmpty
        ? Center(child: Text(context.l10n.t('chat.targetMissing')))
        : ChatContent(targetUID: targetUID),
  );
}
