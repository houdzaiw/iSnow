import '../../../model/room_share_models.dart';

class RoomShareState {
  const RoomShareState({
    this.materialsLoading = true,
    this.recentLoading = true,
    this.friendsLoading = true,
    this.materialsLoaded = false,
    this.busy = false,
    this.isActive = true,
    this.hasMore = true,
    this.tab = RoomShareTab.share,
    this.materialIndex = 0,
    this.materials = const [],
    this.recent = const [],
    this.friends = const [],
    this.preview,
    this.materialsError,
    this.recentError,
    this.friendsError,
    this.error,
    this.query = '',
  });

  final bool materialsLoading, recentLoading, friendsLoading, materialsLoaded;
  final bool busy, isActive, hasMore;
  final RoomShareTab tab;
  final int materialIndex;
  final List<RoomShareMaterial> materials;
  final List<RoomShareContact> recent, friends;
  final RoomShareContent? preview;
  final String? materialsError, recentError, friendsError, error;
  final String query;
  bool get loading => materialsLoading || recentLoading || friendsLoading;

  RoomShareState copyWith({
    bool? materialsLoading,
    bool? recentLoading,
    bool? friendsLoading,
    bool? materialsLoaded,
    bool? busy,
    bool? isActive,
    bool? hasMore,
    RoomShareTab? tab,
    int? materialIndex,
    List<RoomShareMaterial>? materials,
    List<RoomShareContact>? recent,
    List<RoomShareContact>? friends,
    RoomShareContent? preview,
    String? materialsError,
    String? recentError,
    String? friendsError,
    String? error,
    String? query,
    bool clearPreview = false,
    bool clearMaterialsError = false,
    bool clearRecentError = false,
    bool clearFriendsError = false,
    bool clearError = false,
  }) => RoomShareState(
    materialsLoading: materialsLoading ?? this.materialsLoading,
    recentLoading: recentLoading ?? this.recentLoading,
    friendsLoading: friendsLoading ?? this.friendsLoading,
    materialsLoaded: materialsLoaded ?? this.materialsLoaded,
    busy: busy ?? this.busy,
    isActive: isActive ?? this.isActive,
    hasMore: hasMore ?? this.hasMore,
    tab: tab ?? this.tab,
    materialIndex: materialIndex ?? this.materialIndex,
    materials: materials ?? this.materials,
    recent: recent ?? this.recent,
    friends: friends ?? this.friends,
    preview: clearPreview ? null : preview ?? this.preview,
    materialsError: clearMaterialsError
        ? null
        : materialsError ?? this.materialsError,
    recentError: clearRecentError ? null : recentError ?? this.recentError,
    friendsError: clearFriendsError ? null : friendsError ?? this.friendsError,
    error: clearError ? null : error ?? this.error,
    query: query ?? this.query,
  );
}
