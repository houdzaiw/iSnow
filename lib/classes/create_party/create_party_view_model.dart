import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'create_party_models.dart';
import 'create_party_repository.dart';
import 'create_party_state.dart';

final createPartyViewModelProvider =
    AutoDisposeNotifierProvider<CreatePartyViewModel, CreatePartyState>(
      CreatePartyViewModel.new,
    );

class CreatePartyViewModel extends AutoDisposeNotifier<CreatePartyState> {
  CreatePartyRepository get _repository =>
      ref.read(createPartyRepositoryProvider);

  @override
  CreatePartyState build() {
    Future.microtask(loadInitialData);
    return CreatePartyState.initial();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(
      isLoading: true,
      loadError: null,
      message: null,
      messageKey: null,
    );
    Object? loadError;
    var canCreateParty = true;

    try {
      await _repository.preCheck();
    } catch (error) {
      canCreateParty = false;
      loadError = error;
      state = state.copyWith(message: error.toString());
    }

    try {
      final user = await _repository.fetchCurrentUser();
      state = state.copyWith(currentUser: user);
      final roomInfo = await _repository.fetchCurrentRoomInfo(user);
      state = state.copyWith(roomInfo: roomInfo);
    } catch (error) {
      loadError ??= error;
    }

    try {
      final tags = await _repository.fetchTags();
      state = state.copyWith(tags: tags);
    } catch (error) {
      loadError ??= error;
    }

    state = state.copyWith(
      isLoading: false,
      canCreateParty: canCreateParty,
      loadError: loadError,
    );
  }

  void updateTopic(String value) {
    state = state.copyWith(
      topic: value.length <= 50 ? value : value.substring(0, 50),
      message: null,
      messageKey: null,
    );
  }

  void updateDescription(String value) {
    state = state.copyWith(
      description: value.length <= 500 ? value : value.substring(0, 500),
      message: null,
      messageKey: null,
    );
  }

  void updateDuration(int minutes) {
    state = state.copyWith(
      durationMinutes: minutes,
      message: null,
      messageKey: null,
    );
  }

  void updateStartTime(DateTime startTime) {
    state = state.copyWith(
      startTime: startTime,
      message: null,
      messageKey: null,
    );
  }

  void toggleTag(int tagId) {
    final selected = state.selectedTagIds.toList(growable: true);
    if (selected.contains(tagId)) {
      selected.remove(tagId);
    } else {
      selected.add(tagId);
      if (selected.length > 2) {
        selected.removeAt(0);
      }
    }
    state = state.copyWith(
      selectedTagIds: selected.toSet(),
      message: null,
      messageKey: null,
    );
  }

  Future<void> uploadCover(String filePath) async {
    if (filePath.trim().isEmpty || state.isUploadingCover) return;
    state = state.copyWith(
      isUploadingCover: true,
      message: null,
      messageKey: null,
    );
    try {
      final coverUrl = await _repository.uploadCover(filePath);
      state = state.copyWith(
        coverLocalPath: filePath,
        coverUrl: coverUrl,
        isUploadingCover: false,
      );
    } catch (error) {
      state = state.copyWith(
        isUploadingCover: false,
        message: error.toString(),
      );
    }
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    final validationKey = _validationMessageKey();
    if (validationKey != null) {
      state = state.copyWith(messageKey: validationKey, message: null);
      return false;
    }

    state = state.copyWith(isSubmitting: true, message: null, messageKey: null);
    try {
      await _repository.createParty(
        CreatePartyDraft(
          picUrl: state.coverUrl!.trim(),
          topic: state.topic.trim(),
          description: state.description.trim(),
          duration: state.durationMinutes,
          beginTime: state.startTime,
          tagIdList: state.selectedTagIds
              .map((id) => id.toString())
              .toList(growable: false),
        ),
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (error) {
      state = state.copyWith(isSubmitting: false, message: error.toString());
      return false;
    }
  }

  String? _validationMessageKey() {
    if (!state.canCreateParty) {
      return 'createParty.preCheckFailed';
    }
    if (state.coverUrl?.trim().isNotEmpty != true) {
      return 'createParty.coverRequired';
    }
    if (state.topic.trim().isEmpty) {
      return 'createParty.topicRequired';
    }
    if (state.description.trim().isEmpty) {
      return 'createParty.descriptionRequired';
    }
    if (!state.startTime.isAfter(DateTime.now())) {
      return 'createParty.startTimeRequired';
    }
    if (state.durationMinutes < 30) {
      return 'createParty.durationRequired';
    }
    return null;
  }
}
