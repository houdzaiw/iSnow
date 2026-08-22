import '../../model/user_profile.dart';
import 'create_party_models.dart';

const Object _unset = Object();

class CreatePartyState {
  const CreatePartyState({
    required this.startTime,
    this.currentUser,
    this.tags = const [],
    this.selectedTagIds = const {},
    this.topic = '',
    this.description = '',
    this.durationMinutes = 30,
    this.coverLocalPath,
    this.coverUrl,
    this.isLoading = false,
    this.isUploadingCover = false,
    this.isSubmitting = false,
    this.loadError,
    this.message,
    this.messageKey,
  });

  factory CreatePartyState.initial() {
    return CreatePartyState(startTime: _nextHalfHour(DateTime.now()));
  }

  final UserData? currentUser;
  final List<CreatePartyTag> tags;
  final Set<int> selectedTagIds;
  final String topic;
  final String description;
  final int durationMinutes;
  final DateTime startTime;
  final String? coverLocalPath;
  final String? coverUrl;
  final bool isLoading;
  final bool isUploadingCover;
  final bool isSubmitting;
  final Object? loadError;
  final String? message;
  final String? messageKey;

  CreatePartyHost get host => CreatePartyHost.fromUser(currentUser);
  String get topicCountText => '${topic.length}/50';
  String get descriptionCountText => '${description.length}/500';
  bool get canSubmit => !isSubmitting && !isUploadingCover;

  List<CreatePartyTag> get selectedTags {
    return tags
        .where((tag) => selectedTagIds.contains(tag.id))
        .toList(growable: false);
  }

  CreatePartyState copyWith({
    Object? currentUser = _unset,
    List<CreatePartyTag>? tags,
    Set<int>? selectedTagIds,
    String? topic,
    String? description,
    int? durationMinutes,
    DateTime? startTime,
    Object? coverLocalPath = _unset,
    Object? coverUrl = _unset,
    bool? isLoading,
    bool? isUploadingCover,
    bool? isSubmitting,
    Object? loadError = _unset,
    Object? message = _unset,
    Object? messageKey = _unset,
  }) {
    return CreatePartyState(
      currentUser: identical(currentUser, _unset)
          ? this.currentUser
          : currentUser as UserData?,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      coverLocalPath: identical(coverLocalPath, _unset)
          ? this.coverLocalPath
          : coverLocalPath as String?,
      coverUrl: identical(coverUrl, _unset)
          ? this.coverUrl
          : coverUrl as String?,
      isLoading: isLoading ?? this.isLoading,
      isUploadingCover: isUploadingCover ?? this.isUploadingCover,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      loadError: identical(loadError, _unset) ? this.loadError : loadError,
      message: identical(message, _unset) ? this.message : message as String?,
      messageKey: identical(messageKey, _unset)
          ? this.messageKey
          : messageKey as String?,
    );
  }
}

DateTime _nextHalfHour(DateTime now) {
  final minute = now.minute < 30 ? 30 : 60;
  final rounded = DateTime(now.year, now.month, now.day, now.hour, minute);
  return rounded.isAfter(now)
      ? rounded
      : rounded.add(const Duration(minutes: 30));
}
