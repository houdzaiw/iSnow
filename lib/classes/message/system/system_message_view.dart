import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/system_message_card_data.dart';
import '../../../theme/app_theme.dart';
import '../chat_view_model.dart';
import 'system_message_card.dart';
import 'system_message_navigation.dart';

class SystemMessageView extends HookConsumerWidget {
  const SystemMessageView({
    super.key,
    required this.state,
    required this.viewModel,
    required this.scroll,
  });
  final ChatState state;
  final ChatViewModel viewModel;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = useRef(<Route<void>>[]);
    useEffect(() {
      void closeOwned() {
        for (final route in List.of(owned.value.reversed)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (route.isActive && route.navigator?.mounted == true) {
              route.navigator!.removeRoute(route);
            }
          });
        }
      }

      final remove = viewModel.addActionInvalidationListener(closeOwned);
      return () {
        remove();
        closeOwned();
      };
    }, [viewModel]);

    final language = context.l10n.locale.languageCode;
    final cards = viewModel.systemCards(language);

    Future<void> open(
      SystemMessageCardData card,
      SystemMessageActionKind kind,
    ) async {
      final request = viewModel.beginSystemAction(card.id, kind, language);
      if (request == null) return;
      bool current() =>
          context.mounted && viewModel.isSystemActionCurrent(request);
      try {
        final navigation = ref.read(systemMessageNavigatorProvider);
        if (request.action.destination == SystemMessageDestination.room) {
          await navigation.enterRoom(
            context,
            ref,
            request.action.roomId!,
            current,
          );
        } else if (current()) {
          final destination = navigation.destination(request.action);
          final route = MaterialPageRoute<void>(builder: (_) => destination);
          owned.value.add(route);
          try {
            await Navigator.of(context, rootNavigator: true).push(route);
            await route.completed;
          } finally {
            owned.value.remove(route);
          }
        }
      } catch (_) {
        if (context.mounted && current()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.t('message.system.openFailed')),
            ),
          );
        }
      } finally {
        viewModel.finishSystemAction(request);
      }
    }

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textInverse),
      );
    }
    if (cards.isEmpty) {
      return Center(
        child: Text(
          context.l10n.t('message.empty'),
          style: AppTextStyles.systemMessageBody,
        ),
      );
    }
    return ListView.builder(
      key: const ValueKey('system-message-history'),
      controller: scroll,
      reverse: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: cards.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == cards.length) {
          return Center(
            child: state.loadingMore
                ? const CircularProgressIndicator(color: AppColors.textInverse)
                : TextButton(
                    onPressed: viewModel.loadMore,
                    child: Text(
                      context.l10n.t('message.system.earlier'),
                      style: AppTextStyles.systemMessageBody,
                    ),
                  ),
          );
        }
        final card = cards[cards.length - index - 1];
        return SystemMessageCard(
          data: card,
          onImage: card.picture == null
              ? null
              : () => open(card, SystemMessageActionKind.image),
          onDetails: card.details(language) == null
              ? null
              : () => open(card, SystemMessageActionKind.details),
        );
      },
    );
  }
}
