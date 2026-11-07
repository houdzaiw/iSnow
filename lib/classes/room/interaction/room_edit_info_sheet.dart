import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../more/room_tools_widgets.dart';
import '../viewmodel/room_state.dart';
import 'room_edit_info_fields.dart';
import 'room_interaction_frame.dart';
import 'room_interaction_view_model.dart';
import 'room_management_sheet.dart';
import 'room_management_view_model.dart';
import 'room_profile_widgets.dart';

class RoomEditInfoSheet extends HookConsumerWidget {
  const RoomEditInfoSheet({
    super.key,
    required this.session,
    required this.roomState,
  });
  final RoomInteractionKey session;
  final ProviderListenable<RoomPageState> roomState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomState);
    final provider = roomManagementProvider((
      session: session,
      section: RoomManagementSection.edit,
    ));
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final name = useTextEditingController(text: room.roomTitle);
    final description = useTextEditingController(text: room.roomDesc ?? '');
    final nameFocus = useFocusNode();
    final descriptionFocus = useFocusNode();
    final scroll = useScrollController();
    useListenable(name);
    _listenEditorLifetime(context, ref, session, roomState, onClose: vm.close);
    final busy = state.busy || !room.isOwnerOrManager;
    final canSave = !busy && name.text.trim().isNotEmpty;

    Future<void> save() async {
      FocusScope.of(context).unfocus();
      final saved = await vm.saveInfo(name.text, description.text);
      if (saved &&
          context.mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
      } else if (context.mounted && scroll.hasClients) {
        scroll.jumpTo(0);
      }
    }

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) vm.close();
      },
      child: RoomProfileSheet(
        height: RoomProfileTheme.editHeight,
        header: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: RoomProfileTheme.editHandleArea.h,
              child: Center(
                child: Container(
                  width: RoomProfileTheme.editHandleWidth.w,
                  height: RoomProfileTheme.editHandleHeight.h,
                  decoration: const BoxDecoration(
                    color: RoomProfileTheme.editHandleColor,
                    borderRadius: RoomProfileTheme.pillRadius,
                  ),
                ),
              ),
            ),
            RoomProfileHeader(
              title: toolText(context, 'Room Management', '房间管理'),
              onBack: () => Navigator.pop(context),
              trailing: PopupMenuButton<RoomManagementSection>(
                tooltip: toolText(context, 'More options', '更多选项'),
                enabled: !busy,
                color: RoomProfileTheme.surface,
                onOpened: () => FocusScope.of(context).unfocus(),
                onSelected: (_) {
                  if (vm.active) {
                    showRoomManagementSheet(
                      context,
                      session,
                      roomState,
                      RoomManagementSection.location,
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: RoomManagementSection.location,
                    child: _EditorLocationLabel(
                      session: session,
                      roomState: roomState,
                    ),
                  ),
                ],
                child: SizedBox.square(
                  dimension: RoomProfileTheme.touch.r,
                  child: Center(
                    child: RoomProfileAsset(
                      asset: AppAssets.lanhuRoomBottomMore,
                      color: RoomProfileTheme.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                key: const PageStorageKey('room-edit-info-form'),
                padding: EdgeInsetsDirectional.fromSTEB(
                  RoomProfileTheme.editFormStart.w,
                  RoomProfileTheme.gap.h,
                  RoomProfileTheme.editFormEnd.w,
                  RoomProfileTheme.gap.h,
                ),
                children: [
                  if (state.error != null) ...[
                    Text(state.error!, style: RoomProfileTheme.editError),
                    SizedBox(height: RoomProfileTheme.gap.h),
                  ],
                  Center(
                    child: _EditCover(
                      avatar: room.roomAvatar,
                      localImage: state.localImage,
                      busy: busy,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        vm.choosePhoto();
                      },
                    ),
                  ),
                  SizedBox(height: RoomProfileTheme.editCoverGap.h),
                  RoomEditInfoField(
                    controller: name,
                    focusNode: nameFocus,
                    fieldKey: const ValueKey('room-edit-name'),
                    enabled: !busy,
                    label: toolText(context, 'Room Name', '房间名称'),
                    limit: RoomManagementViewModel.nameLimit,
                    onSubmitted: (_) => descriptionFocus.requestFocus(),
                  ),
                  SizedBox(height: RoomProfileTheme.editFieldGap.h),
                  RoomEditInfoField(
                    controller: description,
                    focusNode: descriptionFocus,
                    fieldKey: const ValueKey('room-edit-description'),
                    enabled: !busy,
                    label: toolText(context, 'Description', '房间简介'),
                    hint: toolText(context, 'Please enter here', '请输入房间简介'),
                    limit: RoomManagementViewModel.descriptionLimit,
                    multiline: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                RoomProfileTheme.section.w,
                RoomProfileTheme.gap.h,
                RoomProfileTheme.section.w,
                RoomProfileTheme.giftBottom.h,
              ),
              child: Semantics(
                button: true,
                enabled: canSave,
                label: toolText(context, 'Confirm', '确认'),
                child: InkWell(
                  key: const ValueKey('room-edit-confirm'),
                  onTap: canSave ? save : null,
                  borderRadius: RoomProfileTheme.pillRadius,
                  child: Opacity(
                    opacity: canSave || busy
                        ? 1
                        : RoomProfileTheme.editDisabledOpacity,
                    child: Container(
                      width: double.infinity,
                      height: RoomProfileTheme.editConfirmHeight.w.clamp(
                        RoomProfileTheme.touch,
                        double.infinity,
                      ),
                      decoration: const BoxDecoration(
                        gradient: RoomProfileTheme.giftGradient,
                        borderRadius: RoomProfileTheme.pillRadius,
                      ),
                      child: Center(
                        child: busy
                            ? _editProgress()
                            : Text(
                                toolText(context, 'Confirm', '确认'),
                                style: RoomProfileTheme.editConfirm,
                              ),
                      ),
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

class _EditCover extends StatelessWidget {
  const _EditCover({
    required this.avatar,
    required this.localImage,
    required this.busy,
    required this.onTap,
  });
  final String? avatar, localImage;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: !busy,
    label: toolText(context, 'Change cover', '更换封面'),
    child: InkWell(
      onTap: busy ? null : onTap,
      borderRadius: RoomProfileTheme.imageRadius,
      child: ClipRRect(
        borderRadius: RoomProfileTheme.imageRadius,
        child: SizedBox.square(
          dimension: RoomProfileTheme.editCover.r,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (localImage case final path?)
                Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const RoomProfileAsset(
                    asset: AppAssets.iconMissing,
                    color: AppColors.missingAsset,
                  ),
                )
              else
                RoomProfilePicture(url: avatar),
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: RoomProfileAsset(
                  asset: AppAssets.roomEditCamera,
                  width: RoomProfileTheme.editCameraWidth.r,
                  height: RoomProfileTheme.editCameraHeight.r,
                ),
              ),
              if (busy)
                ColoredBox(
                  color: RoomProfileTheme.badgeScrim,
                  child: Center(child: _editProgress()),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _editProgress() => SizedBox.square(
  dimension: RoomProfileTheme.editProgressSize.r,
  child: const CircularProgressIndicator(
    color: AppColors.textInverse,
    strokeWidth: RoomProfileTheme.editProgressStroke,
  ),
);

void _listenEditorLifetime(
  BuildContext context,
  WidgetRef ref,
  RoomInteractionKey session,
  ProviderListenable<RoomPageState> roomState, {
  VoidCallback? onClose,
}) {
  listenRoomInteractionLifetime(context, ref, session, onClose: onClose);
  void closeForPermission() {
    onClose?.call();
    final route = ModalRoute.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && route?.isActive == true) {
        Navigator.of(context).removeRoute(route!);
      }
    });
  }

  if (!ref.watch(roomState).isOwnerOrManager) closeForPermission();
  ref.listen(roomState, (_, next) {
    if (!next.isOwnerOrManager) closeForPermission();
  });
}

class _EditorLocationLabel extends ConsumerWidget {
  const _EditorLocationLabel({required this.session, required this.roomState});
  final RoomInteractionKey session;
  final ProviderListenable<RoomPageState> roomState;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenEditorLifetime(context, ref, session, roomState);
    return Text(
      toolText(context, 'Location', '位置'),
      style: RoomProfileTheme.description,
    );
  }
}
