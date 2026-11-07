import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../membership_aux_view_model.dart';
import '../membership_models.dart';
import '../membership_repository.dart';
import '../membership_state.dart';
import '../membership_view_model.dart';
import 'membership_media.dart';
import 'membership_widgets.dart';

/// Owns only routes created by this membership page; session changes close them.
class MembershipFlows {
  MembershipFlows(this.context, this.ref) {
    _subscription = ref.listenManual(
      membershipRepositoryProvider,
      (_, _) => _closeRoutes(),
    );
  }
  final BuildContext context;
  final WidgetRef ref;
  final Set<Route<dynamic>> _routes = {};
  late final ProviderSubscription<MembershipRepository> _subscription;
  bool _alive = true, _busy = false;
  bool get active => _alive && context.mounted;
  Future<T?> sheet<T>(WidgetBuilder builder) async {
    if (!active) return null;
    final route = ModalBottomSheetRoute<T>(
      isScrollControlled: true,
      backgroundColor: MembershipTheme.panel,
      modalBarrierColor: MembershipTheme.barrier,
      shape: const RoundedRectangleBorder(
        borderRadius: MembershipTheme.sheetRadius,
      ),
      builder: (c) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(c).height * MembershipTheme.sheetFraction,
            ),
            child: SingleChildScrollView(
              padding: MembershipTheme.padding,
              child: builder(c),
            ),
          ),
        ),
      ),
    );
    return _push(route);
  }

  Future<T?> _push<T>(Route<T> route) async {
    if (!active) return null;
    _routes.add(route);
    try {
      return await Navigator.of(context, rootNavigator: true).push(route);
    } finally {
      _routes.remove(route);
    }
  }

  Future<bool> confirm(String text, {String? title}) async =>
      await _push<bool>(
        DialogRoute<bool>(
          context: context,
          barrierColor: MembershipTheme.barrier,
          builder: (c) => Dialog(
            backgroundColor: MembershipTheme.panel,
            shape: const RoundedRectangleBorder(
              borderRadius: MembershipTheme.radius,
            ),
            child: Padding(
              padding: MembershipTheme.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title ?? c.l10n.t('membership.confirm'),
                    style: MembershipTheme.title,
                  ),
                  MembershipTheme.sectionGap,
                  Text(
                    text,
                    style: MembershipTheme.body,
                    textAlign: TextAlign.center,
                  ),
                  MembershipTheme.sectionGap,
                  Row(
                    children: [
                      Expanded(
                        child: MembershipButton(
                          text: c.l10n.t('app.cancel'),
                          gold: false,
                          onTap: () => Navigator.pop(c, false),
                        ),
                      ),
                      MembershipTheme.rowGap,
                      Expanded(
                        child: MembershipButton(
                          text: c.l10n.t('auth.confirm'),
                          onTap: () => Navigator.pop(c, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ) ??
      false;
  void notice(String text) {
    if (active) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> act(
    MembershipAction action, {
    bool chooseRecipient = false,
    NobleReward? reward,
  }) async {
    final context = this.context;
    if (!active || _busy) return;
    _busy = true;
    try {
      MembershipRecipient? recipient;
      if (chooseRecipient) {
        // Each opening starts without a previous search result.
        ref.invalidate(membershipRecipientProvider(action));
        recipient = await sheet<MembershipRecipient>(
          (_) => MembershipRecipientSheet(action: action),
        );
        if (!active || !context.mounted || recipient == null) return;
      }
      final model = ref.read(membershipViewModelProvider.notifier);
      final operation = await model.prepare(
        action,
        recipient: recipient,
        reward: reward,
      );
      if (!active || !context.mounted) return;
      final label = switch (action) {
        MembershipAction.experienceCard => context.l10n.t(
          'membership.experienceCard',
          {'count': '1'},
        ),
        MembershipAction.unblock => context.l10n.t('membership.unblock'),
        _ => operation.label,
      };
      final values = {
        'coins': '${operation.coins}',
        'label': label,
        'days': '${operation.days}',
        'target': operation.targetName ?? context.l10n.t('membership.self'),
      };
      final confirmation = action == MembershipAction.unblock
          ? context.l10n.t('membership.unblockCost', values)
          : context.l10n.t(
              operation.coins > 0
                  ? 'membership.confirmPurchase'
                  : 'membership.confirmFree',
              values,
            );
      if (!await confirm(confirmation) || !active || !context.mounted) return;
      final result = await model.execute(operation);
      if (!active || !context.mounted) return;
      switch (result) {
        case MembershipSubmitResult.stale:
          return;
        case MembershipSubmitResult.insufficientCoins:
          if (await confirm(context.l10n.t('membership.insufficient')) &&
              active &&
              context.mounted) {
            await context.push('/wallet');
            if (active) await model.load(force: true);
          }
        case MembershipSubmitResult.failed:
          notice(
            membershipError(
              context,
              ref.read(membershipViewModelProvider).actionError,
            ),
          );
        case MembershipSubmitResult.success ||
            MembershipSubmitResult.refreshFailed:
          notice(
            context.l10n.t(
              result == MembershipSubmitResult.success
                  ? 'membership.success'
                  : 'membership.refreshFailed',
            ),
          );
          final animation = ref
              .read(membershipViewModelProvider)
              .successAnimation;
          model.clearAnimation();
          if (animation != null && animation.isNotEmpty) {
            await _push<void>(
              DialogRoute<void>(
                context: context,
                barrierColor: MembershipTheme.barrier,
                builder: (c) => GestureDetector(
                  onTap: () => Navigator.pop(c),
                  behavior: HitTestBehavior.opaque,
                  child: SafeArea(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MembershipMedia(
                          url: animation,
                          success: true,
                          onEnd: () {
                            if (c.mounted) Navigator.pop(c);
                          },
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: MembershipTheme.padding,
                            child: MembershipButton(
                              text: c.l10n.t('membership.close'),
                              onTap: () => Navigator.pop(c),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
      }
    } catch (error) {
      if (active && context.mounted) notice(membershipError(context, error));
    } finally {
      _busy = false;
    }
  }

  Future<void> preview(MembershipPrivilege privilege) => sheet<void>((c) {
    final detail = privilege.detail;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MembershipImage(
          detail?.icon ?? privilege.icon,
          size: MembershipTheme.badge,
        ),
        MembershipTheme.dialogGap,
        Text(
          detail?.title ?? privilege.name,
          style: MembershipTheme.title,
          textAlign: TextAlign.center,
        ),
        if (detail?.image.isNotEmpty == true) ...[
          MembershipTheme.dialogGap,
          AspectRatio(
            aspectRatio: MembershipTheme.galleryRatio,
            child: MembershipImage(
              detail!.image,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ],
        MembershipTheme.dialogGap,
        Text(
          detail?.description ?? privilege.description,
          style: MembershipTheme.body,
          textAlign: TextAlign.center,
        ),
        MembershipTheme.sectionGap,
        MembershipButton(
          text: c.l10n.t('membership.close'),
          onTap: () => Navigator.pop(c),
        ),
      ],
    );
  });
  void _closeRoutes() {
    final routes = _routes.toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final route in routes.reversed) {
        if (route.isActive) route.navigator?.removeRoute(route);
      }
    });
  }

  void dispose() {
    _alive = false;
    _subscription.close();
    _closeRoutes();
  }
}

class MembershipRecipientSheet extends ConsumerWidget {
  const MembershipRecipientSheet({super.key, required this.action});
  final MembershipAction action;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(membershipRecipientProvider(action));
    final model = ref.read(membershipRecipientProvider(action).notifier);
    final user = state.user;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.t(
            action == MembershipAction.unblock
                ? 'membership.unblock'
                : 'membership.sendTo',
          ),
          style: MembershipTheme.title,
        ),
        MembershipTheme.sectionGap,
        TextField(
          key: const ValueKey('membership-recipient-input'),
          keyboardType: TextInputType.number,
          style: MembershipTheme.body,
          onChanged: model.changed,
          onSubmitted: (_) => unawaited(model.search()),
          decoration: InputDecoration(
            hintText: context.l10n.t('membership.idHint'),
            hintStyle: MembershipTheme.caption,
            filled: true,
            fillColor: MembershipTheme.background,
          ),
        ),
        MembershipTheme.dialogGap,
        MembershipButton(
          text: context.l10n.t('membership.search'),
          busy: state.loading,
          onTap: state.loading ? null : model.search,
        ),
        if (state.error != null)
          Padding(
            padding: MembershipTheme.smallPadding,
            child: Text(
              membershipError(context, state.error),
              style: MembershipTheme.caption,
            ),
          ),
        if (user != null) ...[
          MembershipTheme.sectionGap,
          Row(
            children: [
              MembershipImage(
                user.user.avatar ?? '',
                size: MembershipTheme.avatar,
              ),
              MembershipTheme.rowGap,
              Expanded(
                child: Text(
                  '${user.user.nick ?? ''}\nID: ${user.user.userNo ?? user.user.uid}',
                  style: MembershipTheme.body,
                ),
              ),
            ],
          ),
          if (action == MembershipAction.unblock) ...[
            MembershipTheme.dialogGap,
            Text(
              context.l10n.t(
                user.blockStatus == 1
                    ? 'membership.unblockCost'
                    : 'membership.normalAccount',
                {'coins': '${user.unblockCoins}'},
              ),
              style: MembershipTheme.caption,
            ),
          ],
          MembershipTheme.sectionGap,
          MembershipButton(
            text: context.l10n.t('auth.confirm'),
            onTap: action == MembershipAction.unblock && user.blockStatus != 1
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context, user);
                  },
          ),
        ],
      ],
    );
  }
}
