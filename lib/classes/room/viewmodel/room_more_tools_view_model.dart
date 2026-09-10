import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/room_more_tools_models.dart';
import '../room_more_tools_repository.dart';

final roomMoreToolsRepositoryProvider = Provider<RoomMoreToolsRepository>((
  ref,
) {
  return RoomMoreToolsRepository();
});

final roomMoreToolsViewModelProvider = StateNotifierProvider.autoDispose
    .family<RoomMoreToolsViewModel, RoomMoreToolsState, String>((ref, roomId) {
      return RoomMoreToolsViewModel(
        repository: ref.read(roomMoreToolsRepositoryProvider),
        roomId: roomId,
      );
    });

class RoomMoreToolsState {
  const RoomMoreToolsState({
    required this.roomId,
    this.loadingBanners = false,
    this.togglingLobbyType,
    this.activeLobbyType,
    this.additionalTools = const [],
    this.gameBanners = const [],
    this.errorMessage,
  });

  final String roomId;
  final bool loadingBanners;
  final int? togglingLobbyType;
  final int? activeLobbyType;
  final List<RoomToolBanner> additionalTools;
  final List<RoomToolBanner> gameBanners;
  final String? errorMessage;

  RoomMoreToolsState copyWith({
    bool? loadingBanners,
    Object? togglingLobbyType = _sentinel,
    Object? activeLobbyType = _sentinel,
    List<RoomToolBanner>? additionalTools,
    List<RoomToolBanner>? gameBanners,
    Object? errorMessage = _sentinel,
  }) {
    return RoomMoreToolsState(
      roomId: roomId,
      loadingBanners: loadingBanners ?? this.loadingBanners,
      togglingLobbyType: identical(togglingLobbyType, _sentinel)
          ? this.togglingLobbyType
          : togglingLobbyType as int?,
      activeLobbyType: identical(activeLobbyType, _sentinel)
          ? this.activeLobbyType
          : activeLobbyType as int?,
      additionalTools: additionalTools ?? this.additionalTools,
      gameBanners: gameBanners ?? this.gameBanners,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class RoomMoreToolsViewModel extends StateNotifier<RoomMoreToolsState> {
  RoomMoreToolsViewModel({
    required RoomMoreToolsRepository repository,
    required String roomId,
  }) : _repository = repository,
       super(RoomMoreToolsState(roomId: roomId)) {
    unawaited(loadBanners());
  }

  final RoomMoreToolsRepository _repository;

  Future<void> loadBanners() async {
    if (state.loadingBanners) return;

    state = state.copyWith(loadingBanners: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.fetchBanners(
          position: RoomMoreBannerPosition.additionalTool,
          roomId: state.roomId,
        ),
        _repository.fetchBanners(
          position: RoomMoreBannerPosition.game,
          roomId: state.roomId,
        ),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        loadingBanners: false,
        additionalTools: results[0],
        gameBanners: results[1],
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        loadingBanners: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> setLobbyMode(
    RoomLobbyToolType lobbyType, {
    required bool open,
  }) async {
    if (state.togglingLobbyType != null) return false;

    state = state.copyWith(
      togglingLobbyType: lobbyType.value,
      errorMessage: null,
    );
    try {
      await _repository.setLobbyOpen(
        roomId: state.roomId,
        lobbyType: lobbyType,
        open: open,
      );
      if (!mounted) return false;
      state = state.copyWith(
        togglingLobbyType: null,
        activeLobbyType: open ? lobbyType.value : null,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        togglingLobbyType: null,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}

const Object _sentinel = Object();
