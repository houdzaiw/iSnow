import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/home_feed_session.dart';
import '../../room/more/room_entry_flow.dart';

final homeRoomOpeningProvider = StateProvider<bool>((ref) {
  ref.watch(homeFeedSessionProvider.select((s) => s.generation));
  return false;
});

void listenHomeSessionRoute(BuildContext context, WidgetRef ref) {
  final route = ModalRoute.of(context);
  ref.listen(homeFeedSessionProvider.select((s) => s.generation), (_, __) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && route?.isActive == true) {
        if (route!.settings is Page) {
          Navigator.of(context).popUntil((r) => identical(r, route));
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            router.go('/party');
          }
        } else {
          Navigator.of(context).removeRoute(route);
        }
      }
    });
  });
}

Future<void> openHomeActivityRoom(
  BuildContext context,
  WidgetRef ref,
  String? roomId,
  int uid,
) async {
  if (roomId == null || roomId.isEmpty || ref.read(homeRoomOpeningProvider)) {
    return;
  }
  final gate = ref.read(homeRoomOpeningProvider.notifier);
  final session = ref.read(homeFeedSessionProvider);
  final generation = session.generation;
  gate.state = true;
  try {
    await enterSharedRoom(
      context,
      ref,
      roomId,
      followUid: uid,
      isCurrent: () => context.mounted && session.generation == generation,
    );
  } finally {
    if (gate.mounted) gate.state = false;
  }
}
