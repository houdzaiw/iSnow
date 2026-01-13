
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PublishVoicePage extends HookConsumerWidget {
  const PublishVoicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    return Center(
      child: Text(
        'Voice Mood Content',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF757575),
        ),
      ),
    );
  }
}