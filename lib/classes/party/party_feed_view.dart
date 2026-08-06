part of 'party_page.dart';

class _PartyFeedView extends ConsumerWidget {
  const _PartyFeedView({required this.sortTab});

  final _FeedSortTab sortTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = _partyFeedViewModelProvider(sortTab);
    return _FeedItemsView(
      feedItems: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      onRefresh: () => ref.refresh(provider.future).then<void>((_) {}),
    );
  }
}
