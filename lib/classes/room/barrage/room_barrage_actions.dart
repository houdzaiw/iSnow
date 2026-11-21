part of 'room_barrage_view_model.dart';

extension RoomBarrageActions on RoomBarrageViewModel {
  Future<void> activate(
    RoomBarrageTask task,
    RoomBarrageNavigator navigator,
  ) async {
    if (!mounted ||
        _uid == null ||
        _actionBusy ||
        !_visible ||
        !identical(_queue.active, task)) {
      return;
    }
    final action = task.action(_roomId);
    if (action.kind == RoomBarrageActionKind.none) return;
    final uid = _uid;
    final auth = _authRevision;
    final actionRevision = ++_actionRevision;
    final originRoom = repository.roomGeneration;
    _activeNavigator = navigator;
    _actionBusy = true;
    _issue = null;
    bool alive() =>
        mounted &&
        _visible &&
        _uid == uid &&
        _authRevision == auth &&
        _actionRevision == actionRevision;
    bool original() => alive() && repository.roomGeneration == originRoom;
    _emit();
    try {
      switch (action.kind) {
        case RoomBarrageActionKind.enterRoom:
          await navigator.enterRoom(action.roomId, original);
        case RoomBarrageActionKind.profile:
          await navigator.profile(action.uid, original);
        case RoomBarrageActionKind.prize:
          if (task.prize != null) await navigator.prize(task.prize!, original);
        case RoomBarrageActionKind.web:
          if (action.url != null) await navigator.web(action.url!, original);
        case RoomBarrageActionKind.game:
        case RoomBarrageActionKind.gift:
          if (action.roomId.isEmpty) return;
          if (_roomId != action.roomId || repository.roomState.isMinimized) {
            _expectedRoom = action.roomId;
            if (!await navigator.enterRoom(action.roomId, original) ||
                !alive()) {
              return;
            }
            if (!await repository.waitForRoom(action.roomId, alive) ||
                !alive()) {
              return;
            }
          }
          final enteredGeneration = repository.roomGeneration;
          _expectedRoom = null;
          bool entered() =>
              alive() &&
              repository.roomGeneration == enteredGeneration &&
              repository.roomState.currentRoomId == action.roomId &&
              repository.roomState.isInRoom;
          if (!entered()) return;
          if (action.kind == RoomBarrageActionKind.gift) {
            await navigator.gift(action.roomId, action.giftId, entered);
          } else if (action.url != null) {
            await navigator.game(action.roomId, action.url!, entered);
          }
        case RoomBarrageActionKind.none:
          break;
      }
    } catch (error) {
      if (alive()) _emit(issue: userFacingErrorMessage(error));
    } finally {
      if (identical(_activeNavigator, navigator)) _activeNavigator = null;
      if (alive()) {
        _actionBusy = false;
        _expectedRoom = null;
        _emit();
      }
    }
  }
}
