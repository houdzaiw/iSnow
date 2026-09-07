part of '../party_page.dart';

class _PartyFeedView extends ConsumerWidget {
  const _PartyFeedView({required this.sortTab});

  final _FeedSortTab sortTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = _partyFeedViewModelProvider(sortTab);
    final notifier = ref.read(provider.notifier);
    return _FeedItemsView(
      state: ref.watch(provider),
      onRetry: notifier.refresh,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
    );
  }
}
