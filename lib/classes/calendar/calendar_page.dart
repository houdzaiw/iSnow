// dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:project/classes/calendar/select_mood_page.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../manager/app_Isar.dart';
import '../../configs/consts.dart';
import '../../manager/providers.dart';
import '../../model/diary_entry.dart';

class CalendarPage extends HookConsumerWidget {
  const CalendarPage({super.key});

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarFormat = useState(CalendarFormat.week);
    final focusedDay = useState(DateTime.now());
    final selectedDay = useState(DateTime.now());
    final diaryEntries = useState<List<DiaryEntry>>([]);
    final emotionMap = useState<Map<DateTime, List<String>>>({});

    // 加载数据库中的日记条目
    Future<void> loadDiaryEntries() async {
      try {
        final isar = await IsarDB.instance.db;
        final entries = await isar.diaryEntrys.where().findAll();
        diaryEntries.value = entries;

        // 更新 emotionMap - 每个日期显示最后3个mood icon
        final newEmotionMap = <DateTime, List<String>>{};

        // 按日期分组
        final Map<DateTime, List<DiaryEntry>> entriesByDate = {};
        for (var entry in entries) {
          final normalizedDate = _normalize(entry.date);
          if (!entriesByDate.containsKey(normalizedDate)) {
            entriesByDate[normalizedDate] = [];
          }
          entriesByDate[normalizedDate]!.add(entry);
        }

        // 为每个日期获取最后3条记录的mood icon
        entriesByDate.forEach((date, dateEntries) {
          // 按时间倒序排序，获取最后3条
          dateEntries.sort((a, b) => b.date.compareTo(a.date));
          final last3Entries = dateEntries.take(3).toList();

          final moodIcons = <String>[];
          for (var entry in last3Entries) {
            if (entry.moodIndex != null &&
                entry.moodIndex! >= 0 &&
                entry.moodIndex! < moodImages.length) {
              moodIcons.add(moodImages[entry.moodIndex!]);
            }
          }

          if (moodIcons.isNotEmpty) {
            newEmotionMap[date] = moodIcons;
          }
        });

        emotionMap.value = newEmotionMap;
      } catch (e) {
        print('Error loading diary entries: $e');
      }
    }

    // 初始化时加载数据
    useEffect(() {
      loadDiaryEntries();
      return null;
    }, []);

    // 监听 refresh provider，当有新数据时自动刷新
    final refreshTrigger = ref.watch(diaryRefreshProvider);
    useEffect(() {
      if (refreshTrigger > 0) {
        loadDiaryEntries();
      }
      return null;
    }, [refreshTrigger]);

    // 获取选中日期的日记条目
    List<DiaryEntry> getEntriesForSelectedDay() {
      final normalized = _normalize(selectedDay.value);
      final entries = diaryEntries.value.where((entry) {
        return _normalize(entry.date).isAtSameMomentAs(normalized);
      }).toList();

      // 按时间倒序排序（最新的在前）
      entries.sort((a, b) => b.date.compareTo(a.date));

      return entries;
    }

    void toggleCalendar() {
      calendarFormat.value = calendarFormat.value == CalendarFormat.week
          ? CalendarFormat.month
          : CalendarFormat.week;
    }

    void expandCalendar() {
      if (calendarFormat.value == CalendarFormat.month) return;
      calendarFormat.value = CalendarFormat.month;
    }

    void collapseCalendar() {
      if (calendarFormat.value == CalendarFormat.week) return;
      calendarFormat.value = CalendarFormat.week;
    }

