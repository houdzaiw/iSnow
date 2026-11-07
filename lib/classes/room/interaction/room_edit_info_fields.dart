import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/app_theme.dart';

class RoomEditInfoField extends StatelessWidget {
  const RoomEditInfoField({
    super.key,
    required this.controller,
    required this.label,
    required this.limit,
    required this.enabled,
    required this.fieldKey,
    this.multiline = false,
    this.focusNode,
    this.onSubmitted,
    this.hint,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int limit;
  final bool enabled, multiline;
  final Key fieldKey;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final input = TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLength: limit,
      maxLines: multiline ? null : 1,
      expands: multiline,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
      textInputAction: multiline
          ? TextInputAction.newline
          : TextInputAction.next,
      onSubmitted: onSubmitted,
      style: RoomProfileTheme.editInput,
      cursorColor: RoomProfileTheme.pink,
      scrollPadding: EdgeInsets.only(
        bottom:
            RoomProfileTheme.editConfirmHeight.w + RoomProfileTheme.section.h,
      ),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: hint,
        hintStyle: RoomProfileTheme.editHint,
        filled: false,
        border: RoomProfileTheme.editFieldBorder,
        enabledBorder: RoomProfileTheme.editFieldBorder,
        focusedBorder: RoomProfileTheme.editFieldBorder,
        disabledBorder: RoomProfileTheme.editFieldBorder,
        contentPadding: EdgeInsets.all(RoomProfileTheme.gap.r),
      ),
    );
    final counter = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) => Text(
        '${value.text.characters.length}/$limit',
        textAlign: TextAlign.end,
        style: RoomProfileTheme.editCounter,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RoomProfileTheme.editLabel),
        SizedBox(height: RoomProfileTheme.editLabelGap.h),
        Semantics(
          label: label,
          child: Container(
            height:
                (multiline
                        ? RoomProfileTheme.editDescriptionHeight
                        : RoomProfileTheme.editNameHeight)
                    .w,
            decoration: const BoxDecoration(
              color: RoomProfileTheme.field,
              borderRadius: RoomProfileTheme.imageRadius,
            ),
            child: multiline
                ? Column(
                    children: [
                      Expanded(child: input),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: RoomProfileTheme.gap.w,
                            bottom: RoomProfileTheme.gap.h,
                          ),
                          child: counter,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: input),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: RoomProfileTheme.gap.w,
                        ),
                        child: SizedBox(
                          width: RoomProfileTheme.editCounterWidth.w,
                          child: counter,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
