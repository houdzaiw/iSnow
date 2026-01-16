// dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'profile_menu_item.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = ProfileMenuData.getMenuItems();

    return Scaffold(
      appBar: null,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/profile/profile_bg_image.png'),
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
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 昵称
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Username',
                        style: TextStyle(
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
                      leading: Image.asset(item.icon, width: 27, height: 27),
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
                        if (item.name == 'My Posts') {
                          context.push('/my-posts');
                        }
                        if (item.name == 'User Privacy') {
                          context.push(
                            '/web-view?title=User Privacy&uri=https://www.example.com/user-privacy',
                          );
                        }
                        if (item.name == 'Settings') {
                          context.push('/settings');
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
}
