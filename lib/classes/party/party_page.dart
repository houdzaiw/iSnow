import 'package:card_swiper/card_swiper.dart';
import 'package:country_flags/country_flags.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/country_info.dart';
import '../../model/server_response.dart';
import '../../theme/app_theme.dart';
import '../create_room/create_room_entry_flow.dart';

part 'model/home_feed_model.dart';
part 'home_feed_repository.dart';
part 'viewmodel/home_feed_state.dart';
part 'viewmodel/home_feed_view_model.dart';
part 'views/home_country_filter_bar.dart';
part 'views/home_feed_list_view.dart';
part 'views/home_feed_view.dart';
part 'views/party_feed_view.dart';

enum _MainFeedTab { party, room }

enum _FeedSortTab { now, newest }

extension on _FeedSortTab {
  int get partyType => this == _FeedSortTab.now ? 1 : 2;
}

final _partyRepositoryProvider = Provider<_PartyRepository>((ref) {
  return _PartyRepository(HttpDioManager());
});

final _partyFeedViewModelProvider =
    NotifierProvider.family<_PartyFeedViewModel, _PartyFeedState, _FeedSortTab>(
      _PartyFeedViewModel.new,
    );

class PartyPage extends HookConsumerWidget {
  const PartyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(
      initialLength: _MainFeedTab.values.length,
      initialIndex: _MainFeedTab.room.index,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PartyHeader(tabController: tabController),
            Expanded(
              child: ExtendedTabBarView(
                controller: tabController,
                cacheExtent: 1,
                children: const [
                  _FeedSection(mainTab: _MainFeedTab.party),
                  _FeedSection(mainTab: _MainFeedTab.room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyRepository {
  const _PartyRepository(this._httpManager);

  final HttpDioManager _httpManager;

  Future<List<_PartyFeedItem>> fetchPartyList({
    required int type,
    required int pageNum,
  }) async {
    final response = await _httpManager.get(
      HttpApi.partyList,
      queryParameters: {'type': type, 'pageNum': pageNum},
    );
    return _requireList(response)
        .whereType<Map>()
        .map((item) => _PartyFeedItem.fromPartyJson(item))
        .toList();
  }

  List<dynamic> _requireList(dynamic response) {
    final server = NadyServerResponse<List<dynamic>>.fromJson(
      _asMap(response),
      (json) {
        if (json is List) return json;
        if (json is Map && json['list'] is List) return json['list'] as List;
        return <dynamic>[];
      },
    );
    if (!server.isSuccess) {
      throw server.toException();
    }
    return server.data ?? const [];
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return response.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }
}

class _PartyFeedItem {
  const _PartyFeedItem({
    required this.uid,
    required this.title,
    required this.hostName,
    required this.onlineNum,
    required this.subscribeNum,
    required this.status,
    required this.isSubscribe,
    required this.isCanceled,
    required this.tags,
    required this.subscribeUsers,
    this.coverUrl,
    this.avatarUrl,
    this.roomId,
    this.partyId,
    this.beginTime,
    this.endTime,
  });

  final int uid;
  final String? coverUrl;
  final String? avatarUrl;
  final String title;
  final String hostName;
  final int onlineNum;
  final int subscribeNum;
  final int status;
  final bool isSubscribe;
  final bool isCanceled;
  final String? roomId;
  final int? partyId;
  final DateTime? beginTime;
  final DateTime? endTime;
  final List<_PartyTagItem> tags;
  final List<_PartyUserItem> subscribeUsers;

  bool get isLive => status == 1;
  bool get isWaiting => status == 2;
  bool get isEnded => status == 3;
  bool get isClosed => isCanceled || status == 4;
  bool get canEnterRoom => isLive && (roomId?.isNotEmpty ?? false);

  int get audienceCount => isLive ? onlineNum : subscribeNum;

  String get onlineText {
    if (audienceCount >= 10000) {
      return '${(audienceCount / 10000).toStringAsFixed(1)}w';
    }
    if (audienceCount >= 1000) {
      return '${(audienceCount / 1000).toStringAsFixed(1)}k';
    }
    return '$audienceCount';
  }

  factory _PartyFeedItem.fromPartyJson(Map<dynamic, dynamic> json) {
    final userInfo = _map(json['createUserInfo']);
    final topic = _string(json['topic']) ?? _string(json['description']);
    final onlineNum = _int(json['onlineNum']);
    final rawStatus = _int(json['status']);
    final isCanceled = _bool(json['cancle']) || rawStatus == 4;
    return _PartyFeedItem(
      uid: _int(json['uid']),
      coverUrl: _string(json['picUrl']),
      avatarUrl: _string(userInfo['avatar']),
      title: topic ?? '',
      hostName: _string(userInfo['nick']) ?? '',
      onlineNum: onlineNum,
      subscribeNum: _int(json['subscribeNum']),
      status: isCanceled ? 4 : rawStatus,
      isSubscribe: _bool(json['isSubscribe']),
      isCanceled: isCanceled,
      roomId: _string(json['roomId']),
      partyId: _intOrNull(json['partyId']),
      beginTime: _dateTime(json['beginTime']),
      endTime: _dateTime(json['endTime']),
      tags: _list(json['partyTags'])
          .whereType<Map>()
          .map(_PartyTagItem.fromJson)
          .where((tag) => tag.hasContent)
          .take(2)
          .toList(growable: false),
      subscribeUsers: _list(json['subscribeUserList'])
          .whereType<Map>()
          .map(_PartyUserItem.fromJson)
          .where((user) => user.avatar != null)
          .take(8)
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const {};
  }

  static String? _string(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<dynamic> _list(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _dateTime(dynamic value) {
    final text = _string(value);
    if (text == null) return null;
    return DateTime.tryParse(text)?.toLocal();
  }
}

class _PartyTagItem {
  const _PartyTagItem({
    required this.id,
    required this.enName,
    required this.arName,
    this.trName,
    this.idName,
    this.tagPic,
  });

  final int id;
  final String enName;
  final String arName;
  final String? trName;
  final String? idName;
  final String? tagPic;

  bool get hasContent {
    return enName.isNotEmpty ||
        arName.isNotEmpty ||
        (trName?.isNotEmpty ?? false) ||
        (idName?.isNotEmpty ?? false);
  }

  String labelForLocale(String languageCode) {
    final preferred = switch (languageCode) {
      'zh' => enName,
      'tr' => trName,
      'id' => idName,
      'ar' => arName,
      _ => enName,
    };
    return _firstText(preferred, enName, arName, trName, idName, '$id');
  }

  factory _PartyTagItem.fromJson(Map<dynamic, dynamic> json) {
    return _PartyTagItem(
      id: _PartyFeedItem._int(json['id']),
      enName: _PartyFeedItem._string(json['enName']) ?? '',
      arName: _PartyFeedItem._string(json['arName']) ?? '',
      trName: _PartyFeedItem._string(json['trName']),
      idName: _PartyFeedItem._string(json['idName']),
      tagPic: _PartyFeedItem._string(json['tagPic']),
    );
  }
}

class _PartyUserItem {
  const _PartyUserItem({this.avatar});

  final String? avatar;

  factory _PartyUserItem.fromJson(Map<dynamic, dynamic> json) {
    return _PartyUserItem(avatar: _PartyFeedItem._string(json['avatar']));
  }
}

String _firstText(
  Object? first,
  Object? second, [
  Object? third,
  Object? fourth,
  Object? fifth,
  Object? sixth,
]) {
  for (final value in [first, second, third, fourth, fifth, sixth]) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return '';
}

class _PartyHeader extends ConsumerWidget {
  const _PartyHeader({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 17),
          SizedBox(
            width: 148,
            child: ExtendedTabBar(
              controller: tabController,
              tabs: [
                Tab(text: context.l10n.t('party.tabParty')),
                Tab(text: context.l10n.t('party.tabRoom')),
              ],
              indicator: const _GradientUnderlineTabIndicator(
                gradient: AppGradients.sendButton,
                width: 28,
                height: 4,
                bottom: 0,
                radius: 8,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.textPrimary,
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelColor: AppColors.textPlaceholder,
              unselectedLabelStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: AppColors.transparent,
              overlayColor: WidgetStateProperty.all(AppColors.transparent),
            ),
          ),
          const Spacer(),
          _HeaderIconButton(
            assetName: AppAssets.lanhuPartyTrophy,
            onPressed: () => context.push('/rank'),
            tooltip: context.l10n.t('rank.title'),
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            assetName: AppAssets.lanhuPartyPop,
            onPressed: () => enterOwnRoom(context, ref),
            tooltip: context.l10n.t('createRoom.title'),
          ),
          const SizedBox(width: 7),
          IconButton(
            onPressed: () {},
            icon: Image.asset(
              AppAssets.lanhuPartySearch,
              width: AppSpacing.iconSizeLg,
              height: AppSpacing.iconSizeLg,
            ),
            tooltip: 'Search',
          ),
          const SizedBox(width: 11),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.assetName,
    this.onPressed,
    this.tooltip,
  });

  final String assetName;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () {},
      icon: Image.asset(assetName, width: 24, height: 24),
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      tooltip: tooltip ?? '',
    );
  }
}

class _FeedSection extends HookConsumerWidget {
  const _FeedSection({required this.mainTab});

  final _MainFeedTab mainTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (mainTab) {
      _MainFeedTab.party => const _PartyFeedSection(),
      _MainFeedTab.room => const _HomeFeedView(),
    };
  }
}

class _PartyFeedSection extends HookConsumerWidget {
  const _PartyFeedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortController = useTabController(initialLength: 2, initialIndex: 1);

    return Stack(
      children: [
        Column(
          children: [
            _SortBar(tabController: sortController),
            Expanded(
              child: ExtendedTabBarView(
                controller: sortController,
                cacheExtent: 1,
                children: const [
                  _PartyFeedView(sortTab: _FeedSortTab.now),
                  _PartyFeedView(sortTab: _FeedSortTab.newest),
                ],
              ),
            ),
          ],
        ),
        const _CreatePartyButton(),
      ],
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 8),
      child: Row(
        children: [
          Container(
            width: 118,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEFF1),
              borderRadius: AppRadius.pillBorder,
            ),
            child: ExtendedTabBar(
              controller: tabController,
              tabs: [
                Tab(text: context.l10n.t('party.now')),
                Tab(text: context.l10n.t('party.new')),
              ],
              indicator: const BoxDecoration(
                gradient: AppGradients.sendButton,
                borderRadius: AppRadius.pillBorder,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.textInverse,
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelColor: AppColors.textPrimary,
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              dividerColor: AppColors.transparent,
              overlayColor: WidgetStateProperty.all(AppColors.transparent),
            ),
          ),
          const Spacer(),
          Image.asset(
            AppAssets.lanhuCreatePartyMine,
            width: AppSpacing.createRoomTitleTop,
            height: AppSpacing.createRoomTitleTop,
          ),
          const SizedBox(width: 3),
          Image.asset(
            AppAssets.lanhuCreatePartyChevronRight,
            width: AppSpacing.iconSizeXs,
            height: AppSpacing.iconSizeSm,
          ),
        ],
      ),
    );
  }
}

class _PartyImage extends StatelessWidget {
  const _PartyImage({
    required this.url,
    required this.assetName,
    required this.width,
    required this.height,
  });

  final String? url;
  final String assetName;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source != null && source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _AssetFallbackImage(assetName: assetName),
        errorWidget: (_, __, ___) => _AssetFallbackImage(assetName: assetName),
      );
    }
    return Image.asset(
      assetName,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }
}

class _AssetFallbackImage extends StatelessWidget {
  const _AssetFallbackImage({required this.assetName});

