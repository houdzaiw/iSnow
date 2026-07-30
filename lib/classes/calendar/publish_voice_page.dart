import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../configs/consts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/voice_bubble.dart';

class PublishVoicePage extends HookConsumerWidget {
  final int? moodIndex;
  final Function(String voicePath, String inSecond)? onSave;

  const PublishVoicePage({super.key, this.moodIndex, this.onSave});

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
      final hasPermission = await recorder.hasPermission();
      if (!context.mounted) return;

      if (hasPermission) {
        final dir = Directory.systemTemp;
        final filePath =
            '${dir.path}/isnow_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
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

          timer.value = Timer.periodic(const Duration(seconds: 1), (_) {
            recordDuration.value = Duration(
              seconds: recordDuration.value.inSeconds + 1,
            );
          });
        } catch (e) {
          // ignore errors silently for now
        }
      } else {
        // show permission denied
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有录音权限')));
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
          if (onSave != null) {
            onSave!(
              recordedFilePath.value!,
              _durationToSeconds(recordDuration.value),
            );
          }
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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: AppColors.calendarBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                moodIndex != null &&
                        moodIndex! >= 0 &&
                        moodIndex! < moodImages.length
                    ? moodImages[moodIndex!]
                    : AppAssets.calendarDefaultMood,
                width: 45,
                height: 45,
              ),
              const SizedBox(width: AppSpacing.md),
              VoiceBubble(text: _durationToSeconds(recordDuration.value)),
            ],
          ),
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
            const SizedBox(height: AppSpacing.section),
            Text(
              isRecording.value ? '点击停止录音' : '点击开始录音',
              style: AppTextStyles.bodyStrong,
            ),
            const SizedBox(height: AppSpacing.lg),
            Image.asset(
              AppAssets.calendarSpeakerButton,
              width: 116,
              height: 116,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _formatDuration(recordDuration.value),
              style: AppTextStyles.title,
            ),
          ],
        ),
      );
    }

    if (recordedFilePath.value != null && !isRecording.value) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.section),
        child: playButton(),
      );
    }
    return Center(child: recordButton());
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
