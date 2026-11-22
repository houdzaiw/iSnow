enum RoomDisconnectReason { authenticationTimeout, socketClosed, audioClosed }

/// Memory-only recovery target. Never retains passwords or authentication data.
class RoomRecoveryNotice {
  const RoomRecoveryNotice({
    required this.generation,
    required this.roomId,
    required this.reason,
  });

  final int generation;
  final String roomId;
  final RoomDisconnectReason reason;
}
