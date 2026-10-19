import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/app_theme.dart';
import 'room_report_view_model.dart';
import 'room_tools_widgets.dart';

class RoomReportPage extends ConsumerWidget {
  const RoomReportPage({super.key, required this.roomId});
  final String roomId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomReportViewModelProvider(roomId));
    final vm = ref.read(roomReportViewModelProvider(roomId).notifier);
    final reasons = [
      toolText(context, 'Pornography', '色情'),
      toolText(context, 'Religion', '宗教'),
      toolText(context, 'Politics', '政治'),
      toolText(context, 'Illegal content', '违法'),
      toolText(context, 'Other', '其他'),
    ];
    return RoomToolPage(
      roomId: roomId,
      title: toolText(context, 'Report room', '举报房间'),
      child: Column(
        children: [
          for (final (index, reason) in reasons.indexed)
            CheckboxListTile(
              title: Text(reason),
              value: state.reason == index + 1,
              onChanged: state.busy ? null : (_) => vm.selectReason(index + 1),
            ),
          TextField(
            enabled: !state.busy,
            maxLength: 200,
            maxLines: 4,
            onChanged: vm.describe,
            decoration: InputDecoration(
              labelText: toolText(context, 'Description (optional)', '描述（选填）'),
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final photo in state.photos)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: Image.file(File(photo)),
                          ),
                        ),
                      ),
                      child: SizedBox.square(
                        dimension: AppSpacing.roomExitChoiceSize,
                        child: Image.file(File(photo), fit: BoxFit.cover),
                      ),
                    ),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () => vm.removePhoto(photo),
                      child: Text(toolText(context, 'Remove', '移除')),
                    ),
                  ],
                ),
              if (state.photos.length < 4)
                TextButton(
                  onPressed: state.busy ? null : vm.pickPhotos,
                  child: Image.asset(
                    AppAssets.lanhuRoomIconMissing,
                    width: AppSpacing.iconSizeLg,
                    semanticLabel: toolText(context, 'Add screenshot', '添加截图'),
                  ),
                ),
            ],
          ),
          if (state.error != null)
            Text(state.error!, style: AppTextStyles.hint),
          TextButton(
            onPressed: state.busy
                ? null
                : () async {
                    if (await vm.submit() && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            toolText(context, 'Report submitted', '举报已提交'),
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
            child: state.busy
                ? const CircularProgressIndicator()
                : Text(toolText(context, 'Submit', '提交')),
          ),
        ],
      ),
    );
  }
}
