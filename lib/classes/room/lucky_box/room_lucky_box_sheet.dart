import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../activities/room_activity_widgets.dart';
import '../more/room_tools_widgets.dart';
import 'room_lucky_box_rules_sheet.dart';
import 'room_lucky_box_view_model.dart';

Future<void> showRoomLuckyBoxSheet(BuildContext context, String id) =>
    showRoomActivitySheet(context, id, RoomLuckyBoxPage(roomId: id));
Future<void> showRoomLuckyBoxList(BuildContext context, String id) =>
    showRoomActivitySheet(context, id, RoomLuckyBoxList(roomId: id));

class RoomLuckyBoxPage extends HookConsumerWidget {
  const RoomLuckyBoxPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomLuckyBoxProvider(roomId));
    final vm = ref.read(roomLuckyBoxProvider(roomId).notifier);
    final preparing = useState(false);
    useEffect(() {
      Future.microtask(vm.load);
      return null;
    }, [vm]);
    final language = Localizations.localeOf(context).languageCode;
    final rules = state.config?.rules(language) ?? '';
    final busy = state.sending || state.loading || preparing.value;
    Future<void> send() async {
      if (preparing.value || !state.canSubmit) return;
      preparing.value = true;
      try {
        var confirmed = false;
        final needsConfirmation = await vm.needsConfirmation();
        if (needsConfirmation == null) return;
        if (needsConfirmation) {
          if (!context.mounted || !vm.valid) return;
          confirmed = await confirmRoomTool(
            context,
            toolText(context, 'Send Lucky Box', '发送幸运盒'),
            toolText(
              context,
              'Sending this box costs ${state.gold} coins. Continue?',
              '发送此宝箱将扣除 ${state.gold} 金币，继续？',
            ),
          );
          if (!confirmed) return;
        }
        if (!context.mounted || !vm.valid) return;
        final success = await vm.send(confirmed: confirmed);
        if (!context.mounted || !vm.valid) return;
        if (success) {
          Navigator.of(context).pop();
        } else if (ref.read(roomLuckyBoxProvider(roomId)).error ==
            'Not enough coins') {
          if (await confirmRoomTool(
                context,
                toolText(context, 'Not enough coins', '金币不足'),
                toolText(context, 'Open wallet?', '前往充值？'),
              ) &&
              context.mounted) {
            await context.push('/wallet');
            if (vm.valid) await vm.load();
          }
        }
      } finally {
        if (context.mounted) preparing.value = false;
      }
    }

    final mode = state.mode;
    final people =
        mode?.amounts.where((a) => a.gold == state.gold).firstOrNull?.people ??
        [];
    return RoomActivityPanel(
      title: toolText(context, 'Lucky Box', '幸运盒'),
      light: true,
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: RoomActivityTheme.luckyText,
            displayColor: RoomActivityTheme.luckyText,
          ),
        ),
        child: Column(
          children: [
            if (state.loading) const LinearProgressIndicator(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${toolText(context, 'Balance', '余额')}: ${state.balance}',
                    style: RoomActivityTheme.darkBody,
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          await context.push('/wallet');
                          if (vm.valid) await vm.load();
                        },
                  child: Text(toolText(context, 'Recharge', '充值')),
                ),
                if (rules.isNotEmpty)
                  TextButton(
                    onPressed: () => state.config!.rulesAreImage(language)
                        ? showRoomLuckyBoxImageRules(context, roomId, rules)
                        : context.push(
                            Uri(
                              path: '/web-view',
                              queryParameters: {
                                'title': 'Lucky Box',
                                'uri': rules,
                              },
                            ).toString(),
                          ),
                    child: Text(toolText(context, 'Rules', '规则')),
                  ),
              ],
            ),
            if (state.error != null)
              RoomActivityError(
                state.error!,
                light: true,
                retry: busy ? null : vm.load,
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (!state.canSend && !state.loading)
                      Text(
                        toolText(
                          context,
                          'Lucky Box is unavailable',
                          '当前无法发送幸运盒',
                        ),
                        style: RoomActivityTheme.darkBody,
                      ),
                    ToolChoices<int>(
                      values: const [0, 1],
                      selected: state.type,
                      label: (n) => n == 0
                          ? toolText(context, 'Room', '房间')
                          : toolText(context, 'World', '世界'),
                      onSelected: busy ? null : vm.chooseType,
                    ),
                    Padding(
                      padding: EdgeInsets.all(RoomActivityTheme.gap.r),
                      child: Text(
                        toolText(context, 'Coins', '金币数量'),
                        style: RoomActivityTheme.darkTitle,
                      ),
                    ),
                    Wrap(
                      spacing: RoomActivityTheme.gap.w,
                      runSpacing: RoomActivityTheme.gap.h,
                      children: [
                        for (final (index, amount)
                            in (mode?.amounts ?? []).indexed)
                          InkWell(
                            onTap: busy
                                ? null
                                : () => vm.chooseGold(amount.gold),
                            child: Container(
                              width: RoomActivityTheme.luckyCard.w,
                              padding: EdgeInsets.all(RoomActivityTheme.gap.r),
                              decoration: BoxDecoration(
                                color: state.gold == amount.gold
                                    ? RoomActivityTheme.gold
                                    : RoomActivityTheme.white,
                                borderRadius: RoomActivityTheme.cardRadius,
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    [
                                      AppAssets.roomActivityIcLuckyBagGold1,
                                      AppAssets.roomActivityIcLuckyBagGold2,
                                      AppAssets.roomActivityIcLuckyBagGold3,
                                      AppAssets.roomActivityIcLuckyBagGold4,
                                    ][index % 4],
                                    width: RoomActivityTheme.goldIcon.r,
                                    height: RoomActivityTheme.goldIcon.r,
                                  ),
                                  Text(
                                    '${amount.gold}',
                                    style: RoomActivityTheme.darkBody,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.all(RoomActivityTheme.gap.r),
                      child: Text(
                        toolText(context, 'Number of recipients', '领取人数'),
                        style: RoomActivityTheme.darkTitle,
                      ),
                    ),
                    ToolChoices<int>(
                      values: people,
                      selected: state.people,
                      label: (n) => '$n',
                      onSelected: busy ? null : vm.choosePeople,
                    ),
                    Padding(
                      padding: EdgeInsets.all(RoomActivityTheme.gap.r),
                      child: Text(
                        toolText(context, 'Countdown (seconds)', '倒计时（秒）'),
                        style: RoomActivityTheme.darkTitle,
                      ),
                    ),
                    ToolChoices<int>(
                      values: mode?.countdowns ?? [],
                      selected: state.countdown,
                      label: (n) => '$n',
                      onSelected: busy ? null : vm.chooseCountdown,
                    ),
                    if (mode?.amounts.isEmpty ?? true)
                      Text(
                        toolText(
                          context,
                          'No available Lucky Box configuration',
                          '暂无可用宝箱配置',
                        ),
                        style: RoomActivityTheme.darkBody,
                      ),
                    TextButton(
                      onPressed: () => showRoomLuckyBoxList(context, roomId),
                      child: Text(toolText(context, 'Lucky Boxes', '宝箱列表')),
                    ),
                  ],
                ),
              ),
            ),
            RoomActivityImageButton(
              asset: AppAssets.roomActivityBtnLuckyBagSend,
              text: '${toolText(context, 'Send', '发送')} · ${state.gold ?? 0}',
              busy: state.sending || state.loading,
              onTap: state.canSubmit && !busy ? send : null,
            ),
          ],
        ),
      ),
    );
  }
}

