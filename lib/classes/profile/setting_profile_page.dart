import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/classes/profile/profile_menu_item.dart';
import 'package:project/widgets/custom_scaffold.dart';

class SettingProfilePage extends HookConsumerWidget {
  const SettingProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = SettingMenuData.getMenuItems();
    return CustomScaffold(
      title: 'Settings',
      body: SizedBox(
        child: Container(
          height: 54.0 * menuItems.length,
          margin: EdgeInsets.only(top: 18, left: 12, right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (item.router.isNotEmpty) {
                      context.push(item.router);
                    }
                  },
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 17), child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(flex: 1),
                      // Icon(item.arrow, size: 16),
                      Image.asset('assets/base/next_button.png', width: 24, height: 24),
                    ],
                  )
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFF6F6F6),
            ),
          ),
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