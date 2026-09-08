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
        child: Center(child: _StateList(text: context.l10n.t('party.noData'))),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.partyListHorizontalInset,
            0,
            AppSpacing.partyListHorizontalInset,
            AppSpacing.partyListBottomInset,
          ),
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
    final roomId = item.roomId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.canEnterRoom && roomId != null
          ? () => context.pushNamed('room', pathParameters: {'roomId': roomId})
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.partyCardHorizontalPadding,
          AppSpacing.partyCardTopPadding,
          AppSpacing.partyCardHorizontalPadding,
          AppSpacing.partyCardBottomPadding,
        ),
        decoration: const BoxDecoration(
          color: AppColors.partyCardBackground,
          borderRadius: AppRadius.cardBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PartyCover(item: item),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textInverse,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _AvatarImage(
                  url: item.avatarUrl,
                  size: AppSpacing.partyHostAvatarSize,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hostName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const _ShareButton(),
                const SizedBox(width: 12),
                _PartyActionButton(item: item),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyCover extends StatelessWidget {
  const _PartyCover({required this.item});

  final _PartyFeedItem item;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: AppSpacing.partyCardCoverHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: AppRadius.fieldBorder,
        child: Stack(
          children: [
            Positioned.fill(
              child: _PartyImage(
                url: item.coverUrl,
                assetName: AppAssets.lanhuPartyCover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            if (item.tags.isNotEmpty)
              PositionedDirectional(
                top: 0,
                start: 0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.partyCardTagMaxWidth,
                  ),
                  child: _PartyTagBadge(
                    tags: item.tags,
                    languageCode: languageCode,
                  ),
                ),
              ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.partyCardStatusMaxWidth,
                ),
                child: _PartyStatusBadge(item: item),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: _PartyAudienceBar(item: item),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyTagBadge extends StatelessWidget {
  const _PartyTagBadge({required this.tags, required this.languageCode});

  final List<_PartyTagItem> tags;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.partyCardBadgeHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.partyBadgeHorizontalPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.partyBadgeOverlay,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tag in tags) ...[
            _PartyTagIcon(url: tag.tagPic),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                tag.labelForLocale(languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
            if (tag != tags.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PartyTagIcon extends StatelessWidget {
  const _PartyTagIcon({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source == null || !source.startsWith('http')) {
      return const SizedBox.shrink();
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: source,
        width: AppSpacing.partyTagIconSize,
        height: AppSpacing.partyTagIconSize,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
        placeholder: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PartyStatusBadge extends StatelessWidget {
  const _PartyStatusBadge({required this.item});

  final _PartyFeedItem item;

  @override
  Widget build(BuildContext context) {
    final label = _partyStatusLabel(context, item);
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      height: AppSpacing.partyCardBadgeHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.partyBadgeHorizontalPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.partyBadgeOverlay,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.xl),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PartyStatusGlyph(item: item),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyStatusGlyph extends StatelessWidget {
  const _PartyStatusGlyph({required this.item});

  final _PartyFeedItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isLive) {
      return Container(
        width: AppSpacing.partyStatusDotSize,
        height: AppSpacing.partyStatusDotSize,
        decoration: BoxDecoration(
          color: AppColors.partyLiveDot,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textInverse),
        ),
      );
    }
    if (item.isWaiting) {
      return const _ClockGlyph(size: 12);
    }
    return const _StatusDot(size: AppSpacing.partyStatusDotSize);
  }
}

class _PartyAudienceBar extends StatelessWidget {
  const _PartyAudienceBar({required this.item});

  final _PartyFeedItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.partyCoverScrim),
      child: SizedBox(
        height: AppSpacing.partyCardAudienceBarHeight,
        child: Row(
          children: [
            const SizedBox(width: 12),
            item.isLive
                ? const _AudioBars()
                : const _ReminderGlyph(size: AppSpacing.iconSizeSm),
            const SizedBox(width: 4),
            Text(
              item.onlineText,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            _StackedAvatars(users: item.subscribeUsers),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars({required this.users});

  final List<_PartyUserItem> users;

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(8).toList(growable: false);
    if (visibleUsers.isEmpty) return const SizedBox.shrink();

    const avatarSize = AppSpacing.partySubscribeAvatarSize;
    const overlap = AppSpacing.partySubscribeAvatarOverlap;
    final width =
        avatarSize + (visibleUsers.length - 1) * (avatarSize - overlap);

    return SizedBox(
      width: width,
      height: avatarSize,
      child: Stack(
        children: [
          for (var index = 0; index < visibleUsers.length; index++)
            PositionedDirectional(
              end: index * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textInverse),
                ),
                child: ClipOval(
                  child: _AvatarImage(
                    url: visibleUsers[visibleUsers.length - 1 - index].avatar,
                    size: avatarSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioBars extends StatelessWidget {
  const _AudioBars({this.width = 16});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _AudioBar(height: 7, color: AppColors.textInverse),
          _AudioBar(height: 13, color: AppColors.textInverse),
          _AudioBar(height: 10, color: AppColors.textInverse),
        ],
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  const _AudioBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BorderRadius.circular(2).toBoxDecoration(color: color),
    );
  }
}

class _PartyActionButton extends StatelessWidget {
  const _PartyActionButton({required this.item});

  final _PartyFeedItem item;

  @override
  Widget build(BuildContext context) {
    final label = _partyActionLabel(context, item);
    final isMuted = item.isEnded || item.isClosed || item.isSubscribe;
    final textColor = item.isEnded || item.isClosed
        ? AppColors.partyActionDisabledText
        : AppColors.textInverse;

    return Container(
      width: AppSpacing.partyActionWidth,
      height: AppSpacing.partyActionHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isMuted
            ? AppColors.partyActionDisabledBackground
            : AppColors.partyActionBackground,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.isLive) ...[
            const _AudioBars(width: 12),
            const SizedBox(width: 4),
          ] else if (item.isWaiting) ...[
            const _ReminderGlyph(size: AppSpacing.partyActionIconSize),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSpacing.partyShareButtonSize,
      child: Center(
        child: Image.asset(
          AppAssets.lanhuPartyShare,
          width: AppSpacing.partyShareIconSize,
          height: AppSpacing.partyShareIconSize,
        ),
      ),
    );
  }
}

class _ReminderGlyph extends StatelessWidget {
  const _ReminderGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(
        painter: _ReminderGlyphPainter(AppColors.textInverse),
      ),
    );
  }
}

class _ClockGlyph extends StatelessWidget {
  const _ClockGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(
        painter: _ClockGlyphPainter(AppColors.textInverse),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.partyActionDisabledText,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ReminderGlyphPainter extends CustomPainter {
  const _ReminderGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final width = size.width;
    final height = size.height;
    final path = Path()
      ..moveTo(width * 0.24, height * 0.64)
      ..quadraticBezierTo(
        width * 0.5,
        height * 0.18,
        width * 0.76,
        height * 0.64,
      )
      ..lineTo(width * 0.83, height * 0.75)
      ..lineTo(width * 0.17, height * 0.75)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(width * 0.5, height * 0.12),
      Offset(width * 0.5, height * 0.22),
      paint,
    );
    canvas.drawCircle(
      Offset(width * 0.5, height * 0.86),
      width * 0.06,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ReminderGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ClockGlyphPainter extends CustomPainter {
  const _ClockGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(center, Offset(center.dx, center.dy - radius * 0.5), paint);
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.44, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

String _partyActionLabel(BuildContext context, _PartyFeedItem item) {
  if (item.isLive) return context.l10n.t('party.join');
  if (item.isWaiting) {
    return context.l10n.t(item.isSubscribe ? 'party.reminded' : 'party.remind');
  }
  if (item.isEnded) return context.l10n.t('party.ended');
  if (item.isClosed) return context.l10n.t('party.canceled');
  return context.l10n.t('party.remind');
}

String _partyStatusLabel(BuildContext context, _PartyFeedItem item) {
  if (item.isLive) return context.l10n.t('party.onLive');
  if (item.isWaiting) return _formatPartySchedule(context, item);
  if (item.isEnded) return context.l10n.t('party.ended');
  if (item.isClosed) return context.l10n.t('party.canceled');
  return '';
}

String _formatPartySchedule(BuildContext context, _PartyFeedItem item) {
  final start = item.beginTime;
  final end = item.endTime;
  if (start == null) return context.l10n.t('party.remind');

  final now = DateTime.now();
  final minutesUntilStart = start.difference(now).inMinutes;
  if (_isSameDate(start, now) &&
      minutesUntilStart >= 0 &&
      minutesUntilStart <= 30) {
    return context.l10n.t('party.startInMinutes', {
      'minutes': '${minutesUntilStart == 0 ? 1 : minutesUntilStart}',
    });
  }

  final dayOffset = _partyDayOffset(start, now);
  final dayLabel = _partyDayLabel(context, start, now);
  if (dayOffset == 2) return dayLabel;
  final range = end == null
      ? _formatClock(start)
      : '${_formatClock(start)}-${_formatClock(end)}';
  final nextDay = end != null && !_isSameDate(start, end)
      ? context.l10n.t('party.nextDay')
      : '';
  return '$dayLabel,$range$nextDay';
}

String _partyDayLabel(BuildContext context, DateTime start, DateTime now) {
  final days = _partyDayOffset(start, now);
  if (days == 0) return context.l10n.t('party.today');
  if (days == 1) return context.l10n.t('party.tomorrow');
  if (days == 2) return context.l10n.t('party.overmorrow');
  return '${start.month}/${start.day}';
}

int _partyDayOffset(DateTime start, DateTime now) {
  return DateTime(
    start.year,
    start.month,
    start.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
}

String _formatClock(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
