import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../model/room_share_models.dart';
import '../../theme/app_theme.dart';
import 'web_share_models.dart';
import '../profile/tools/profile_tools_widgets.dart';
import 'profile_web_actions.dart';
import 'profile_web_contacts.dart';

class ProfileWebShareSheet extends ConsumerStatefulWidget {
  const ProfileWebShareSheet({
    super.key,
    required this.request,
    required this.isCurrent,
  });
  final WebShareRequest request;
  final bool Function() isCurrent;
  @override
  ConsumerState<ProfileWebShareSheet> createState() =>
      _ProfileWebShareSheetState();
}

class _ProfileWebShareSheetState extends ConsumerState<ProfileWebShareSheet> {
  int index = 0;
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final materials = widget.request.materials;
    final tabs = <String>[
      if (widget.request.showShare) 'share',
      if (widget.request.showRecent) 'recent',
      if (widget.request.showFriends) 'friends',
    ];
    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.sizeOf(context).height * ProfileToolsTheme.sheetFraction,
        child: tabs.isEmpty
            ? Center(child: Text(context.l10n.t('tools.empty')))
            : DefaultTabController(
                length: tabs.length,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ExtendedTabBar(
                            labelColor: ProfileToolsTheme.tabActive,
                            unselectedLabelColor: ProfileToolsTheme.tabInactive,
                            indicatorColor: ProfileToolsTheme.tabIndicator,
                            tabs: [
                              for (final tab in tabs)
                                Tab(text: context.l10n.t('tools.$tab')),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.l10n.t('tools.close')),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ExtendedTabBarView(
                        children: [
                          for (final tab in tabs)
                            if (tab != 'share')
                              ProfileWebContacts(recent: tab == 'recent')
                            else
                              materials.isEmpty
                                  ? Center(
                                      child: Text(
                                        context.l10n.t('tools.empty'),
                                      ),
                                    )
                                  : ListView(
                                      padding: ProfileToolsTheme.padding,
                                      children: [
                                        SizedBox(
                                          height: ProfileToolsTheme.preview,
                                          child: PageView.builder(
                                            itemCount: materials.length,
                                            onPageChanged: (i) =>
                                                setState(() => index = i),
                                            itemBuilder: (_, i) =>
                                                MembershipImage(
                                                  materials[i].image,
                                                  width: double.infinity,
                                                  height:
                                                      ProfileToolsTheme.preview,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          materials[index].title,
                                          style: ProfileToolsTheme.body,
                                        ),
                                        Text(
                                          materials[index].link,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: ProfileToolsTheme.caption,
                                        ),
                                        Wrap(
                                          spacing:
                                              ProfileToolsTheme.gridSpacing,
                                          children: [
                                            for (final action
                                                in RoomShareAction.values)
                                              TextButton(
                                                onPressed: busy
                                                    ? null
                                                    : () async {
                                                        setState(
                                                          () => busy = true,
                                                        );
                                                        final actions = ref.read(
                                                          profileWebActionsProvider,
                                                        );
                                                        final render = context
                                                            .findRenderObject();
                                                        final rect =
                                                            render is RenderBox
                                                            ? render.localToGlobal(
                                                                    Offset.zero,
                                                                  ) &
                                                                  render.size
                                                            : Rect.zero;
                                                        try {
                                                          final material =
                                                              materials[index];
                                                          await actions.shareContent(
                                                            action.name == 'x'
                                                                ? 'twitter'
                                                                : action.name,
                                                            {
                                                              'title': material
                                                                  .title,
                                                              'linkUrl':
                                                                  material.link,
                                                            },
                                                            rect,
                                                            isCurrent: () =>
                                                                mounted &&
                                                                widget
                                                                    .isCurrent(),
                                                          );
                                                          if (context.mounted &&
                                                              widget
                                                                  .isCurrent() &&
                                                              action ==
                                                                  RoomShareAction
                                                                      .copy) {
                                                            profileToolsNotice(
                                                              context,
                                                              null,
                                                              key:
                                                                  'tools.copied',
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (context.mounted &&
                                                              widget
                                                                  .isCurrent()) {
                                                            profileToolsNotice(
                                                              context,
                                                              e,
                                                            );
                                                          }
                                                        } finally {
                                                          if (mounted) {
                                                            setState(
                                                              () =>
                                                                  busy = false,
                                                            );
                                                          }
                                                        }
                                                      },
                                                child: Text(action.channelName),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
