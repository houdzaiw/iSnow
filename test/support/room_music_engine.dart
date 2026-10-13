import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'room_microphone_engine.dart';

class RoomMusicEngine extends RoomMicrophoneEngine {
  final starts = <String>[];
  final loopbacks = <bool>[];
  final cycles = <int>[];
  final volumes = <int>[];
  final publishVolumes = <int>[];
  final seeks = <int>[];
  int stops = 0;
  int pauses = 0;
  int resumes = 0;
  int position = 2000;
  int duration = 60000;
  bool failStart = false;
  bool acknowledgeStart = true;
  Completer<void>? startGate;

  @override
  Future<void> startAudioMixing({
    required String filePath,
    required bool loopback,
    required int cycle,
    int startPos = 0,
  }) async {
    starts.add(filePath);
    loopbacks.add(loopback);
    cycles.add(cycle);
    await startGate?.future;
    if (failStart) throw StateError('start failed');
    if (acknowledgeStart) {
      musicState(AudioMixingStateType.audioMixingStatePlaying);
    }
  }

  void musicState(
    AudioMixingStateType state, {
    AudioMixingReasonType reason = AudioMixingReasonType.audioMixingReasonOk,
  }) => handler!.onAudioMixingStateChanged!(state, reason);
  @override
  Future<void> stopAudioMixing() async {
    stops++;
  }

  @override
  Future<void> pauseAudioMixing() async {
    pauses++;
  }

  @override
  Future<void> resumeAudioMixing() async {
    resumes++;
  }

  @override
  Future<void> adjustAudioMixingVolume(int volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> adjustAudioMixingPublishVolume(int volume) async {
    publishVolumes.add(volume);
  }

  @override
  Future<int> getAudioMixingDuration() async => duration;
  @override
  Future<int> getAudioMixingCurrentPosition() async => position;
  @override
  Future<void> setAudioMixingPosition(int pos) async {
    seeks.add(pos);
  }
}
