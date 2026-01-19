
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../widgets/custom_scaffold.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    return CustomScaffold(
        title: 'chat',
        body: Center(
          child: Text('This is the chat Page'),
        )
    );
  }
}