  final String assetName;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetName, width: double.infinity, fit: BoxFit.cover);
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url, this.size = 22});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: _PartyImage(
        url: url,
        assetName: AppAssets.lanhuPartyAvatar,
        width: size,
        height: size,
      ),
    );
  }
}

class _PartyAudioIcon extends StatelessWidget {
  const _PartyAudioIcon({
    this.width = AppSpacing.partyAudioIconSize,
    this.height = AppSpacing.partyAudioIconSize,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.lanhuPartyAudioBars,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class _CreatePartyButton extends ConsumerWidget {
  const _CreatePartyButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      right: 17,
      bottom: MediaQuery.of(context).padding.bottom + 40,
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            final created = await context.push<bool>('/party/create');
            if (created != true || !context.mounted) return;
            ref.invalidate(_partyFeedViewModelProvider(_FeedSortTab.now));
            ref.invalidate(_partyFeedViewModelProvider(_FeedSortTab.newest));
          },
          child: Center(
            child: Image.asset(
              AppAssets.lanhuPartyAdd,
              width: AppSpacing.buttonHeightLg,
              height: AppSpacing.buttonHeightLg,
            ),
          ),
        ),
      ),
    );
  }
}

class _StateList extends StatelessWidget {
  const _StateList({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: const EdgeInsets.fromLTRB(17, 110, 17, 110),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.lanhuPartyStateEmpty,
                width: AppSpacing.partyStateImageSize,
                height: AppSpacing.partyStateImageSize,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(color: AppColors.primaryPink),
                  ),
                ),
              ],
            ],
          ),
        );

        if (!constraints.hasBoundedHeight) {
          return content;
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}

class _GradientUnderlineTabIndicator extends Decoration {
  const _GradientUnderlineTabIndicator({
    required this.gradient,
    this.width = 28,
    this.height = 4,
    this.bottom = 0,
    this.radius = 8,
  });

  final Gradient gradient;
  final double width;
  final double height;
  final double bottom;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GradientUnderlinePainter(this);
  }
}

class _GradientUnderlinePainter extends BoxPainter {
  const _GradientUnderlinePainter(this.decoration);

  final _GradientUnderlineTabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    final rect = Rect.fromLTWH(
      offset.dx + (size.width - decoration.width) / 2,
      offset.dy + size.height - decoration.bottom - decoration.height,
      decoration.width,
      decoration.height,
    );
    final paint = Paint()..shader = decoration.gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(decoration.radius)),
      paint,
    );
  }
}
