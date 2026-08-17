import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'profile_homepage_view_model.dart';
import 'views/profile_homepage_content_view.dart';

class ProfileHomepagePage extends ConsumerWidget {
  const ProfileHomepagePage({super.key, required this.targetUid});

  final int targetUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileHomepageViewModelProvider(targetUid));
    final notifier = ref.read(
      profileHomepageViewModelProvider(targetUid).notifier,
    );

    return ProfileHomepageContentView(
      state: state,
      onRefresh: notifier.refresh,
      onFollow: notifier.toggleFollow,
      onChat: () {
        final user = state.info?.user;
        final uid = user?.uid;
        if (uid == null || uid <= 0) return;
        context.push(
          Uri(
            path: '/chat-view',
            queryParameters: {
              'targetUID': uid.toString(),
              if (user!.nick.trim().isNotEmpty) 'title': user.nick.trim(),
            },
          ).toString(),
        );
      },
    );
  }
}
