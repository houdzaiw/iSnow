import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/system_message_card_data.dart';
import '../../../theme/app_theme.dart';
import 'system_message_image.dart';

class SystemMessageCard extends StatelessWidget {
  const SystemMessageCard({
    super.key,
    required this.data,
    this.onImage,
    this.onDetails,
  });
  final SystemMessageCardData data;
  final VoidCallback? onImage, onDetails;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey('system-message-${data.id}'),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.time != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.systemMessageTimeTop,
              bottom: AppSpacing.systemMessageTimeBottom,
            ),
            child: Text(
              DateFormat('yyyy.MM.dd HH:mm:ss').format(data.time!),
              textAlign: TextAlign.center,
              style: AppTextStyles.systemMessageTime,
            ),
          )
        else
          const SizedBox(height: AppSpacing.xl),
        Material(
          color: AppColors.systemMessageCard,
          borderRadius: AppRadius.systemMessageCardBorder,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onDetails,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.picture != null)
                    GestureDetector(
                      key: ValueKey('system-message-image-${data.id}'),
                      onTap: onImage,
                      child: ClipRRect(
                        borderRadius: AppRadius.systemMessageImageBorder,
                        child: AspectRatio(
                          aspectRatio: AppSpacing.systemMessageImageRatio,
                          child: SystemMessageImage(uri: data.picture!),
                        ),
                      ),
                    ),
                  if (data.title.isNotEmpty)
                    Text(data.title, style: AppTextStyles.systemMessageTitle),
                  if (data.text.isNotEmpty)
                    Padding(
                      padding: data.title.isNotEmpty
                          ? const EdgeInsets.symmetric(vertical: AppSpacing.lg)
                          : EdgeInsets.zero,
                      child: Text(
                        data.text,
                        style: AppTextStyles.systemMessageBody,
                      ),
                    ),
                  if (!data.supported)
                    Text(
                      context.l10n.t('message.system.unsupported'),
                      style: AppTextStyles.systemMessageBody,
                    ),
                  if (onDetails != null) ...[
                    const Divider(
                      color: AppColors.systemMessageCard,
                      thickness: AppSpacing.hairline,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.t('message.system.details'),
                            style: AppTextStyles.systemMessageDetails,
                          ),
                        ),
                        Image.asset(
                          AppAssets.lanhuCreatePartyChevronRight,
                          width: AppSpacing.iconSizeSm,
                          height: AppSpacing.iconSizeSm,
                          color: AppColors.systemMessageBody,
                          matchTextDirection: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
