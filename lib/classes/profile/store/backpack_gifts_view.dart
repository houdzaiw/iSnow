import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../tools/profile_tools_widgets.dart';
import 'backpack_gift.dart';
import 'store_preview.dart';

class BackpackGiftsView extends ConsumerWidget {
  const BackpackGiftsView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refresh() => ref.refresh(backpackGiftsProvider.future);
    return ref
        .watch(backpackGiftsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ProfileToolsError(error: error, retry: refresh),
          data: (items) => RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              key: const PageStorageKey('personal-gifts'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: ProfileToolsTheme.padding,
              children: [
                if (items.isEmpty)
                  Center(child: Text(context.l10n.t('tools.empty'))),
                for (final item in items)
                  ListTile(
                    leading: MembershipImage(
                      item.icon,
                      size: ProfileToolsTheme.badge,
                    ),
                    title: Text(item.name, style: ProfileToolsTheme.label),
                    subtitle: item.expiresAt == null
                        ? null
                        : Text(
                            context.l10n.t('tools.expires', {
                              'time': DateFormat.yMd().add_Hm().format(
                                item.expiresAt!,
                              ),
                            }),
                          ),
                    trailing: Text(
                      '×${item.amount}',
                      style: ProfileToolsTheme.label,
                    ),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      useRootNavigator: true,
                      builder: (c) => SafeArea(
                        child: Padding(
                          padding: ProfileToolsTheme.padding,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.name, style: ProfileToolsTheme.title),
                              SizedBox(
                                height: ProfileToolsTheme.preview,
                                child: StorePreview(product: item.preview),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: Text(c.l10n.t('tools.close')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
  }
}