class RoomLuckyBoxList extends HookConsumerWidget {
  const RoomLuckyBoxList({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomLuckyBoxProvider(roomId));
    final vm = ref.read(roomLuckyBoxProvider(roomId).notifier);
    useEffect(() {
      Future.microtask(vm.refreshList);
      return null;
    }, [vm]);
    return RoomActivityPanel(
      title: toolText(context, 'Lucky Box', '幸运盒'),
      light: true,
      child: Column(
        children: [
          if (state.error != null)
            RoomActivityError(state.error!, light: true, retry: vm.load),
          if (state.bags.isEmpty)
            Text(
              toolText(context, 'No Lucky Boxes', '暂无幸运盒'),
              style: RoomActivityTheme.darkBody,
            ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: RoomActivityTheme.gap.w,
                mainAxisSpacing: RoomActivityTheme.gap.h,
                childAspectRatio: .8,
              ),
              itemCount: state.bags.length,
              itemBuilder: (context, index) {
                final bag = state.bags[index];
                final seconds = bag.remaining(DateTime.now());
                return InkWell(
                  onTap: seconds > 0
                      ? null
                      : () async {
                          final route = ModalRoute.of(context);
                          Navigator.of(context).pop();
                          await route?.completed;
                          if (vm.valid) vm.open(bag.id);
                        },
                  child: Container(
                    padding: EdgeInsets.all(RoomActivityTheme.gap.r),
                    decoration: const BoxDecoration(
                      color: RoomActivityTheme.gold,
                      borderRadius: RoomActivityTheme.cardRadius,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(AppAssets.roomActivityIcLuckyBag),
                        ),
                        Text(
                          bag.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RoomActivityTheme.darkBody,
                        ),
                        Text(
                          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                          style: RoomActivityTheme.darkBody,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          TextButton(
            onPressed: vm.load,
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
) async => ref.read(roomLuckyBoxProvider(roomId).notifier).open(id);
