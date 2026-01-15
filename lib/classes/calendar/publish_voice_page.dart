import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

class PublishVoicePage extends HookConsumerWidget {
  final int? moodIndex;
  final Function(String voicePath)? onSave;

  const PublishVoicePage({
    super.key,
    this.moodIndex,
    this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // hooks state
    final isRecording = useState<bool>(false);
    final recordedFilePath = useState<String?>(null);
    final recordDuration = useState<Duration>(Duration.zero);
    final player = useMemoized(() => AudioPlayer(), []);
    final recorder = useMemoized(() => AudioRecorder(), []);
    final timer = useRef<Timer?>(null);

    useEffect(() {
      return () {
        timer.value?.cancel();
        player.dispose();
        recorder.dispose();
      };
    }, []);

    Future<void> startRecording() async {
      if (await recorder.hasPermission()) {
        final dir = Directory.systemTemp;
        final filePath = '${dir.path}/isnow_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        try {
          await recorder.start(
            RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: filePath,
          );
          recordedFilePath.value = null;
          recordDuration.value = Duration.zero;
          isRecording.value = true;

          timer.value = Timer.periodic(Duration(seconds: 1), (_) {
            recordDuration.value = Duration(seconds: recordDuration.value.inSeconds + 1);
          });
        } catch (e) {
          // ignore errors silently for now
        }
      } else {
        // show permission denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording permission denied')),
        );
      }
    }

    Future<void> stopRecording() async {
      try {
        timer.value?.cancel();
        timer.value = null;
        final path = await recorder.stop();
        isRecording.value = false;
        if (path != null) {
          recordedFilePath.value = path;
          // prepare player
          try {
            await player.setFilePath(path);
          } catch (e) {
            // ignore
          }
        }
      } catch (e) {
        // ignore
      }
    }

    Future<void> toggleRecording() async {
      // 检查录音状态
      if (isRecording.value) {
        // 正在录音，停止录音
        await stopRecording();
      } else {
        // 没有录音，开启录音
        await startRecording();
      }
    }

    Future<void> playOrPause() async {
      if (player.playing) {
        await player.pause();
      } else {
        await player.seek(Duration.zero);
        await player.play();
      }
    }

    Widget playButton() {
      return GestureDetector(
        onTap: () async {
          await playOrPause();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 16),
            Image.asset(
              moodIndex != null
                ? 'assets/mood/model_${moodIndex.toString().padLeft(2, '0')}.png'
                : 'assets/calendar/default_icon.png',
              width: 45,
              height: 45,
            ),
            SizedBox(width: 10),
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
                    _durationToSeconds(recordDuration.value),
                    style: TextStyle(color: Color(0xFF212121)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget recordButton() {
      // 否则显示录音按钮
      return GestureDetector(
        onTap: () async {
          await toggleRecording();
        },
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              "Click to ${isRecording.value ? 'stop' : 'record'}",
              style: TextStyle(color: Color(0xFF212121)),
            ),
            const SizedBox(height: 12),
            Container(
              width: 220,
              height: 116,
              // alignment: Alignment.center,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/calendar/speaker_button.png'),
                  // fit: BoxFit.contain,
                ),
              ),
              // child: Text(isRecording.value ? 'Click to stop' : 'Click to record', style: TextStyle(color: Color(0xFF212121))),
            ),
            const SizedBox(height: 12),
            Text(_formatDuration(recordDuration.value), style: TextStyle(color: Color(0xFF212121), fontSize: 18),)
          ],
        ),
      );
    }
    // 如果已经有录音文件，显示播放按钮
    if (recordedFilePath.value != null && !isRecording.value) {
      return Padding(padding: EdgeInsets.only(top: 42), child: playButton());
    }
    return Center(
      child: recordButton(),
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
  // 将recordDuration.value转为总共秒数
 String _durationToSeconds(Duration d) {
    return d.inSeconds.toString();
  }
}