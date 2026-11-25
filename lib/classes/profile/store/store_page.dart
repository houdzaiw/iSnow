import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../localization/app_localizations.dart';
import '../../../model/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../party/friends_activity/home_activity_navigation.dart';
import '../tools/profile_tools_widgets.dart';
import 'store_models.dart';
import 'store_preview.dart';
import 'store_recipient_sheet.dart';
import 'store_view_model.dart';

class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});
  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: StoreCategory.values.length, vsync: this);
    tabs.addListener(() {
      if (mounted) {
        ref
            .read(storeViewModelProvider.notifier)
            .selectCategory(StoreCategory.values[tabs.index]);
      }
    });
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _buy({bool gift = false}) async {
    if (_opening) return;
    _opening = true;
    final model = ref.read(storeViewModelProvider.notifier);
    try {
      UserData? recipient;
      if (gift) {
        recipient = await showModalBottomSheet<UserData>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          builder: (_) => const StoreRecipientSheet(),
        );
        if (!mounted || recipient == null) return;
      }
      final order = await model.order(recipient: recipient);
      if (!mounted || order == null) return;
      final confirmed = await profileToolsConfirm(
        context,
        context.l10n.t('tools.confirmPurchase', {
          'name': order.product.name,
          'target': recipient?.nick ?? context.l10n.t('tools.self'),
          'days': '${order.price.days}',
          'price': '${order.price.price}',
          'currency': context.l10n.t(
            order.price.currency == 1 ? 'tools.coins' : 'tools.diamonds',
          ),
        }),
      );
      if (!mounted || !confirmed) return;
      final result = await model.submit(order);
      if (mounted && result != null) {
        profileToolsNotice(
          context,
          null,
          key: result ? 'tools.success' : 'tools.refreshFailed',
        );
      }
    } on StoreInsufficientBalance {
      if (mounted &&
          await profileToolsConfirm(
            context,
            context.l10n.t('tools.insufficient'),
          ) &&
          mounted) {
        await context.push('/wallet');
        if (mounted) await model.refreshBalance();
      }
    } catch (e) {
      if (mounted) profileToolsNotice(context, e);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    listenHomeSessionRoute(context, ref);
    final state = ref.watch(storeViewModelProvider);
    final model = ref.read(storeViewModelProvider.notifier);
    final selected = state.board.selected;
    return ProfileToolsScaffold(
      title: context.l10n.t('tools.store'),
      actions: [
        TextButton(
          onPressed: () async {
            await context.push('/store/backpack');
            if (mounted) {
              await model.refreshBalance();
              await model.refreshNew();
            }
          },
          child: Text(context.l10n.t('tools.backpack')),
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.purse case final balance?)
            Text(
              context.l10n.t('tools.balance', {
                'coins': '${balance.coin}',
                'diamonds': '${balance.diamond}',
              }),
              style: ProfileToolsTheme.caption,
            ),
          if (state.balanceError != null)
            ProfileToolsError(
              error: state.balanceError,
              retry: model.refreshBalance,
            ),
          if (selected != null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < selected.prices.length; i++)
                    ChoiceChip(
                      label: Text(
                        '${context.l10n.t('tools.days', {'days': '${selected.prices[i].days}'})} · ${selected.prices[i].price} ${context.l10n.t(selected.prices[i].currency == 1 ? 'tools.coins' : 'tools.diamonds')}',
                      ),
                      selected: state.board.priceIndex == i,
                      onSelected: state.busy
                          ? null
                          : (_) => model.selectPrice(i),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.busy || selected.prices.isEmpty
                        ? null
                        : () => _buy(gift: true),
                    child: Text(context.l10n.t('tools.send')),
                  ),
                ),
                ProfileToolsTheme.space,
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.busy || selected.prices.isEmpty
                        ? null
                        : _buy,
                    child: state.busy
                        ? const CircularProgressIndicator()
                        : Text(context.l10n.t('tools.buy')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      child: Column(
        children: [
          ExtendedTabBar(
            labelColor: ProfileToolsTheme.tabActive,
            unselectedLabelColor: ProfileToolsTheme.tabInactive,
            indicatorColor: ProfileToolsTheme.tabIndicator,
            controller: tabs,
            isScrollable: true,
            tabs: [
              for (final c in StoreCategory.values)
                Tab(
                  text:
                      '${context.l10n.t('tools.${c.label}')}${state.newTypes.contains(c.type) ? ' · ${context.l10n.t('tools.new')}' : ''}',
                ),
            ],
          ),
          Expanded(
            child: ExtendedTabBarView(
              controller: tabs,
              children: [
                for (final c in StoreCategory.values) StoreCatalog(category: c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StoreCatalog extends ConsumerWidget {
  const StoreCatalog({super.key, required this.category});
  final StoreCategory category;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeViewModelProvider);
    final board = state.boards[category] ?? const StoreBoard(loading: true);
    final model = ref.read(storeViewModelProvider.notifier);
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical &&
            n.metrics.extentAfter < ProfileToolsTheme.preview &&
            !board.loading &&
            board.error == null &&
            board.more) {
          model.load(category, more: true);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => model.load(category),
        child: ListView(
          key: PageStorageKey('store-${category.name}'),
          padding: ProfileToolsTheme.padding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (board.selected case final product?)
              SizedBox(
                height: ProfileToolsTheme.preview,
                child: StorePreview(
                  key: ValueKey(product.id),
                  product: product,
                ),
              ),
            if (board.error != null)
              ProfileToolsError(
                error: board.error,
                retry: () => model.load(category, more: board.failedMore),
              ),
            if (board.items.isEmpty && !board.loading && board.error == null)
              Center(child: Text(context.l10n.t('tools.empty'))),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ProfileToolsTheme.gridColumns,
                mainAxisExtent: ProfileToolsTheme.itemExtent,
                crossAxisSpacing: ProfileToolsTheme.gridSpacing,
                mainAxisSpacing: ProfileToolsTheme.gridSpacing,
              ),
              itemCount: board.items.length,
              itemBuilder: (context, index) {
                final p = board.items[index];
                return InkWell(
                  onTap: () => model.selectProduct(p.id),
                  child: Container(
                    padding: ProfileToolsTheme.smallPadding,
                    decoration: BoxDecoration(
                      color: ProfileToolsTheme.white,
                      borderRadius: ProfileToolsTheme.radius,
                      border: Border.fromBorderSide(
                        board.selectedId == p.id
                            ? ProfileToolsTheme.selectedBorder
                            : ProfileToolsTheme.normalBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: MembershipImage(
                            p.icon,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ProfileToolsTheme.label,
                        ),
                        if (p.isNew)
                          Text(
                            context.l10n.t('tools.new'),
                            style: ProfileToolsTheme.caption,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (board.loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
