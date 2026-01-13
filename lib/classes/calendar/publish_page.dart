import 'package:flutter/material.dart';

import 'publish_edit_page.dart';
import 'publish_voice_page.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 初始化图标数组
  final List<IconData> _tabIcons = [
    Icons.edit,
    Icons.mic,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabIcons.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    controller: _tabController,
                    indicator: const BoxDecoration(),
                    labelPadding: EdgeInsets.zero,
                    tabs: _tabIcons.asMap().entries.map((entry) {
                      int index = entry.key;
                      IconData iconData = entry.value;
                      bool isSelected = _tabController.index == index;
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
                  onTap: () {
                    // TODO: 实现发送功能
                    print('Send post tapped');
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
                controller: _tabController,
                children: [
                  // Edit mood tab content
                  PublishEditPage(),
                  // Voice mood tab content
                  PublishVoicePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

