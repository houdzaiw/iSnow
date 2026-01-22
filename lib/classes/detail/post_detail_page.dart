
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/content_view.dart';

import '../../model/diary_entry.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/voice_view.dart';

class PostDetailPage extends HookConsumerWidget {
  final DiaryEntry entry;
  const PostDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    return CustomScaffold(
      title: 'Edit Detail',
      body: _buildContainer(),
    );
  }
  Widget _buildContainer() {
    if (entry.type == 'voice' ) {
      return VoiceView(entry: entry);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ContentView(entry: entry),
    );
  }
}