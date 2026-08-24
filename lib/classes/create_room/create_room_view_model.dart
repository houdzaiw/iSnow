import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'create_room_models.dart';
import 'create_room_repository.dart';
import 'create_room_state.dart';

final createRoomViewModelProvider =
    NotifierProvider.autoDispose<CreateRoomViewModel, CreateRoomState>(
      CreateRoomViewModel.new,
    );

class CreateRoomViewModel extends AutoDisposeNotifier<CreateRoomState> {
  CreateRoomRepository get _repository =>
      ref.read(createRoomRepositoryProvider);

  @override
  CreateRoomState build() {
    Future.microtask(loadInitialData);
    return CreateRoomState.initial();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, loadError: null);
    try {
      final user = await _repository.fetchCurrentUser();
      state = state.copyWith(currentUser: user, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, loadError: error);
    }
  }

  void updateTitle(String value) {
    state = state.copyWith(
      title: value.length <= 20 ? value : value.substring(0, 20),
      message: null,
      messageKey: null,
    );
  }

  void updateDescription(String value) {
    state = state.copyWith(
      description: value.length <= 200 ? value : value.substring(0, 200),
      message: null,
      messageKey: null,
    );
  }

  Future<void> uploadAvatar(String filePath) async {
    if (filePath.trim().isEmpty || state.isUploadingAvatar) return;
    state = state.copyWith(
      isUploadingAvatar: true,
      message: null,
      messageKey: null,
    );
    try {
      final avatarUrl = await _repository.uploadAvatar(filePath);
      state = state.copyWith(
        avatarLocalPath: filePath,
        avatarUrl: avatarUrl,
        isUploadingAvatar: false,
      );
    } catch (error) {
      state = state.copyWith(
        isUploadingAvatar: false,
        message: error.toString(),
      );
    }
  }

  Future<String?> submit({required String languageCode}) async {
    if (state.isSubmitting || state.isUploadingAvatar) return null;

    final validationKey = _validationMessageKey();
    if (validationKey != null) {
      state = state.copyWith(messageKey: validationKey, message: null);
      return null;
    }

    state = state.copyWith(isSubmitting: true, message: null, messageKey: null);
    late final String roomId;
    try {
      roomId = await _repository.openRoom(
        CreateRoomDraft(
          avatar: state.avatarUrl!.trim(),
          title: state.title.trim(),
          roomDesc: state.description.trim(),
          language: _normalizeLanguage(languageCode),
        ),
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        messageKey: 'createRoom.createFailed',
        message: null,
      );
      return null;
    }

    try {
      await _repository.fetchRemoteCurrentUser();
    } catch (error) {
      debugPrint('Refresh user after openRoom failed: $error');
    }

    try {
      await _repository.enterRoom(roomId);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        messageKey: 'createRoom.enterFailed',
        message: null,
      );
      return null;
    }

    state = state.copyWith(isSubmitting: false);
    return roomId;
  }

  String? _validationMessageKey() {
    if (state.avatarUrl?.trim().isNotEmpty != true) {
      return 'createRoom.avatarRequired';
    }
    if (state.title.trim().isEmpty) {
      return 'createRoom.titleRequired';
    }
    if (state.description.trim().isEmpty) {
      return 'createRoom.descriptionRequired';
    }
    return null;
  }

  String _normalizeLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    return normalized.isEmpty ? 'en' : normalized;
  }
}
