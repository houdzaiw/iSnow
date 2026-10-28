part of '../room_page.dart';

void _showRoomMoreToolsSheet(
  BuildContext context,
  WidgetRef ref,
  AutoDisposeStateNotifierProvider<RoomViewModel, RoomPageState> provider,
) {
  var openingShare = false;
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.modalScrimStrong,
    builder: (sheetContext) {
      return _RoomMoreToolsSheet(
        roomProvider: provider,
        onOpenTool: (action) async {
          final roomId = _roomMoreRoomId(ref.read(provider));
          if (action == 'share') {
            if (openingShare ||
                !(ModalRoute.of(sheetContext)?.isCurrent ?? false)) {
              return;
            }
            openingShare = true;
            final repository = ref.read(roomRepositoryProvider);
            final generation = repository.roomGeneration;
            final route = ModalRoute.of(sheetContext);
            Navigator.of(sheetContext).pop();
            await route?.completed;
            if (context.mounted &&
                (ModalRoute.of(context)?.isCurrent ?? true) &&
                repository.roomGeneration == generation &&
                repository.roomState.isInRoom &&
                repository.roomState.currentRoomId == roomId) {
              await showRoomShareSheet(context, roomId);
            }
            return;
          }
          final page = switch (action) {
            'report' => RoomReportPage(roomId: roomId),
            'effects' => RoomSettingsPage(
              roomId: roomId,
              section: RoomSettingSection.effects,
            ),
            'counter' => RoomSettingsPage(
              roomId: roomId,
              section: RoomSettingSection.charmCounter,
            ),
            'currency' => RoomSettingsPage(
              roomId: roomId,
              section: RoomSettingSection.charmCurrency,
            ),
            'pk' => RoomPkPage(roomId: roomId),
            'lucky' => RoomLuckyBoxPage(roomId: roomId),
            _ => RoomLobbyPage(roomId: roomId),
          };
          Navigator.of(sheetContext).pop();
          if (context.mounted) pushRoomTool(context, page);
        },
        onOpenMusic: () {
          final roomState = ref.read(provider);
          Navigator.of(sheetContext).pop();
          if (context.mounted) _openRoomMusic(ref, roomState);
        },
        onOpenBanner: (banner, game) {
          final roomState = ref.read(provider);
          final targetUrl = banner.resolvedRouteUrl(
            roomId: _roomMoreRoomId(roomState),
            languageCode: Localizations.localeOf(context).languageCode,
          );
          final target = Uri.tryParse(targetUrl);
          if (target == null ||
              !{'http', 'https'}.contains(target.scheme) ||
              target.host.isEmpty ||
              target.userInfo.isNotEmpty) {
            _showRoomMoreSnack(
              sheetContext,
              toolText(context, 'This tool is unavailable', '此功能当前不可用'),
            );
            return;
          }

          Navigator.of(sheetContext).pop();
          if (!context.mounted) return;
          if (game) {
            openRoomGame(
              context,
              ref,
              _roomMoreRoomId(roomState),
              targetUrl,
              banner.displayName,
            );
            return;
          }
          context.push(
            Uri(
              path: '/web-view',
              queryParameters: {
                'title': banner.displayName,
                'uri': targetUrl,
                'hiddenAppBar': 'false',
              },
            ).toString(),
          );
        },
      );
    },
  );
}
