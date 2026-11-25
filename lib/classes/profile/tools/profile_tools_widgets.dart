import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../manager/api_error_message.dart';
import '../../../theme/app_theme.dart';
import '../membership/views/membership_widgets.dart';

export '../membership/views/membership_widgets.dart' show MembershipImage;

class ProfileToolsScaffold extends StatelessWidget {
  const ProfileToolsScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
    this.onBack,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ProfileToolsTheme.background,
    appBar: AppBar(
      title: Text(title),
      actions: actions,
      automaticallyImplyLeading: false,
      leading: TextButton(
        onPressed: onBack ?? () => Navigator.maybePop(context),
        child: const MembershipImage(
          AppAssets.backButton,
          size: ProfileToolsTheme.icon,
        ),
      ),
    ),
    body: SafeArea(top: false, child: child),
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            top: false,
            child: Padding(padding: ProfileToolsTheme.padding, child: bottom),
          ),
  );
}

class ProfileToolsError extends StatelessWidget {
  const ProfileToolsError({super.key, this.error, required this.retry});
  final Object? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: ProfileToolsTheme.padding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          userFacingErrorMessage(
            error,
            fallback: context.l10n.t('tools.failed'),
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: ProfileToolsTheme.body,
        ),
        TextButton(
          onPressed: retry,
          child: Text(context.l10n.t('tools.retry')),
        ),
      ],
    ),
  );
}

void profileToolsNotice(
  BuildContext context,
  Object? error, {
  String key = 'tools.failed',
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error == null
            ? context.l10n.t(key)
            : userFacingErrorMessage(error, fallback: context.l10n.t(key)),
      ),
    ),
  );
}

Future<bool> profileToolsConfirm(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.l10n.t('tools.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.l10n.t('tools.confirm')),
          ),
        ],
      ),
    ) ??
    false;
