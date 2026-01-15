import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../configs/app_Isar.dart';
import '../../configs/providers.dart';
import '../../model/diary_entry.dart';
import 'publish_edit_page.dart';
import 'publish_voice_page.dart';

class PublishPage extends HookConsumerWidget {
  final int? moodIndex;
  const PublishPage({super.key, this.moodIndex});

  // 保存数据到 Isar 数据库
  Future<void> _saveToDatabase(
    BuildContext context,
    WidgetRef ref,
    TabController tabController,
    String editDescription,
    List<String> editImagePaths,
    String voicePath,
  ) async {
    try {
      final isar = await IsarDB.instance.db;

      // 判断当前是 edit 还是 voice
      final currentType = tabController.index == 0 ? 'edit' : 'voice';

      // 创建日记条目
      final diaryEntry = DiaryEntry()
        ..date = DateTime.now()
        ..emoji = '' // 可以根据 moodIndex 设置 emoji
        ..moodIndex = moodIndex
        ..type = currentType
        ..createdAt = DateTime.now();

      if (currentType == 'edit') {
        // 编辑模式：保存描述和图片
        diaryEntry.description = editDescription;
        diaryEntry.images = editImagePaths;
        diaryEntry.content = editDescription; // 兼容旧字段
        diaryEntry.type = currentType;
      } else {
        // 语音模式：保存语音路径
        // TODO: 语音功能待实现
        diaryEntry.description = editDescription;
        diaryEntry.images = editImagePaths;
        diaryEntry.content = voicePath;
        diaryEntry.type = currentType;
      }

      // 保存到数据库
      await isar.writeTxn(() async {
        await isar.diaryEntrys.put(diaryEntry);
      });

      // 触发刷新
      ref.read(diaryRefreshProvider.notifier).state++;

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功！')),
        );
        // 关闭弹框
        Navigator.pop(context);
      }
    } catch (e) {
      // ...existing code...
    }
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化图标数组
    final tabIcons = [
      Icons.edit,
      Icons.mic,
    ];

    // 使用 useSingleTickerProvider 创建 TabController
    final tabController = useTabController(initialLength: tabIcons.length);

    // 存储编辑页面的数据
    final editDescription = useState('');
    final editImagePaths = useState<List<String>>([]);

    // 存储语音页面的数据
    final voicePath = useState('');

    // 监听 TabController 变化以触发重建
    final currentTabIndex = useState(0);
    useEffect(() {
      void listener() {
        currentTabIndex.value = tabController.index;
      }
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.64,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TabBar with icon tabs
            Row(
              children: [
                const SizedBox(width: 24),
                const SizedBox(width: 36),
                Expanded(
                  child: TabBar(
                    controller: tabController,
                    indicator: const BoxDecoration(),
                    labelPadding: EdgeInsets.zero,
                    tabs: tabIcons.asMap().entries.map((entry) {
                      int index = entry.key;
                      IconData iconData = entry.value;
                      bool isSelected = tabController.index == index;
                      return Tab(
                        child: Container(
                          width: 99,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF9E707)
                                : const Color(0xFFE3E3E3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              size: 22,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 36),
                // 右边增加发送按钮
                GestureDetector(
                  onTap: () async {
                    // 判断当前是编辑还是语音模式，并保存数据
                    if (tabController.index == 0) {
                      // 编辑模式：检查是否有内容
                      if (editDescription.value.isEmpty && editImagePaths.value.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入内容或选择图片')),
                        );
                        return;
                      }
                    } else {
                      // 语音模式：检查是否有语音
                      if (voicePath.value.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请录制语音')),
                        );
                        return;
                      }
                    }

                    // 保存到数据库
                    await _saveToDatabase(
                      context,
                      ref,
                      tabController,
                      editDescription.value,
                      editImagePaths.value,
                      voicePath.value,
                    );
                  },
                  child: Image.asset(
                    'assets/calendar/send_post.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // TabBarView with content
            Expanded(
              child: TabBarView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: tabController,
                children: [
                  // Edit mood tab content
                  PublishEditPage(
                    moodIndex: moodIndex,
                    onSave: (description, imagePaths) {
                      editDescription.value = description;
                      editImagePaths.value = imagePaths;
                    },
                  ),
                  // Voice mood tab content
                  PublishVoicePage(
                    moodIndex: moodIndex,
                    onSave: (voicePathValue, inSeconds) {
                      editDescription.value = inSeconds;
                      voicePath.value = voicePathValue;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

