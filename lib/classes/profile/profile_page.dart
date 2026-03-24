// dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/configs/consts.dart';
import 'package:project/manager/user_manager.dart';
import 'package:project/widgets/app_network_image.dart';
import 'profile_menu_item.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ProfileMenuData.getMenuItems();
    return Scaffold(
      extendBodyBehindAppBar: true,  // ★ 关键：让 body 内容延伸到 AppBar 后面
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset(
              "assets/message/message_icon.png",
              width: 24,
              height: 24,
            ),
            onPressed: () => onRightIconTap(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFFF6E5),
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
                  // 头像
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child:  AppNetworkImage(
                      url: UserManager.shared.avatar ?? defaultAvatar,
                      width: 100,
                      height: 100,
                      radius: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 昵称
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        UserManager.shared.nick ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          context.push('/edit-profile');
                        },
                        child: Image.asset(
                          'assets/profile/edit_icon.png',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            // ListView部分
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return Container(
                    height: 54,
                    margin: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
                    //圆角14
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Image.asset(item.icon ?? "", width: 27, height: 27),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(item.arrow, size: 16),
                      horizontalTitleGap: 0, // 设置leading和title之间的间距为8像素
                      onTap: () {
                        // 处理点击事件
                        print('点击了: ${item.name}');
                        //调用my posts 路由跳转
                        if (item.router.isNotEmpty) {
                          print('跳转到: ${item.router}');
                          context.push(item.router);
                        }

                      },
                    ),
                  );
                },
              ),
            ),
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
