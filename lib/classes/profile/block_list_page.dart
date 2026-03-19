import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/custom_scaffold.dart';

class BlockListPage extends HookConsumerWidget {
  const BlockListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScaffold(
      title: 'Block List',
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/base/bg_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // 头像和昵称部分
            Container(
              //安全区域适配
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 39,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [

                ],
              ),
            ),
            // ListView部分
            SizedBox()
          ],
        ),
      ),
    );
  }

  void onRightIconTap(BuildContext context) {
    // 跳转到消息页面
    print('跳转到消息页面');
    context.push('/messages');
  }
}