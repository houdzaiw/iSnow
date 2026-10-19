import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_scaffold.dart';
import 'room_tools_controller.dart';

String toolText(BuildContext context, String en, String zh) =>
    context.l10n.isChinese ? zh : en;

class RoomToolPage extends ConsumerWidget {
  const RoomToolPage({
    super.key,
    required this.roomId,
    required this.title,
    required this.child,
  });
  final String roomId, title;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomToolsControllerProvider(roomId));
    return CustomScaffold(
      title: title,
      onBackPressed: () => Navigator.of(context).pop(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (state.error != null)
              MaterialBanner(
                content: Text(state.error!),
                actions: [
                  TextButton(
                    onPressed: () => ref
                        .read(roomToolsControllerProvider(roomId).notifier)
                        .refresh(),
                    child: Text(context.l10n.t('app.retry')),
                  ),
                ],
              ),
            if (!state.sessionActive)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(context.l10n.t('room.gift.roomUnavailable')),
              ),
            Expanded(
              child: IgnorePointer(
                ignoring: !state.sessionActive,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolHeading extends StatelessWidget {
  const ToolHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, style: AppTextStyles.bodyStrong),
    ),
  );
}

class ToolImage extends StatelessWidget {
  const ToolImage(this.url, {super.key, this.size = AppSpacing.avatarSizeMd});
  final String url;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: url.isEmpty
        ? Image.asset(AppAssets.lanhuRoomIconMissing)
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Image.asset(AppAssets.lanhuRoomIconMissing),
          ),
  );
}

class ToolChoices<T> extends StatelessWidget {
  const ToolChoices({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });
  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T>? onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: values
        .map(
          (value) => ChoiceChip(
            selected: selected == value,
            label: Text(label(value)),
            onSelected: onSelected == null ? null : (_) => onSelected!(value),
          ),
        )
        .toList(),
  );
}

Future<bool> confirmRoomTool(
  BuildContext context,
  String title,
  String content,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.t('app.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.t('auth.confirm')),
          ),
        ],
      ),
    ) ==
    true;

Future<T?> pushRoomTool<T>(BuildContext context, Widget page) {
  final router = GoRouter.maybeOf(context);
  if (router != null) return router.push<T>('/room-tool', extra: page);
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(MaterialPageRoute(builder: (_) => page));
}

/// Remove only this page when a newer wallet/profile page is above it.
void dismissOwnedRoomTool(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route == null || !route.isActive) return;
  if (route.isCurrent) {
    Navigator.of(context).pop();
    return;
  }
  final router = GoRouter.maybeOf(context);
  final page = route.settings;
  if (router == null || page is! Page) return;
  final current = router.routerDelegate.currentConfiguration;
  final matches = current.matches
      .where((match) => match.pageKey != page.key)
      .toList();
  if (matches.isEmpty || matches.length == current.matches.length) return;
  for (final match in current.matches) {
    if (match.pageKey == page.key && match is ImperativeRouteMatch) {
      match.complete(null);
    }
  }
  router.restore(
    RouteMatchList(
      matches: matches,
      uri: current.uri,
      pathParameters: current.pathParameters,
      extra: current.extra,
    ),
  );
}
