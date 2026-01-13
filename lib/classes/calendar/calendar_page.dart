// dart
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// 模拟每天的「表情 / 状态」
  final Map<DateTime, String> emotionMap = {};

  @override
  void initState() {
    super.initState();

    /// 模拟数据
    for (int i = 0; i < 30; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      emotionMap[_normalize(day)] = ["😄", "😡", "😊", "😮", "😴"][i % 5];
    }
  }

  DateTime _normalize(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCalendar(),
            _buildDragHandle(),
            _buildList(),
          ],
        ),
      ),
    );
  }

  /// 顶部年月
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        "${_focusedDay.year}.${_focusedDay.month.toString().padLeft(2, '0')}",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 日历本体
  Widget _buildCalendar() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        if (details.primaryVelocity! < -50) {
          setState(() => _calendarFormat = CalendarFormat.month);
        } else if (details.primaryVelocity! > 50) {
          setState(() => _calendarFormat = CalendarFormat.week);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2030),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) =>
              isSameDay(day, _selectedDay),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },

          headerVisible: false,
          daysOfWeekHeight: 24,
          rowHeight: 60,

          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
          ),

          calendarBuilders: CalendarBuilders(
            defaultBuilder: (_, day, __) =>
                _buildDayCell(day, false),
            selectedBuilder: (_, day, __) =>
                _buildDayCell(day, true),
            todayBuilder: (_, day, __) =>
                _buildDayCell(day, false, isToday: true),
          ),
        ),
      ),
    );
  }

  /// 单个日期 Cell（上图标 + 下日期）
  Widget _buildDayCell(DateTime day, bool selected,
      {bool isToday = false}) {
    final emoji = emotionMap[_normalize(day)];

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
          Text(
            emoji ?? "⚪️",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
              isToday ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.orange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 中间拖拽条
  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// 下方列表
  Widget _buildList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 10,
        itemBuilder: (_, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Diary item ${index + 1} - ${_selectedDay.toLocal()}",
              style: const TextStyle(fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}
