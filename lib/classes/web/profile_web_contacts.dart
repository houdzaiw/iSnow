import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/http_api.dart';
import '../../model/im_models.dart';
import '../../model/room_share_models.dart';
import '../../theme/app_theme.dart';
import '../message/message_view_model.dart';
import '../profile/tools/profile_feature_repository.dart';
import '../profile/tools/profile_tools_widgets.dart';

class WebFriendsState {
  const WebFriendsState({
    this.users = const [],
    this.query = '',
    this.page = 0,
    this.more = true,
    this.loading = false,
    this.error,
  });
  final List<RoomShareContact> users;
  final String query;
  final int page;
  final bool more, loading;
  final Object? error;
}

final webFriendsProvider =
    StateNotifierProvider.autoDispose<WebFriendsModel, WebFriendsState>(
      (ref) => WebFriendsModel(ref.watch(profileFeatureRepositoryProvider)),
    );

class WebFriendsModel extends StateNotifier<WebFriendsState> {
  WebFriendsModel(this.features) : super(const WebFriendsState()) {
    Future.microtask(() {
      if (_alive) load();
    });
  }
  final ProfileFeatureRepository features;
  bool _alive = true;
  int _revision = 0;
  @override
  void dispose() {
    _alive = false;
    _revision++;
    super.dispose();
  }

  void search(String query) {
    _revision++;
    state = WebFriendsState(query: query);
    load();
  }

  Future<void> load({bool more = false}) async {
    if (!_alive || state.loading || more && !state.more) return;
    final old = state, revision = ++_revision;
    state = WebFriendsState(
      users: old.users,
      query: old.query,
      page: old.page,
      more: old.more,
      loading: true,
    );
    try {
      final account = await features.identity();
      final page = more ? old.page + 1 : 1;
      final raw = await features.request(
        'POST',
        HttpApi.userFriends,
        account: account,
        params: {
          'pageNum': page,
          'pageSize': 20,
          'targetUid': 0,
          'searchKey': old.query,
        },
      );
      final rows = raw is List ? raw : membershipMap(raw)['list'];
      final parsed = membershipList(rows, (j) {
        final user = j['userBaseInfo'] is Map
            ? membershipMap(j['userBaseInfo'])
            : j;
        return RoomShareContact(
          uid: membershipInt(user['uid']),
          nickname: membershipString(user['nick']),
          avatar: membershipString(user['avatar']),
        );
      });
      if (!_alive || revision != _revision) return;
      state = WebFriendsState(
        users: <int, RoomShareContact>{
          if (more)
            for (final u in old.users) u.uid: u,
          for (final u in parsed)
            if (u.uid > 0 && u.uid != account.uid) u.uid: u,
        }.values.toList(),
        query: old.query,
        page: page,
        more: parsed.length >= 20,
      );
    } catch (e) {
      if (_alive && revision == _revision) {
        state = WebFriendsState(
          users: old.users,
          query: old.query,
          page: old.page,
          more: old.more,
          error: e,
        );
      }
    }
  }
}

class ProfileWebContacts extends ConsumerStatefulWidget {
  const ProfileWebContacts({super.key, required this.recent});
  final bool recent;
  @override
  ConsumerState<ProfileWebContacts> createState() => _ProfileWebContactsState();
}

class _ProfileWebContactsState extends ConsumerState<ProfileWebContacts> {
  String query = '';
  Future<void> _select(RoomShareContact user) async {
    if (await profileToolsConfirm(
      context,
      '${context.l10n.t('tools.chooseContact')}: ${user.nickname}',
    )) {
      if (mounted) {
        Navigator.pop(
          context,
          widget.recent
              ? {
                  'type': 'chat',
                  'data': {
                    'userID': '${user.uid}',
                    'showName': user.nickname,
                    'faceUrl': user.avatar,
                  },
                }
              : {
                  'type': 'friend',
                  'data': {
                    'uid': user.uid,
                    'nick': user.nickname,
                    'avatar': user.avatar,
                  },
                },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.recent ? null : ref.watch(webFriendsProvider);
    final recent = widget.recent ? ref.watch(messageViewModelProvider) : null;
    final people = widget.recent
        ? [
            for (final c in recent!.conversations)
              if (int.tryParse(c.userID ?? '') case final uid?)
                if (uid > 0 && !isImSystemUser('$uid'))
                  RoomShareContact(
                    uid: uid,
                    nickname: imConversationTitle(c),
                    avatar: c.faceUrl ?? '',
                  ),
          ]
        : friends!.users;
    final filtered = people.where(
      (u) =>
          u.nickname.toLowerCase().contains(query.toLowerCase()) ||
          '${u.uid}'.contains(query),
    );
    return Column(
      children: [
        Padding(
          padding: ProfileToolsTheme.smallPadding,
          child: TextField(
            onChanged: (value) {
              setState(() => query = value);
              if (!widget.recent) {
                ref.read(webFriendsProvider.notifier).search(value);
              }
            },
            decoration: InputDecoration(
              labelText: context.l10n.t('tools.search'),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: ProfileToolsTheme.smallPadding,
            children: [
              if (friends?.loading == true || recent?.isLoading == true)
                const Center(child: CircularProgressIndicator()),
              if (friends?.error != null || recent?.errorMessage != null)
                ProfileToolsError(
                  error: friends?.error ?? recent?.errorMessage,
                  retry: () => widget.recent
                      ? ref.read(messageViewModelProvider.notifier).load()
                      : ref.read(webFriendsProvider.notifier).load(),
                ),
              if (filtered.isEmpty &&
                  friends?.loading != true &&
                  recent?.isLoading != true)
                Center(child: Text(context.l10n.t('tools.empty'))),
              for (final user in filtered)
                ListTile(
                  onTap: () => _select(user),
                  leading: MembershipImage(user.avatar),
                  title: Text(user.nickname),
                  subtitle: Text('${user.uid}'),
                ),
              if (friends?.more == true && friends!.users.isNotEmpty)
                TextButton(
                  onPressed: friends.loading
                      ? null
                      : () => ref
                            .read(webFriendsProvider.notifier)
                            .load(more: true),
                  child: Text(context.l10n.t('tools.more')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
