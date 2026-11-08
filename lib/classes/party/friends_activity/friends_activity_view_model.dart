import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/home_feed_session.dart';
import '../model/home_friend_room.dart';
import '../model/home_history_room.dart';
import '../viewmodel/home_list_view_model.dart';
import 'friends_activity_repository.dart';

final friendsActivityProvider =
    StateNotifierProvider<
      HomeListViewModel<HomeFriendRoom>,
      HomeListState<HomeFriendRoom>
    >((ref) {
      ref.watch(homeFeedSessionProvider.select((v) => v.generation));
      final repo = ref.watch(friendsActivityRepositoryProvider);
      return HomeListViewModel((_) => repo.fetchFriends());
    });

final homeRoomHistoryProvider =
    StateNotifierProvider.autoDispose<
      HomeListViewModel<HomeHistoryRoom>,
      HomeListState<HomeHistoryRoom>
    >((ref) {
      ref.watch(homeFeedSessionProvider.select((v) => v.generation));
      final repo = ref.watch(friendsActivityRepositoryProvider);
      return HomeListViewModel(
        repo.fetchHistory,
        paginated: true,
        itemKey: (item) => item.roomId,
      );
    });

final homeOwnRoomIdProvider = FutureProvider.autoDispose<String?>((ref) {
  ref.watch(homeFeedSessionProvider.select((v) => v.generation));
  return ref.watch(friendsActivityRepositoryProvider).ownRoomId();
});
