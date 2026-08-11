import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/server_response.dart';
import '../../theme/app_theme.dart';

part 'model/rank_models.dart';
part 'rank_repository.dart';
part 'viewmodel/rank_state.dart';
part 'viewmodel/rank_view_model.dart';
part 'views/rank_content_view.dart';
part 'views/rank_list_view.dart';
part 'views/rank_podium_view.dart';
part 'views/rank_shared_widgets.dart';

class RankPage extends ConsumerWidget {
  const RankPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_rankViewModelProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.lanhuRankBackground,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _RankStateMessage(
                  text: context.l10n.t('rank.loadFailed'),
                  actionLabel: context.l10n.t('app.retry'),
                  onAction: () =>
                      ref.read(_rankViewModelProvider.notifier).reload(),
                ),
                data: (rankState) => _RankContentView(
                  state: rankState,
                  onBack: () => context.pop(),
                  onSelectCategory: (category) => ref
                      .read(_rankViewModelProvider.notifier)
                      .selectCategory(category),
                  onSelectPeriod: (period) => ref
                      .read(_rankViewModelProvider.notifier)
                      .selectPeriod(period),
                  onRefresh: () =>
                      ref.read(_rankViewModelProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankStateMessage extends StatelessWidget {
  const _RankStateMessage({
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: Color.fromRGBO(254, 229, 190, 1),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
