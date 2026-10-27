import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../model/room_share_models.dart';
import '../../../theme/app_theme.dart';
import 'room_tools_widgets.dart';

class RoomShareContacts extends HookWidget {
  const RoomShareContacts({
    super.key,
    required this.contacts,
    required this.query,
    required this.onSearch,
    required this.onInvite,
    required this.loading,
    required this.enabled,
    required this.onRetry,
    this.error,
    this.onLoadMore,
  });
  final List<RoomShareContact> contacts;
  final String query;
  final ValueChanged<String> onSearch;
  final ValueChanged<RoomShareContact> onInvite;
  final bool loading, enabled;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: query);
    useEffect(() {
      if (controller.text.trim() != query) {
        controller.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
      }
      return null;
    }, [query]);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: TextField(
            controller: controller,
            enabled: enabled,
            onChanged: onSearch,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: toolText(context, 'Search name or ID', '搜索昵称或 ID'),
              hintStyle: AppTextStyles.caption,
              filled: true,
              fillColor: AppColors.sheetInputBackground,
              border: const OutlineInputBorder(
                borderRadius: AppRadius.fieldBorder,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            children: [
              if (error != null)
                TextButton(
                  onPressed: enabled ? onRetry : null,
                  child: Text(error!, style: AppTextStyles.bodySmall),
                ),
              if (!loading && contacts.isEmpty && error == null)
                ToolHeading(toolText(context, 'No contacts found', '暂无联系人')),
              for (final user in contacts)
                ListTile(
                  key: ValueKey('room-share-contact-${user.uid}'),
                  leading: ClipOval(child: ToolImage(user.avatar)),
                  title: Text(
                    user.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrongSmall,
                  ),
                  subtitle: Text('${user.uid}', style: AppTextStyles.caption),
                  onTap: enabled ? () => onInvite(user) : null,
                ),
              if (onLoadMore != null)
                TextButton(
                  onPressed: enabled && !loading ? onLoadMore : null,
                  child: Text(toolText(context, 'Load more', '加载更多')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
