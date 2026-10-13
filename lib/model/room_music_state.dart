enum RoomMusicPlayback { stopped, preparing, playing, paused, failed }

class RoomMusicPlaybackState {
  const RoomMusicPlaybackState({
    this.status = RoomMusicPlayback.stopped,
    this.title = '',
    this.path,
    this.position = 0,
    this.duration = 0,
    this.volume = 50,
    this.completed = 0,
    this.error,
  });

  final RoomMusicPlayback status;
  final String title;
  final String? path;
  final int position;
  final int duration;
  final int volume;
  final int completed;
  final String? error;

  bool get isActive =>
      status == RoomMusicPlayback.playing ||
      status == RoomMusicPlayback.paused ||
      status == RoomMusicPlayback.preparing;

  RoomMusicPlaybackState copyWith({
    RoomMusicPlayback? status,
    int? position,
    int? duration,
    int? volume,
    int? completed,
    String? error,
  }) => RoomMusicPlaybackState(
    status: status ?? this.status,
    title: title,
    path: path,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    volume: volume ?? this.volume,
    completed: completed ?? this.completed,
    error: error,
  );
}
