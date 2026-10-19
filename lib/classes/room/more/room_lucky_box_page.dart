import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_tools_controller.dart';
import 'room_tools_models.dart';
import 'room_tools_widgets.dart';

class RoomLuckyBoxPage extends HookConsumerWidget {
  const RoomLuckyBoxPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
    final type = useState(0);
    final gold = useState<int?>(null);
    final recipients = useState<int?>(null);
    final countdown = useState<int?>(null);
    final preparing = useState(false);
    useEffect(() {
      Future.microtask(() {
        vm.refreshBags();
        vm.refreshBalance();
      });
      return null;
    }, [roomId]);
    final config = toolMap(
      state.luckyConfig[type.value == 0 ? 'room' : 'world'],
    );
    final amounts = toolList(config['configuration']);
    final goldValues = amounts
        .map((item) => toolInt(item['goldQuantiry']))
        .where((amount) => amount > 0)
        .toList();
    final selectedGold = goldValues.contains(gold.value)
        ? gold.value
        : goldValues.firstOrNull;
    final amount = amounts
        .where((item) => toolInt(item['goldQuantiry']) == selectedGold)
        .firstOrNull;
    final people = (amount?['numberOfRecipients'] as List? ?? const [])
        .map(toolInt)
        .where((value) => value > 0)
        .toList();
    final seconds = (config['countdown'] as List? ?? const [])
        .map(toolInt)
        .where((value) => value >= 0)
        .toList();
    final selectedPeople = people.contains(recipients.value)
        ? recipients.value
        : people.firstOrNull;
    final selectedSeconds = seconds.contains(countdown.value)
        ? countdown.value
        : seconds.firstOrNull;
    final busy = state.busy.contains('luckySend') || preparing.value;
    final rules =
        '${state.luckyConfig[Localizations.localeOf(context).languageCode == 'ar' ? 'rulesUrlAr' : 'rulesUrlEn'] ?? ''}';
    return RoomToolPage(
      roomId: roomId,
      title: toolText(context, 'Lucky Box', '幸运盒'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${toolText(context, 'Balance', '余额')}: ${state.balance}',
                ),
              ),
              TextButton(
                onPressed: () async {
                  await context.push('/wallet');
                  if (vm.mounted) await vm.refreshBalance();
                },
                child: Text(toolText(context, 'Recharge', '充值')),
              ),
              if (Uri.tryParse(rules)?.hasScheme == true)
                TextButton(
                  onPressed: () => context.push(
                    Uri(
                      path: '/web-view',
                      queryParameters: {'title': 'Lucky Box', 'uri': rules},
                    ).toString(),
                  ),
                  child: Text(toolText(context, 'Rules', '规则')),
                ),
            ],
          ),
          if (vm.canSendLucky) ...[
            ToolChoices<int>(
              values: const [0, 1],
              selected: type.value,
              label: (value) => value == 0
                  ? toolText(context, 'Room', '房间')
                  : toolText(context, 'World', '全服'),
              onSelected: busy
                  ? null
                  : (value) {
                      type.value = value;
                      gold.value = null;
                      recipients.value = null;
                      countdown.value = null;
                    },
            ),
            ToolHeading(toolText(context, 'Coins', '金币')),
            ToolChoices<int>(
              values: goldValues,
              selected: selectedGold,
              label: (value) => '$value',
              onSelected: busy
                  ? null
                  : (value) {
                      gold.value = value;
                      recipients.value = null;
                    },
            ),
            ToolHeading(toolText(context, 'Recipients', '领取人数')),
            ToolChoices<int>(
              values: people,
              selected: selectedPeople,
              label: (value) => '$value',
              onSelected: busy ? null : (value) => recipients.value = value,
            ),
            ToolHeading(toolText(context, 'Countdown (seconds)', '倒计时（秒）')),
            ToolChoices<int>(
              values: seconds,
              selected: selectedSeconds,
              label: (value) => '$value',
              onSelected: busy ? null : (value) => countdown.value = value,
            ),
            TextButton(
              onPressed:
                  busy ||
                      selectedGold == null ||
                      selectedPeople == null ||
                      selectedSeconds == null
                  ? null
                  : () async {
                      if (preparing.value) return;
                      preparing.value = true;
                      try {
                        await vm.refreshBalance();
                        if (!context.mounted || !vm.active) return;
                        if (vm.snapshot.balance < selectedGold) {
                          if (await confirmRoomTool(
                                context,
                                toolText(context, 'Not enough coins', '金币不足'),
                                toolText(context, 'Open wallet?', '前往充值？'),
                              ) &&
                              context.mounted) {
                            await context.push('/wallet');
                            if (vm.mounted) await vm.refreshBalance();
                          }
                          return;
                        }
                        var confirmed = false;
                        if (await vm.needsLuckyConfirmation()) {
                          if (!context.mounted) return;
                          confirmed = await confirmRoomTool(
                            context,
                            toolText(context, 'Send Lucky Box', '发送幸运盒'),
                            toolText(
                              context,
                              'Coins will be charged when the box is sent. Continue?',
                              '发送后将扣除金币，确认继续？',
                            ),
                          );
                          if (!confirmed) return;
                        }
                        await vm.sendLucky(
                          type: type.value,
                          gold: selectedGold,
                          recipients: selectedPeople,
                          countdown: selectedSeconds,
                          confirmed: confirmed,
                        );
                      } finally {
                        if (context.mounted) preparing.value = false;
                      }
                    },
              child: busy
                  ? const CircularProgressIndicator()
                  : Text(toolText(context, 'Send', '发送')),
            ),
            if (goldValues.isEmpty)
              Text(
                toolText(
                  context,
                  'No available Lucky Box configuration',
                  '暂无可用的幸运盒配置',
                ),
              ),
          ],
          ToolHeading(toolText(context, 'Available boxes', '可领取的幸运盒')),
          if (state.bags.isEmpty)
            Text(toolText(context, 'No Lucky Boxes', '暂无幸运盒')),
          for (final bag in state.bags)
            ListTile(
              leading: ToolImage('${bag.raw['avatar'] ?? ''}'),
              title: Text('${bag.raw['nickName'] ?? bag.raw['uid'] ?? ''}'),
              subtitle: Text('${bag.remaining(DateTime.now())}s'),
              trailing: TextButton(
                onPressed:
                    bag.remaining(DateTime.now()) > 0 ||
                        state.busy.contains('grab:${bag.id}')
                    ? null
                    : () => openLuckyBox(context, ref, roomId, bag.id),
                child: Text(toolText(context, 'Open', '领取')),
              ),
            ),
          TextButton(
            onPressed: vm.refreshBags,
            child: Text(toolText(context, 'Refresh', '刷新')),
          ),
        ],
      ),
    );
  }
}

