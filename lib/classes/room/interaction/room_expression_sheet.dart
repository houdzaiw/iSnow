import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/api_error_message.dart';
import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_public_media.dart';

final roomExpressionsProvider = FutureProvider.autoDispose
    .family<List<RoomExpressionPack>, RoomInteractionKey>((ref, key) async {
      final session = ref.watch(roomInteractionProvider(key).notifier);
      if (!session.active) return const [];
      final result = await session.api.expressions();
      return session.active ? result : const [];
    });

class RoomExpressionSheet extends HookConsumerWidget {
  const RoomExpressionSheet({
    super.key,
    required this.session,
    required this.onSend,
  });
  final RoomInteractionKey session;
  final Future<bool> Function(RoomExpression expression) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenRoomInteractionLifetime(context, ref, session);
    final provider = roomExpressionsProvider(session);
    final state = ref.watch(provider);
    final pack = useState(0);
    final busy = useState(false);
    return RoomInteractionFrame(
      title: toolText(context, 'Expressions', '表情'),
      heightRatio: AppSpacing.roomInteractionExpressionSheetHeight,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userFacingErrorMessage(error),
              style: AppTextStyles.roomMessageHint,
            ),
            TextButton(
              onPressed: () => ref.invalidate(provider),
              child: Text(toolText(context, 'Retry', '重试')),
            ),
          ],
        ),
        data: (packs) {
          if (packs.isEmpty) {
            return Center(
              child: Text(
                toolText(context, 'No expressions', '暂无表情'),
                style: AppTextStyles.roomMessageHint,
              ),
            );
          }
          final current = packs[pack.value.clamp(0, packs.length - 1)];
          return Column(
            children: [
              if (busy.value) const LinearProgressIndicator(),
              Expanded(
                child: GridView.builder(
                  key: PageStorageKey(pack.value),
                  padding: EdgeInsets.all(AppSpacing.lg.r),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: AppSpacing.sm.h,
                    crossAxisSpacing: AppSpacing.sm.w,
                  ),
                  itemCount: current.items.length,
                  itemBuilder: (context, index) {
                    final item = current.items[index];
                    return Semantics(
                      button: true,
                      label: item.payload['enName']?.toString(),
                      child: InkWell(
                        onTap: busy.value
                            ? null
                            : () async {
                                if (!item.allowed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        toolText(
                                          context,
                                          'This expression requires a higher Noble rank.',
                                          '此表情需要更高的贵族等级。',
                                        ),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                busy.value = true;
                                final sent = await onSend(item);
                                if (!context.mounted) return;
                                busy.value = false;
                                if (sent &&
                                    ModalRoute.of(context)?.isCurrent == true) {
                                  Navigator.pop(context);
                                }
                              },
                        child: Opacity(
                          opacity: item.allowed
                              ? 1
                              : AppSpacing.roomInteractionLockedOpacity,
                          child: RoomPublicImage(
                            url: item.preview,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (packs.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (index, item) in packs.indexed)
                        InkWell(
                          onTap: () => pack.value = index,
                          child: ColoredBox(
                            color: index == pack.value
                                ? AppColors.roomMessageBubble
                                : AppColors.transparent,
                            child: SizedBox.square(
                              dimension: AppSpacing.controlHeightMd.r,
                              child: RoomPublicImage(
                                url: item.cover,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class RoomPublicImage extends StatelessWidget {
  const RoomPublicImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });
  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget missing() => Center(
      child: Image.asset(
        AppAssets.lanhuRoomIconMissing,
        width: AppSpacing.iconSizeMd.r,
        color: AppColors.missingAsset,
      ),
    );
    final source = roomMediaUrl(url);
    return source == null
        ? missing()
        : CachedNetworkImage(
            imageUrl: source,
            fit: fit,
            errorWidget: (_, __, ___) => missing(),
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
          );
  }
}

Future<void> showRoomPublicImage(
  BuildContext context,
  RoomInteractionKey session,
  String source,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        listenRoomInteractionLifetime(context, ref, session);
        return Dialog.fullscreen(
          backgroundColor: AppColors.roomMessageSurface,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(toolText(context, 'Close', '关闭')),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Center(
                      child: RoomPublicImage(url: source, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
