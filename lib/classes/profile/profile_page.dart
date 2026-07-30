// dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/app_theme.dart';
import 'profile_menu_item.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ProfileMenuData.getMenuItems();
    return Scaffold(
      extendBodyBehindAppBar: true, // ★ 关键：让 body 内容延伸到 AppBar 后面
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset(AppAssets.messageIcon, width: 24, height: 24),
            onPressed: () => onRightIconTap(context),
          ),
        ],
      ),
      backgroundColor: AppColors.pageBackground,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
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
                      color: AppColors.avatarPlaceholder,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.textInverse,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 昵称
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('用户昵称', style: AppTextStyles.title),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () {
                          context.push('/edit-profile');
                        },
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            AppColors.primaryPink,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            AppAssets.profileEditIcon,
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    margin: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.md,
                    ),
                    //圆角14
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: AppRadius.cardBorder,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          item.icon,
                          size: 17,
                          color: AppColors.textInverse,
                        ),
                      ),
                      title: Text(item.name, style: AppTextStyles.menuItem),
                      trailing: Icon(
                        item.arrow,
                        size: 16,
                        color: AppColors.primaryPink,
                      ),
                      horizontalTitleGap: 0, // 设置leading和title之间的间距为8像素
                      onTap: () {
                        //调用my posts 路由跳转
                        if (item.name == '我的帖子') {
                          context.push('/my-posts');
                        }
                        if (item.name == '用户隐私') {
                          context.push(
                            '/web-view?title=用户隐私&uri=https://www.example.com/user-privacy',
                          );
                        }
                        if (item.name == '关于我们') {
                          context.push('/about-us');
                        }
                        if (item.name == '联系我们') {
                          context.push(
                            '/web-view?title=联系我们&uri=https://www.example.com/contact',
                          );
                        }
                        if (item.name == '设置') {
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

  void onRightIconTap(BuildContext context) {
    // 跳转到消息页面
    context.go('/messages');
  }
}