    Widget buildDayCell(DateTime day, bool selected, {bool isToday = false}) {
      final moodIcons = emotionMap.value[_normalize(day)];

      return Container(
        decoration: selected
            ? BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 显示mood icons（最多3个，重叠布局）
            if (moodIcons != null && moodIcons.isNotEmpty)
              SizedBox(
                height: 42,
                width: 50,
                child: Stack(
                  children: [
                    // 第3个图标（最旧的）- 中间偏下（最底层）
                    if (moodIcons.length > 2)
                      Positioned(
                        left: 0,
                        top: -3,
                        child: Image.asset(
                          moodIcons[2],
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    // 第2个图标 - 右上（中间层）
                    if (moodIcons.length > 1)
                      Positioned(
                        right: -4,
                        top: -2,
                        child: Image.asset(
                          moodIcons[1],
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    // 第1个图标（最新的）- 左上（最顶层）
                    if (moodIcons.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -3,
                        child: Image.asset(
                          moodIcons[0],
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              )
            else
              // 无数据时显示默认图标
              SizedBox(
                height: 30,
                child: Center(
                  child: Image.asset(
                    'assets/calendar/default_icon.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.orange : Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildHeader() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          "${focusedDay.value.year}.${focusedDay.value.month.toString().padLeft(2, '0')}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    Widget buildCalendar() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2030),
          focusedDay: focusedDay.value,
          calendarFormat: calendarFormat.value,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay.value),
          onDaySelected: (selected, focused) {
            selectedDay.value = selected;
            focusedDay.value = focused;
          },
          onPageChanged: (focused) {
            focusedDay.value = focused;
          },
          headerVisible: false,
          daysOfWeekHeight: 24,
          rowHeight: 60,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (_, day, __) => buildDayCell(day, false),
            selectedBuilder: (_, day, __) => buildDayCell(day, true),
            todayBuilder: (_, day, __) => buildDayCell(day, false, isToday: true),
          ),
        ),
      );
    }

    Widget buildDragHandle() {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: toggleCalendar,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity == null) return;

          if (details.primaryVelocity! < -50) {
            expandCalendar();
          } else if (details.primaryVelocity! > 50) {
            collapseCalendar();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Image.asset(
              calendarFormat.value == CalendarFormat.week
                  ? "assets/calendar/expand_button.png"
                  : "assets/calendar/fold_button.png",
              width: 36,
              height: 12,
            ),
          ),
        ),
      );
    }

    Widget buildList() {
      final entriesForDay = getEntriesForSelectedDay();

      return Expanded(
        child: entriesForDay.isEmpty
            ? Center(
                child: Text(
                  '暂无心情记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: entriesForDay.length,
                itemBuilder: (_, index) {
                  final entry = entriesForDay[index];
                  if (entry.type == 'voice' ) {
                    return _buildVoiceView(entry);
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildContentView(entry),
                  );
                },
              ),
      );
    }
    void onPublishPressed() async {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (ctx) {
          return const SelectMoodPage();
        },
      );
      // 关闭弹框后重新加载数据
      loadDiaryEntries();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      // 右下角悬浮发布按钮
      floatingActionButton: FloatingActionButton(
        onPressed: onPublishPressed,
        backgroundColor: const Color(0xFFF9E707),
        child: const Icon(
          Icons.add,
          color: Color(0xFF212121),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            buildCalendar(),
            buildDragHandle(),
            buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceView(DiaryEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // 显示心情图标
        Row(
          children: [
            Spacer(),
            Text(
              '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFB2B2B2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 显示语音播放控件占位符
        Row(
          children: [
            if (entry.moodIndex != null &&
                entry.moodIndex! >= 0 &&
                entry.moodIndex! < moodImages.length)
              Image.asset(
              moodImages[entry.moodIndex!],
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 8),
            Container(
              width: 179,
              height: 41,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/calendar/speak_bg_image.png'),
                  fit: BoxFit.contain,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 18),
                  Image.asset('assets/calendar/speak_icon.png', width: 10, height: 16),
                  SizedBox(width: 4),
                  Text(
                    entry.description ?? '',
                    style: TextStyle(color: Color(0xFF212121)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
  Widget _buildContentView(DiaryEntry entry) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示心情图标
          if (entry.moodIndex != null &&
              entry.moodIndex! >= 0 &&
              entry.moodIndex! < moodImages.length)
            Row(
              children: [
                Image.asset(
                  moodImages[entry.moodIndex!],
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          // 显示描述内容
          if (entry.description != null &&
              entry.description!.isNotEmpty)
            Text(
              entry.description!,
              style: const TextStyle(fontSize: 14),
            ),
          // 显示图片
          if (entry.images != null && entry.images!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.images!.take(4).map((imagePath) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // 如果图片加载失败，显示占位图
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          // 显示类型标签
          if (entry.type != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: entry.type == 'edit'
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.type == 'edit' ? '编辑' : '语音',
                  style: TextStyle(
                    fontSize: 10,
                    color: entry.type == 'edit'
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
              ),
            ),
        ],
      );
  }
}
