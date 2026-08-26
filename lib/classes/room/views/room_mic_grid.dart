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
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      itemCount: seats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisExtent: 91.h,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 12.h,
      ),
      itemBuilder: (context, index) {
        final seat = seats[index];
        return _RoomMicSeat(
          seat: seat,
          isMine: seat.uid != null && seat.uid == currentUid,
          isPending: pendingSeatPosition == seat.position,
          onTap: () => onSeatTap(seat),
          onLongPress: () => onSeatLongPress(seat),
        );
      },
    );
  }
}

class _RoomMicSeat extends StatelessWidget {
  const _RoomMicSeat({
    required this.seat,
    required this.isMine,
    required this.isPending,
    required this.onTap,
    required this.onLongPress,
  });

  final RoomSeatViewData seat;
  final bool isMine;
  final bool isPending;
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
          _SeatCircle(seat: seat, isMine: isMine, isPending: isPending),
          SizedBox(height: 6.h),
          Text(
            seat.position.toString(),
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
  });

  final RoomSeatViewData seat;
  final bool isMine;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46.r,
      height: 46.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (seat.isOccupied)
            _RoomAvatarImage(url: seat.avatar, size: 54.r, radius: 27.r)
          else
            _RoomAssetIcon(
              asset: seat.isLocked
                  ? AppAssets.lanhuRoomIconMissing
                  : AppAssets.lanhuRoomMicSeat,
              size: 46.r,
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
              child: _SeatStatusDot(asset: AppAssets.lanhuRoomIconMissing),
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
