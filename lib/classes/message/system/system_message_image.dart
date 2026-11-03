import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_network_image.dart';

/// Failed cached-network-image loads evict their image-cache entry; a new
/// widget key retries without modifying the server URL or adding auth headers.
final systemMessageImageCacheProvider = Provider<BaseCacheManager>(
  (ref) => DefaultCacheManager(),
);

class SystemMessageImage extends HookConsumerWidget {
  const SystemMessageImage({
    super.key,
    required this.uri,
    this.fit = BoxFit.cover,
  });
  final Uri uri;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempt = useState(0);
    return AppNetworkImage(
      key: ValueKey((uri.toString(), attempt.value)),
      url: uri.toString(),
      cacheManager: ref.watch(systemMessageImageCacheProvider),
      fit: fit,
      placeholder: const Center(
        child: CircularProgressIndicator(color: AppColors.textInverse),
      ),
      errorWidget: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.lanhuRoomIconMissing,
              width: AppSpacing.iconSizeMd,
              height: AppSpacing.iconSizeMd,
            ),
            TextButton(
              key: const ValueKey('system-message-image-retry'),
              onPressed: () => attempt.value++,
              child: Text(
                context.l10n.t('app.retry'),
                style: AppTextStyles.systemMessageBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SystemMessageImagePreview extends StatelessWidget {
  const SystemMessageImagePreview({super.key, required this.uri});
  final Uri uri;
  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('system-message-image-preview'),
    backgroundColor: AppColors.systemImageBackground,
    appBar: AppBar(
      backgroundColor: AppColors.systemImageBackground,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: context.l10n.t('app.back'),
        onPressed: () => Navigator.of(context).pop(),
        icon: Image.asset(
          AppAssets.backWhiteButton,
          width: AppSpacing.iconSizeMd,
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: InteractiveViewer(
          maxScale: AppSpacing.systemImageMaxScale,
          child: SizedBox.expand(
            child: SystemMessageImage(uri: uri, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}
