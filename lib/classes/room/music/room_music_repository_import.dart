part of 'room_music_repository.dart';

extension RoomMusicImport on RoomMusicRepository {
  Future<T> _edit<T>(Future<T> Function() action) {
    final task = _editQueue.then((_) => action());
    _editQueue = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<RoomMusicImportResult> _importMusic(
    Future<RoomMusicImportBatch> Function(int, bool Function()) import, {
    bool Function()? isCancelled,
  }) {
    final pending = _importTask;
    if (pending != null) return pending;
    final epoch = _authEpoch;
    final generation = sessionGeneration;
    bool cancelled() =>
        _disposed ||
        epoch != _authEpoch ||
        generation != sessionGeneration ||
        isCancelled?.call() == true;
    final task = _edit(() async {
      if (cancelled()) return const RoomMusicImportResult(cancelled: true);
      await load();
      final uid = _uid;
      if (cancelled()) return const RoomMusicImportResult(cancelled: true);
      if (uid == null) throw const NadyApiException(message: 'Not logged in');
      final batch = await import(uid, cancelled);
      final previous = _tracks;
      var saved = false;
      final retained = <String>{};
      try {
        if (cancelled() || uid != await _room.currentUid()) {
          return const RoomMusicImportResult(cancelled: true);
        }
        final merged = {for (final track in previous) track.id: track};
        for (final track in batch.tracks) {
          merged.putIfAbsent(track.id, () => track);
        }
        final next = List<RoomMusicTrack>.unmodifiable(merged.values);
        await _library.save(uid, next);
        if (cancelled() || uid != await _room.currentUid()) {
          await _library.save(uid, previous);
          return const RoomMusicImportResult(cancelled: true);
        }
        retained.addAll(next.map((track) => track.fileName));
        saved = true;
        _setTracks(next);
        return RoomMusicImportResult(
          addedCount: next.length - previous.length,
          importedCount: batch.tracks.length,
          failedCount: batch.failedCount,
        );
      } finally {
        if (saved) {
          batch.created.removeWhere(
            (track) => retained.contains(track.fileName),
          );
        }
        await _library.discard(uid, batch);
      }
    });
    _importTask = task;
    // Use both handlers so the bookkeeping future cannot leak an async error.
    void clear() {
      if (identical(_importTask, task)) _importTask = null;
    }

    unawaited(
      task.then<void>(
        (_) => clear(),
        onError: (Object _, StackTrace __) => clear(),
      ),
    );
    return task;
  }
}
