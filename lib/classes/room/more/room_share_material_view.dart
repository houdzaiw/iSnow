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
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: const ValueKey('room-share-posters'),
            controller: controller,
            physics: enabled ? null : const NeverScrollableScrollPhysics(),
            onPageChanged: onChanged,
            itemCount: materials.length,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Semantics(
                label: toolText(context, 'Share poster', '分享海报'),
                image: true,
                child: materials[index].imageUrl.isEmpty
                    ? Image.asset(
                        AppAssets.lanhuRoomIconMissing,
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        materials[index].imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          AppAssets.lanhuRoomIconMissing,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (materials.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              '${index + 1} / ${materials.length}',
              style: AppTextStyles.roomAudienceName,
            ),
          ),
      ],
    );
  }
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

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrongSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    content?.link.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (busy) const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.sm,
          children: [
            _action(
              context,
              RoomShareAction.copy,
              AppAssets.lanhuProfileHomepageCopy,
              toolText(context, 'Copy', '复制'),
            ),
            _action(
              context,
              RoomShareAction.system,
              AppAssets.lanhuRoomMoreShare,
              toolText(context, 'System share', '系统分享'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _action(
    BuildContext context,
    RoomShareAction action,
    String asset,
    String label,
  ) => Builder(
    builder: (buttonContext) => TextButton.icon(
      key: ValueKey('room-share-${action.name}'),
      onPressed: enabled ? () => onShare(action, buttonContext) : null,
      icon: Image.asset(
        asset,
        width: AppSpacing.iconSizeMd,
        height: AppSpacing.iconSizeMd,
      ),
      label: Text(label, style: AppTextStyles.bodyStrongSmall),
    ),
  );
}
