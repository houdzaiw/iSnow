import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_interaction_view_model.dart';

Future<T?> showRoomInteractionSheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  Color backgroundColor = AppColors.roomMessageSurface,
}) async {
  ModalRoute<T>? route;
  final result = await showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: backgroundColor,
    barrierColor: AppColors.modalScrimStrong,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
    builder: (context) {
      final current = ModalRoute.of(context);
      if (current is ModalRoute<T>) route = current;
      return builder(context);
    },
  );
  await route?.completed;
  return result;
}

void listenRoomInteractionLifetime(
  BuildContext context,
  WidgetRef ref,
  RoomInteractionKey key, {
  VoidCallback? onClose,
}) {
  final route = ModalRoute.of(context);
  void scheduleClose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && route?.isActive == true) {
        Navigator.of(context).removeRoute(route!);
      }
    });
  }

  final provider = roomInteractionProvider(key);
  if (!ref.watch(provider)) scheduleClose();
  ref.listen(provider, (_, active) {
    if (!active) {
      onClose?.call();
      scheduleClose();
    }
  });
}

class RoomInteractionFrame extends StatelessWidget {
  const RoomInteractionFrame({
    super.key,
    required this.child,
    this.title,
    this.heightRatio = AppSpacing.roomMessageHeightRatio,
  });

  final Widget child;
  final String? title;
  final double heightRatio;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * heightRatio,
      child: Column(
        children: [
          SizedBox(
            height: AppSpacing.roomMessageHandleArea.h,
            child: Center(
              child: Container(
                width: AppSpacing.roomMessageHandleWidth.w,
                height: AppSpacing.roomMessageHandleHeight.h,
                decoration: const BoxDecoration(
                  color: AppColors.roomMessageHandle,
                  borderRadius: AppRadius.cardBorder,
                ),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm.r),
              child: Text(title!, style: AppTextStyles.roomMessageTitle),
            ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
