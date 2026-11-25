import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../localization/app_localizations.dart';
import '../mine/profile_view_model.dart';
import '../tools/profile_tools_widgets.dart';

/// Shared confirmations keep account teardown (including room exit) in ProfileViewModel.
Future<void> confirmProfileAccountAction(
  BuildContext context,
  WidgetRef ref, {
  required bool delete,
}) async {
  if (ref.read(profileViewModelProvider).isSubmitting) return;
  final model = ref.read(profileViewModelProvider.notifier);
  final epoch = model.accountEpoch;
  final confirmed = await profileToolsConfirm(
    context,
    context.l10n.t(
      delete ? 'profile.deleteAccountMessage' : 'profile.logOutMessage',
    ),
  );
  if (!confirmed || !context.mounted || model.accountEpoch != epoch) return;
  final result = await (delete
      ? model.deleteAccount(expectedEpoch: epoch)
      : model.logout(expectedEpoch: epoch));
  if (!context.mounted) return;
  if (result) {
    context.go('/login');
  } else {
    profileToolsNotice(context, ref.read(profileViewModelProvider).actionError);
  }
}
