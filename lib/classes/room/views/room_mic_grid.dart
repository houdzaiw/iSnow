part of '../room_page.dart';

class _RoomMicGrid extends StatelessWidget {
  const _RoomMicGrid({
    required this.seats,
    required this.currentUid,
    required this.pendingSeatPosition,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final List<RoomSeatViewData> seats;
  final int? currentUid;
  final int? pendingSeatPosition;
  final ValueChanged<RoomSeatViewData> onSeatTap;
  final ValueChanged<RoomSeatViewData> onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = AppSpacing.roomMicGridHorizontalInset.w;
        final contentWidth = constraints.maxWidth - horizontalInset * 2;
        final child = seats.length == 12
            ? _buildTwelveSeatLayout(contentWidth)
            : _buildWrapSeatLayout(seats, contentWidth);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: AppSpacing.roomMicGridVerticalInset.h,
          ),
          child: Align(alignment: Alignment.topCenter, child: child),
        );
      },
    );
  }

  Widget _buildTwelveSeatLayout(double contentWidth) {
    final featuredGap = AppSpacing.roomMicFeaturedSeatGap.w;
    final featuredWidth = _responsiveSeatWidth(
      contentWidth: contentWidth,
      preferredWidth: AppSpacing.roomMicFeaturedSeatWidth.w,
      seatsPerRow: 2,
      spacing: featuredGap,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSeat(
              seats[0],
              width: featuredWidth,
              height: AppSpacing.roomMicFeaturedSeatHeight,
              circleSize: AppSpacing.roomMicFeaturedSeatCircleSize,
              avatarSize: AppSpacing.roomMicFeaturedSeatAvatarSize,
            ),
            SizedBox(width: featuredGap),
            _buildSeat(
              seats[1],
              width: featuredWidth,
              height: AppSpacing.roomMicFeaturedSeatHeight,
              circleSize: AppSpacing.roomMicFeaturedSeatCircleSize,
              avatarSize: AppSpacing.roomMicFeaturedSeatAvatarSize,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.roomMicFeaturedRowsGap.h),
        _buildWrapSeatLayout(seats.skip(2), contentWidth),
      ],
    );
  }

  Widget _buildWrapSeatLayout(
    Iterable<RoomSeatViewData> visibleSeats,
    double contentWidth,
  ) {
    final spacing = _seatSpacingForCount(seats.length).w;
    final width = _responsiveSeatWidth(
      contentWidth: contentWidth,
      preferredWidth: AppSpacing.roomMicSeatWidth.w,
      seatsPerRow: _seatsPerRowForCount(seats.length),
      spacing: spacing,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      children: [
        for (final seat in visibleSeats) _buildSeat(seat, width: width),
      ],
    );
  }

  Widget _buildSeat(
    RoomSeatViewData seat, {
    required double width,
    double height = AppSpacing.roomMicSeatHeight,
    double circleSize = AppSpacing.roomMicSeatCircleSize,
    double avatarSize = AppSpacing.roomMicSeatAvatarSize,
  }) {
    return SizedBox(
      width: width,
      height: height.h,
      child: _RoomMicSeat(
        seat: seat,
        isMine: seat.uid != null && seat.uid == currentUid,
        isPending: pendingSeatPosition == seat.position,
        circleSize: circleSize,
        avatarSize: avatarSize,
        onTap: () => onSeatTap(seat),
        onLongPress: () => onSeatLongPress(seat),
      ),
    );
  }

  double _seatSpacingForCount(int count) {
    return count == 8
        ? AppSpacing.roomMicSeatSpacingWide
        : AppSpacing.roomMicSeatSpacing;
  }

  int _seatsPerRowForCount(int count) {
    if (count <= 0) return roomDefaultMicSeatCount;
    if (count <= roomDefaultMicSeatCount) return count;
    if (count == 8) return 4;
    return 5;
  }

  double _responsiveSeatWidth({
    required double contentWidth,
    required double preferredWidth,
    required int seatsPerRow,
    required double spacing,
  }) {
    if (seatsPerRow <= 1) return preferredWidth;
    final availableWidth =
        (contentWidth - spacing * (seatsPerRow - 1)) / seatsPerRow;
    if (availableWidth <= 0) return preferredWidth;
    return availableWidth < preferredWidth ? availableWidth : preferredWidth;
  }
}

class _RoomMicSeat extends StatelessWidget {
  const _RoomMicSeat({
    required this.seat,
    required this.isMine,
    required this.isPending,
    required this.circleSize,
    required this.avatarSize,
    required this.onTap,
    required this.onLongPress,
  });

  final RoomSeatViewData seat;
  final bool isMine;
  final bool isPending;
  final double circleSize;
  final double avatarSize;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          _SeatCircle(
            seat: seat,
            isMine: isMine,
            isPending: isPending,
            circleSize: circleSize,
            avatarSize: avatarSize,
          ),
          SizedBox(height: 6.h),
          Text(
            seat.displayPosition.toString(),
            maxLines: 1,
            style: TextStyle(
              color: isMine
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.48),
              fontSize: 12.sp,
              height: 1,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 3.h),
          _SeatHeat(value: seat.heat),
        ],
      ),
    );
  }
}

class _SeatCircle extends StatelessWidget {
  const _SeatCircle({
    required this.seat,
    required this.isMine,
    required this.isPending,
    required this.circleSize,
    required this.avatarSize,
  });

  final RoomSeatViewData seat;
  final bool isMine;
  final bool isPending;
  final double circleSize;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: circleSize.r,
      height: circleSize.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (seat.isOccupied)
            _RoomAvatarImage(
              url: seat.avatar,
              size: avatarSize.r,
              radius: avatarSize.r / 2,
            )
          else
            _RoomAssetIcon(
              asset: seat.isLocked
                  ? AppAssets.lanhuRoomMicLockSeat
                  : AppAssets.lanhuRoomMicSeat,
              size: circleSize.r,
            ),
          if (seat.isMuted)
            Positioned(
              right: 2.r,
              bottom: 2.r,
              child: _SeatStatusDot(asset: AppAssets.lanhuRoomIconMissing),
            ),
          if (seat.isLocked && seat.isOccupied)
            Positioned(
              left: 2.r,
              bottom: 2.r,
              child: _SeatStatusDot(asset: AppAssets.lanhuRoomMicLockSeat),
            ),
          if (isPending)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
                child: Padding(
                  padding: EdgeInsets.all(18.r),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _roomGold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeatStatusDot extends StatelessWidget {
  const _SeatStatusDot({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.r,
      height: 20.r,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: _RoomAssetIcon(asset: asset, size: 12.r),
      ),
    );
  }
}

class _SeatHeat extends StatelessWidget {
  const _SeatHeat({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoomAssetIcon(asset: AppAssets.lanhuRoomHeat, size: 12.r),
        SizedBox(width: 2.w),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 42.w),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value.toString(),
              maxLines: 1,
              style: TextStyle(
                color: AppColors.roomHeatText,
                fontSize: 10.sp,
                height: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
