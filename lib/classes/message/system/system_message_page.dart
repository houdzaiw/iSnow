import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../chat_content.dart';

class SystemMessagePage extends StatelessWidget {
  const SystemMessagePage({
    super.key,
    required this.targetUID,
    required this.title,
  });
  final String targetUID, title;
  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('system-message-page'),
    backgroundColor: AppColors.systemMessageBackground,
    appBar: AppBar(
      backgroundColor: AppColors.systemMessageBackground,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleLarge?.merge(AppTextStyles.systemMessageTitle),
      title: Text(
        title,
        style: AppTextStyles.systemMessageTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: IconButton(
        tooltip: context.l10n.t('app.back'),
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Image.asset(
          AppAssets.backWhiteButton,
          width: AppSpacing.iconSizeMd,
        ),
      ),
    ),
    body: SafeArea(child: ChatContent(targetUID: targetUID, dark: true)),
  );
}
