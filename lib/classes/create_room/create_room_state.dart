import '../../model/user_profile.dart';

const Object _unset = Object();

class CreateRoomState {
  const CreateRoomState({
    this.currentUser,
    this.title = '',
    this.description = '',
    this.avatarLocalPath,
    this.avatarUrl,
    this.isLoading = false,
    this.isUploadingAvatar = false,
    this.isSubmitting = false,
    this.loadError,
    this.message,
    this.messageKey,
  });

  factory CreateRoomState.initial() => const CreateRoomState();

  final UserData? currentUser;
  final String title;
  final String description;
  final String? avatarLocalPath;
  final String? avatarUrl;
  final bool isLoading;
  final bool isUploadingAvatar;
  final bool isSubmitting;
  final Object? loadError;
  final String? message;
  final String? messageKey;

  String get titleCountText => '${title.length}/20';
  String get descriptionCountText => '${description.length}/200';
  bool get canSubmit =>
      !isSubmitting &&
      !isUploadingAvatar &&
      avatarUrl?.trim().isNotEmpty == true &&
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty;

  CreateRoomState copyWith({
    Object? currentUser = _unset,
    String? title,
    String? description,
    Object? avatarLocalPath = _unset,
    Object? avatarUrl = _unset,
    bool? isLoading,
    bool? isUploadingAvatar,
    bool? isSubmitting,
    Object? loadError = _unset,
    Object? message = _unset,
    Object? messageKey = _unset,
  }) {
    return CreateRoomState(
      currentUser: identical(currentUser, _unset)
          ? this.currentUser
          : currentUser as UserData?,
      title: title ?? this.title,
      description: description ?? this.description,
      avatarLocalPath: identical(avatarLocalPath, _unset)
          ? this.avatarLocalPath
          : avatarLocalPath as String?,
      avatarUrl: identical(avatarUrl, _unset)
          ? this.avatarUrl
          : avatarUrl as String?,
      isLoading: isLoading ?? this.isLoading,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      loadError: identical(loadError, _unset) ? this.loadError : loadError,
      message: identical(message, _unset) ? this.message : message as String?,
      messageKey: identical(messageKey, _unset)
          ? this.messageKey
          : messageKey as String?,
    );
  }
}
