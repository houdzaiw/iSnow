
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../widgets/custom_scaffold.dart';

class MessagePage extends HookConsumerWidget {
  const MessagePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    return CustomScaffold(
        title: 'Message',
        body: Center(
          child: Text('This is the Message Page'),
        ));
    }
  }