import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'profile_relation_type.dart';
import 'profile_relation_view_model.dart';
import 'views/profile_relation_content_view.dart';

export 'profile_relation_type.dart';

class ProfileRelationPage extends ConsumerWidget {
  const ProfileRelationPage({super.key, required this.type});

  final ProfileRelationType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileRelationViewModelProvider(type));
    final notifier = ref.read(profileRelationViewModelProvider(type).notifier);

    return ProfileRelationContentView(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      onToggleFollow: notifier.toggleFollow,
    );
  }
}
