// dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../classes/oauth/provider/login_provider.dart';
import '../../localization/app_localizations.dart';
import '../../model/user_profile.dart';
import '../../theme/app_theme.dart';
import 'profile_menu_item.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ProfileMenuData.getMenuItems();
    final loginProvider = useMemoized(() => LoginProvider());
    final user = useState<UserData?>(null);
    final isLoading = useState(false);
    final errorText = useState<String?>(null);
    final loadFailedText = context.l10n.t('profile.loadFailed');

    useEffect(() {
      var cancelled = false;

      Future<void> loadProfile() async {
        user.value = await loginProvider.cachedUser();
        isLoading.value = true;
        try {
          final remoteUser = await loginProvider.getMyUserInfo();
          if (!cancelled) {
            user.value = remoteUser;
            errorText.value = null;
          }
        } catch (e) {
          if (!cancelled) {
            errorText.value = loadFailedText;
          }
        } finally {
          if (!cancelled) {
            isLoading.value = false;
          }
        }
      }

      loadProfile();
      return () {
        cancelled = true;
      };
    }, [loginProvider, loadFailedText]);

    final profileUser = user.value;
    final displayName = profileUser?.nick?.isNotEmpty == true
        ? profileUser!.nick!
        : context.l10n.t('profile.nickname');
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
                bottom: AppSpacing.section,
              ),
              child: Column(
                children: [
                  // 头像
                  _ProfileAvatar(avatar: profileUser?.avatar),
                  const SizedBox(height: AppSpacing.md),
                  // 昵称
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title,
                        ),
                      ),
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
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
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
                          Icons.person,
                          size: 17,
                          color: AppColors.textInverse,
                        ),
                      ),
                      title: Text(
                        context.l10n.t(item.titleKey),
                        style: AppTextStyles.menuItem,
                      ),
                      trailing: Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.primaryPink,
                      ),
                      horizontalTitleGap: 0, // 设置leading和title之间的间距为8像素
                      onTap: () {
                        //调用my posts 路由跳转
                        switch (item.action) {
                          case 'my-posts':
                            context.push('/my-posts');
                            break;
                          case 'privacy':
                            context.push(
                              '/web-view?title=${Uri.encodeComponent(context.l10n.t('profile.privacy'))}&uri=https://www.example.com/user-privacy',
                            );
                            break;
                          case 'about-us':
                            context.push('/about-us');
                            break;
                          case 'contact-us':
                            context.push(
                              '/web-view?title=${Uri.encodeComponent(context.l10n.t('profile.contactUs'))}&uri=https://www.example.com/contact',
                            );
                            break;
                          case 'settings':
                            context.push('/settings');
                            break;
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.avatar});

  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatar;
    return Container(
      width: 100,
      height: 100,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.avatarPlaceholder,
        shape: BoxShape.circle,
      ),
      child: imageUrl == null || imageUrl.isEmpty
          ? const Icon(Icons.person, size: 50, color: AppColors.textInverse)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person,
                size: 50,
                color: AppColors.textInverse,
              ),
            ),
    );
  }
}
