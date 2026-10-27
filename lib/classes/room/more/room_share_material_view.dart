import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../model/room_share_models.dart';
import '../../../theme/app_theme.dart';
import 'room_tools_widgets.dart';

class RoomSharePoster extends HookWidget {
  const RoomSharePoster({
    super.key,
    required this.materials,
    required this.onChanged,
    required this.enabled,
    required this.index,
  });
  final List<RoomShareMaterial> materials;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final int index;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController(initialPage: index);
    useEffect(() {
      if (controller.hasClients && controller.page?.round() != index) {
        controller.jumpToPage(index);
      }
      return null;
    }, [index]);
    void step(int delta) {
      if (!enabled) return;
      final next = (index + delta + materials.length) % materials.length;
      controller.jumpToPage(next);
      onChanged(next);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.roomSharePosterGap,
      ),
      child: Row(
        children: [
          if (materials.length > 1)
            _PosterArrow(
              enabled: enabled,
              previous: true,
              onTap: () => step(-1),
            ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: PageView.builder(
              key: const ValueKey('room-share-posters'),
              controller: controller,
              physics: enabled ? null : const NeverScrollableScrollPhysics(),
              onPageChanged: onChanged,
              itemCount: materials.length,
              itemBuilder: (_, item) => Semantics(
                label: toolText(context, 'Share poster', '分享海报'),
                image: true,
                child: materials[item].imageUrl.isEmpty
                    ? Image.asset(
                        AppAssets.lanhuRoomIconMissing,
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        materials[item].imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          AppAssets.lanhuRoomIconMissing,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          if (materials.length > 1)
            _PosterArrow(
              enabled: enabled,
              previous: false,
              onTap: () => step(1),
            ),
        ],
      ),
    );
  }
}

class _PosterArrow extends StatelessWidget {
  const _PosterArrow({
    required this.enabled,
    required this.previous,
    required this.onTap,
  });
  final bool enabled, previous;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: previous
        ? toolText(context, 'Previous poster', '上一张海报')
        : toolText(context, 'Next poster', '下一张海报'),
    child: SizedBox.square(
      dimension: AppSpacing.roomSharePosterButtonSize,
      child: Material(
        color: AppColors.roomSharePosterControl,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('room-share-poster-${previous ? 'previous' : 'next'}'),
          onTap: enabled ? onTap : null,
          child: Center(
            child: RotatedBox(
              quarterTurns: previous ? 2 : 0,
              child: Image.asset(
                AppAssets.lanhuCreatePartyChevronRight,
                width: AppSpacing.roomSharePosterArrowSize,
                height: AppSpacing.roomSharePosterArrowSize,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class RoomShareActions extends StatelessWidget {
  const RoomShareActions({
    super.key,
    required this.material,
    required this.content,
    required this.enabled,
    required this.busy,
    required this.onShare,
  });
  final RoomShareMaterial material;
  final RoomShareContent? content;
  final bool enabled, busy;
  final void Function(RoomShareAction, BuildContext) onShare;

  static const _channels = [
    (RoomShareAction.whatsapp, AppAssets.roomShareWhatsapp),
    (RoomShareAction.facebook, AppAssets.roomShareFacebook),
    (RoomShareAction.snapchat, AppAssets.roomShareSnapchat),
    (RoomShareAction.telegram, AppAssets.roomShareTelegram),
    (RoomShareAction.messenger, AppAssets.roomShareMessenger),
    (RoomShareAction.x, AppAssets.roomShareX),
    (RoomShareAction.instagram, AppAssets.roomShareInstagram),
    (RoomShareAction.contacts, AppAssets.roomShareContacts),
    (RoomShareAction.system, AppAssets.roomShareOthers),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('room-share-actions'),
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      children: [
        SizedBox(
          height: AppSpacing.xs,
          child: busy ? const LinearProgressIndicator() : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.roomShareSummaryInset,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.fieldBorder,
                child: ToolImage(
                  material.imageUrl,
                  size: AppSpacing.roomSharePreviewSize,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content?.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrongSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Image.asset(
                          AppAssets.roomShareLink,
                          width: AppSpacing.iconSizeSm,
                          height: AppSpacing.iconSizeSm,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            content?.link.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.roomShareLink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Builder(
                builder: (buttonContext) => Tooltip(
                  message: toolText(context, 'Copy', '复制'),
                  child: InkWell(
                    key: const ValueKey('room-share-copy'),
                    onTap: enabled
                        ? () => onShare(RoomShareAction.copy, buttonContext)
                        : null,
                    child: Image.asset(
                      AppAssets.roomShareCopy,
                      width: AppSpacing.roomShareCopyWidth,
                      height: AppSpacing.roomShareCopyHeight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.roomShareChannelsTopGap),
        GridView.builder(
          key: const ValueKey('room-share-channels'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.roomShareGridInset,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppSpacing.roomShareChannelColumns,
            mainAxisExtent: AppSpacing.roomShareChannelHeight,
            mainAxisSpacing: AppSpacing.roomShareChannelGap,
            crossAxisSpacing: AppSpacing.xxs,
          ),
          itemCount: _channels.length,
          itemBuilder: (context, index) {
            final (action, asset) = _channels[index];
            return Builder(
              builder: (buttonContext) => Semantics(
                button: true,
                enabled: enabled,
                label: action.channelName,
                child: InkWell(
                  key: ValueKey('room-share-${action.name}'),
                  onTap: enabled ? () => onShare(action, buttonContext) : null,
                  child: Column(
                    children: [
                      Image.asset(
                        asset,
                        width: AppSpacing.roomShareChannelIconSize,
                        height: AppSpacing.roomShareChannelIconSize,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        action.channelName,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.roomShareChannel,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
