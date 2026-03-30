import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/model/diary_entry.dart';
import 'dart:math';

import 'package:project/widgets/app_network_image.dart';

// 弹框图层类
class DialogOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const DialogOverlay({
    super.key,
    required this.onClose,
    required this.onOpen,
  });

  @override
  State<DialogOverlay> createState() => _DialogOverlayState();
}

class _DialogOverlayState extends State<DialogOverlay> {
  late final int _idx;
  late final String _idxStr;
  late final String _moodAsset;
  late final Future<DiaryEntry> _entryFuture;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _idx = rand.nextInt(20) + 1; // 1..20
    _idxStr = _idx < 10
        ? _idx.toString().padLeft(2, '0')
        : _idx.toString().padLeft(3, '0');
    _moodAsset = 'assets/mood/model_$_idxStr.png';
    _entryFuture = _loadRandomMoodEntry();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DiaryEntry>(
      future: _entryFuture,
      builder: (context, snapshot) {
        final url = snapshot.data?.avatar ?? '';
        print("url======$url.jpg");
        return Container(
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/home/capture_finished_pop.png',
                      width: 248,
                      height: 248,
                    ),
                    Positioned(
                      left: 0, right: 0, top: 0, bottom: 0,
                      child: Image.asset(
                        _moodAsset,
                        width: 160,
                        height: 160,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset("$url.jpg"),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      top: 20,
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Image.asset(
                          'assets/base/close_button_image.png',
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.onOpen,
                  child: Container(
                    width: 153,
                    height: 53,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9E707),
                      borderRadius: BorderRadius.circular(26.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<DiaryEntry> _loadRandomMoodEntry() async {
    final rand = Random();
    final idx = rand.nextInt(20); // 0..19 for list index
    final jsonString = await rootBundle.loadString('lib/model/moodcontent.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final map = jsonList[idx] as Map<String, dynamic>;

    return DiaryEntry()
      ..userId = (map['userId'] as num).toInt()
      ..nick = map['userNickname'] as String? ?? ''
      ..avatar = map['avatar'] as String? ?? ''
      ..date = DateTime.now()
      ..emoji = ''
      ..content = map['description'] as String? ?? ''
      ..description = map['description'] as String? ?? ''
      ..type = 'edit'
      ..moodIndex = (map['moodIndex'] as num?)?.toInt() ?? 0;
  }
}