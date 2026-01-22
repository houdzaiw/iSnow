
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:project/widgets/content_view.dart';

import '../../configs/consts.dart';
import '../../manager/app_Isar.dart';
import '../../manager/providers.dart';
import '../../model/diary_entry.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/voice_view.dart';

class PostDetailPage extends HookConsumerWidget {
  final DiaryEntry entry;
  const PostDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSad = useState(entry.sad ?? false);
    final isHappy = useState(entry.happy ?? false);

    Future<void> updateDatabase() async {
      final isar = await IsarDB.instance.db;
      await isar.writeTxn(() async {
        // 根据 id 查找数据库中的记录
        final existingEntry = await isar.diaryEntrys.get(entry.id);
        if (existingEntry != null) {
          // 更新 sad 和 happy 字段
          existingEntry.sad = isSad.value;
          existingEntry.happy = isHappy.value;
          // 保存更新后的记录
          await isar.diaryEntrys.put(existingEntry);
        }
        ref.read(diaryRefreshProvider.notifier).state++;
      });
    }

    final sad = isSad.value ? 'assets/calendar/frustrated_icon_pre.png' : 'assets/calendar/frustrated_icon.png';
    final happy = isHappy.value ? 'assets/calendar/rejoice_icon_pre.png' : 'assets/calendar/rejoice_icon.png';

    // TODO: implement build
    return CustomScaffold(
      title: 'Edit Detail',
      body: Column(
        children: [
          _buildContainer(),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23),
            child: Row(
              children: [
                Text(
                  setDateFormatter(entry.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB2B2B2),
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        isSad.value = !isSad.value;
                        if (isSad.value) {
                          isHappy.value = false;
                        }
                        updateDatabase();
                      },
                      child: Image.asset(sad, width: 20, height: 20),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        isHappy.value = !isHappy.value;
                        if (isHappy.value) {
                          isSad.value = false;
                        }
                        updateDatabase();
                      },
                      child: Image.asset(happy, width: 20, height: 20),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildContainer() {
    if (entry.type == 'voice') {
      return VoiceView(entry: entry, isDetail: true);
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ContentView(entry: entry, isDetail: true)
    );
  }
}