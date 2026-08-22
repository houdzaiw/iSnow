import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'create_party_models.dart';
import 'create_party_repository.dart';
import 'create_party_state.dart';

final createPartyViewModelProvider =
    NotifierProvider<CreatePartyViewModel, CreatePartyState>(
      CreatePartyViewModel.new,
    );

class CreatePartyViewModel extends Notifier<CreatePartyState> {
  CreatePartyRepository get _repository =>
      ref.read(createPartyRepositoryProvider);

  @override
  CreatePartyState build() {
    Future.microtask(loadInitialData);
    return CreatePartyState.initial();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, loadError: null);
    Object? loadError;
    try {
      final user = await _repository.fetchCurrentUser();
      state = state.copyWith(currentUser: user);
    } catch (error) {
      loadError = error;
    }

    try {
      final tags = await _repository.fetchTags();
      state = state.copyWith(tags: tags);
    } catch (error) {
      loadError ??= error;
    }

    state = state.copyWith(isLoading: false, loadError: loadError);
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
    state = state.copyWith(durationMinutes: minutes);
  }

  void updateStartTime(DateTime startTime) {
    state = state.copyWith(startTime: startTime);
  }

  void toggleTag(int tagId) {
    final selected = {...state.selectedTagIds};
    if (!selected.add(tagId)) {
      selected.remove(tagId);
    }
    state = state.copyWith(selectedTagIds: selected);
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
          tagIdList: state.selectedTagIds.toList(growable: false),
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
    if (state.coverUrl?.trim().isNotEmpty != true) {
      return 'createParty.coverRequired';
    }
    if (state.topic.trim().isEmpty) {
      return 'createParty.topicRequired';
    }
    if (state.description.trim().isEmpty) {
      return 'createParty.descriptionRequired';
    }
    return null;
  }
}