Future<void> openLuckyBox(
  BuildContext context,
  WidgetRef ref,
  String roomId,
  String id,
) async {
  final vm = ref.read(roomToolsControllerProvider(roomId).notifier);
  final result = await vm.grabLucky(id);
  if (result == null && vm.active) vm.deferBag(id);
  if (!context.mounted || result == null || !vm.active || !vm.visible) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _LuckyResult(roomId: roomId, result: result),
  );
}

class _LuckyResult extends ConsumerStatefulWidget {
  const _LuckyResult({required this.roomId, required this.result});
  final String roomId;
  final ToolJson result;
  @override
  ConsumerState<_LuckyResult> createState() => _LuckyResultState();
}

class _LuckyResultState extends ConsumerState<_LuckyResult> {
  Timer? reveal, close;
  bool showing = false;
  @override
  void initState() {
    super.initState();
    reveal = Timer(const Duration(milliseconds: 1750), () {
      if (!mounted) return;
      setState(() => showing = true);
      close = Timer(const Duration(milliseconds: 3000), _dismiss);
    });
  }

  void _dismiss() {
    final route = ModalRoute.of(context);
    if (!mounted || route?.isActive != true) return;
    if (route!.isCurrent) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  void dispose() {
    reveal?.cancel();
    close?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roomToolsControllerProvider(widget.roomId), (_, next) {
      if (!next.sessionActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _dismiss();
        });
      }
    });
    return AlertDialog(
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: showing
            ? Column(
                key: const ValueKey('result'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToolImage('${widget.result['icon'] ?? ''}'),
                  Text(
                    toolInt(widget.result['count']) > 0
                        ? '+${widget.result['count']}'
                        : toolText(context, 'Better luck next time', '下次好运'),
                    style: AppTextStyles.navTitle,
                  ),
                ],
              )
            : Image.asset(
                AppAssets.lanhuRoomMoreLuckyBox,
                key: const ValueKey('opening'),
                width: AppSpacing.roomExitChoiceSize,
              ),
      ),
      actions: [
        TextButton(
          onPressed: _dismiss,
          child: Text(toolText(context, 'Close', '关闭')),
        ),
      ],
    );
  }
}
