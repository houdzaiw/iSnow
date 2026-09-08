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

class _FeedItemsView extends StatelessWidget {
  const _FeedItemsView({
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final _PartyFeedState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryPink,
        onRefresh: onRefresh,
        child: Center(
          child: _StateList(
            text: context.l10n.t('party.loadFailed'),
            actionLabel: context.l10n.t('app.retry'),
            onAction: () => onRetry(),
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryPink,
        onRefresh: onRefresh,
        child: Center(
          child: _StateList(text: context.l10n.t('party.noData')),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 160) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.primaryPink,
        onRefresh: onRefresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 110),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const _LoadMoreIndicator();
            }
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 8 : 12),
              child: _PartyCard(item: state.items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.item});

  final _PartyFeedItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.isEmpty
        ? context.l10n.t('party.untitled')
        : item.title;
    final hostName = item.hostName.isEmpty
        ? context.l10n.t('party.username')
        : item.hostName;

    return Container(
      height: 218,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 122,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: _PartyImage(
                    url: item.coverUrl,
                    assetName: AppAssets.lanhuPartyCover,
                    width: double.infinity,
                    height: 122,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _AudienceBadge(text: item.onlineText),
                ),
                _JoinButton(label: context.l10n.t('party.join')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AvatarImage(url: item.avatarUrl),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  hostName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF282C2B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (item.isLive) ...[
                const SizedBox(width: 6),
                _LiveBadge(label: context.l10n.t('party.onLive')),
              ],
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const _ShareButton(),
            ],
          ),
        ],
      ),
    );
  }
}
class _AudienceBadge extends StatelessWidget {
  const _AudienceBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AudioBars(),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
class _AudioBars extends StatelessWidget {
  const _AudioBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 9,
      height: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _AudioBar(height: 5),
          _AudioBar(height: 9),
          _AudioBar(height: 7),
        ],
      ),
    );
  }
}


class _AudioBar extends StatelessWidget {
  const _AudioBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: height,
      decoration: BorderRadius.circular(
        1,
      ).toBoxDecoration(color: AppColors.textInverse),
    );
  }
}
class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 52,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 49,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Image.asset(AppAssets.lanhuPartyShare, width: 16, height: 16),
    );
  }
}
