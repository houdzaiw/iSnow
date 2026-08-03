import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/manager/app_Isar.dart';
import 'package:project/model/blocked_user.dart';
import 'package:project/widgets/custom_scaffold.dart';

final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final isar = await IsarDB.instance.db;
  return isar.blockedUsers.where().findAll();
});

class BlockListPage extends HookConsumerWidget {
  const BlockListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return CustomScaffold(
      title: 'Block List',
      body: Column(
        children: [
          SizedBox(height: 15),
          Expanded(
            child: blockedUsersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No blocked users',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage("${user.avatar}.jpg"),
                        onBackgroundImageError: (_, __) {},
                        child: user.avatar == null || user.avatar!.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.nick ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () async {
                          final isar = await IsarDB.instance.db;
                          await isar.writeTxn(() async {
                            await isar.blockedUsers.delete(user.id);
                          });
                          ref.invalidate(blockedUsersProvider);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  void onRightIconTap(BuildContext context) {
    context.push('/messages');
  }
}
