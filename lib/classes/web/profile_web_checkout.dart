import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../profile/tools/profile_tools_widgets.dart';
import '../wallet/wallet_models.dart';
import '../wallet/wallet_state.dart';
import '../wallet/wallet_view_model.dart';

/// H5 cannot start billing automatically: the native confirmation is explicit.
class ProfileWebCheckout extends ConsumerStatefulWidget {
  const ProfileWebCheckout({
    super.key,
    required this.product,
    required this.isCurrent,
  });
  final WalletRechargeProduct product;
  final bool Function() isCurrent;
  @override
  ConsumerState<ProfileWebCheckout> createState() => _ProfileWebCheckoutState();
}

class _ProfileWebCheckoutState extends ConsumerState<ProfileWebCheckout> {
  bool started = false;
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final state = ref.watch(walletViewModelProvider);
    ref.listen<WalletState>(walletViewModelProvider, (old, next) {
      if (!context.mounted || !widget.isCurrent() || !started) return;
      if (old != null &&
          old.purchaseProductId == product.id &&
          next.verifiedPaymentRevision > old.verifiedPaymentRevision) {
        Navigator.pop(context, true);
      } else if (next.noticeMessage != old?.noticeMessage ||
          next.noticeKey != old?.noticeKey) {
        final text =
            next.noticeMessage ??
            (next.noticeKey == null ? '' : context.l10n.t(next.noticeKey!));
        if (text.isNotEmpty) profileToolsNotice(context, text);
      }
    });
    return AlertDialog(
      title: Text(product.name),
      content: Text(
        '${product.coinAmount} ${context.l10n.t('tools.coins')} · ${product.currency} ${(product.currencyAmount / 100).toStringAsFixed(2)}',
      ),
      actions: [
        TextButton(
          onPressed: state.isPurchasing
              ? null
              : () => Navigator.pop(context, false),
          child: Text(context.l10n.t('tools.cancel')),
        ),
        ElevatedButton(
          onPressed:
              state.isPurchasing ||
                  ref.read(walletViewModelProvider.notifier).hasPendingCheckout
              ? null
              : () {
                  if (!widget.isCurrent()) return;
                  started = true;
                  ref
                      .read(walletViewModelProvider.notifier)
                      .purchase(
                        product,
                        isCurrent: () => context.mounted && widget.isCurrent(),
                      );
                },
          child: Text(context.l10n.t('tools.confirm')),
        ),
      ],
    );
  }
}
