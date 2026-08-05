import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../localization/app_localizations.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/server_response.dart';
import '../../theme/app_theme.dart';

enum _MainFeedTab { party, room }

enum _FeedSortTab { now, newest }

class _FeedQuery {
  const _FeedQuery({required this.mainTab, required this.sortTab});

  final _MainFeedTab mainTab;
  final _FeedSortTab sortTab;

  int get partyType => sortTab == _FeedSortTab.now ? 0 : 1;

  @override
  bool operator ==(Object other) {
    return other is _FeedQuery &&
        other.mainTab == mainTab &&
        other.sortTab == sortTab;
  }

  @override
  int get hashCode => Object.hash(mainTab, sortTab);
}

final _partyRepositoryProvider = Provider<_PartyRepository>((ref) {
  return _PartyRepository(HttpDioManager());
});

final _feedItemsProvider =
    FutureProvider.family<List<_PartyFeedItem>, _FeedQuery>((ref, query) async {
      final repository = ref.watch(_partyRepositoryProvider);
      return switch (query.mainTab) {
        _MainFeedTab.party => repository.fetchPartyList(
          type: query.partyType,
          pageNum: 1,
        ),
        _MainFeedTab.room => repository.fetchRecommendRooms(page: 1),
      };
    });

class PartyPage extends HookConsumerWidget {
  const PartyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);

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

  Future<List<_PartyFeedItem>> fetchRecommendRooms({required int page}) async {
    final response = await _httpManager.get(
      HttpApi.homeRecommendRoom,
      queryParameters: {'page': page},
    );
    return _requireList(response)
        .whereType<Map>()
        .map((item) => _PartyFeedItem.fromRoomJson(item))
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
    required this.title,
    required this.hostName,
    required this.onlineCount,
    required this.isLive,
    this.coverUrl,
    this.avatarUrl,
    this.roomId,
    this.partyId,
  });

  final String? coverUrl;
  final String? avatarUrl;
  final String title;
  final String hostName;
  final int onlineCount;
  final bool isLive;
  final String? roomId;
  final int? partyId;

  String get onlineText {
    if (onlineCount >= 10000) {
      return '${(onlineCount / 10000).toStringAsFixed(1)}w';
    }
    if (onlineCount >= 1000) {
      return '${(onlineCount / 1000).toStringAsFixed(1)}k';
    }
    return '$onlineCount';
  }

  factory _PartyFeedItem.fromPartyJson(Map<dynamic, dynamic> json) {
    final userInfo = _map(json['createUserInfo']);
    final topic = _string(json['topic']) ?? _string(json['description']);
    final onlineNum = _int(json['onlineNum']);
    return _PartyFeedItem(
      coverUrl: _string(json['picUrl']),
      avatarUrl: _string(userInfo['avatar']),
      title: topic ?? '',
      hostName: _string(userInfo['nick']) ?? '',
      onlineCount: onlineNum == 0 ? _int(json['subscribeNum']) : onlineNum,
      isLive: _int(json['status']) == 1 || onlineNum > 0,
      roomId: _string(json['roomId']),
      partyId: _intOrNull(json['partyId']),
    );
  }

  factory _PartyFeedItem.fromRoomJson(Map<dynamic, dynamic> json) {
    final audienceTop5 = _map(json['audienceTop5']);
    final audience = audienceTop5['roomAudience'];
    final firstAudience = audience is List && audience.isNotEmpty
        ? _map(audience.first)
        : const <String, dynamic>{};

    return _PartyFeedItem(
      coverUrl: _string(json['cover']),
      avatarUrl: _string(firstAudience['avatar']),
      title: _string(json['title']) ?? '',
      hostName:
          _string(firstAudience['nick']) ??
          _string(json['nameEn']) ??
          _string(json['country']) ??
          '',
      onlineCount: _int(json['online']),
      isLive: true,
      roomId: _string(json['roomId']),
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
}

class _PartyHeader extends StatelessWidget {
  const _PartyHeader({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
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
              indicator: const BoxDecoration(
                gradient: AppGradients.sendButton,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              indicatorPadding: const EdgeInsets.only(
                left: 14,
                right: 14,
                top: 50,
                bottom: 11,
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
          _HeaderIconButton(assetName: AppAssets.lanhuPartyTrophy),
          const SizedBox(width: 8),
          _HeaderIconButton(assetName: AppAssets.lanhuPartyPop),
          const SizedBox(width: 7),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded),
            color: AppColors.primaryPinkDeep,
            iconSize: 32,
            tooltip: 'Search',
          ),
          const SizedBox(width: 11),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.assetName});

  final String assetName;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Image.asset(assetName, width: 24, height: 24),
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      tooltip: '',
    );
  }
}

class _FeedSection extends HookConsumerWidget {
  const _FeedSection({required this.mainTab});

  final _MainFeedTab mainTab;

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
                children: [
                  _FeedList(
                    query: _FeedQuery(
                      mainTab: mainTab,
                      sortTab: _FeedSortTab.now,
                    ),
                  ),
                  _FeedList(
                    query: _FeedQuery(
                      mainTab: mainTab,
                      sortTab: _FeedSortTab.newest,
                    ),
                  ),
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
          const Icon(Icons.person_rounded, color: Color(0xFFFF8DA7), size: 20),
          const SizedBox(width: 3),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({required this.query});

  final _FeedQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedItems = ref.watch(_feedItemsProvider(query));

    return feedItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _StateList(
        text: context.l10n.t('party.loadFailed'),
        actionLabel: context.l10n.t('app.retry'),
        onAction: () => ref.invalidate(_feedItemsProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _StateList(text: context.l10n.t('party.noData'));
        }
        return RefreshIndicator(
          color: AppColors.primaryPink,
          onRefresh: () => ref.refresh(_feedItemsProvider(query).future),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(17, 0, 17, 110),
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(top: index == 0 ? 8 : 12),
              child: _PartyCard(item: items[index]),
            ),
          ),
        );
      },
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.item});

  final _PartyFeedItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.isEmpty
        ? context.l10n.t('party.untitled')
        : item.title;
    final hostName = item.hostName.isEmpty
        ? context.l10n.t('party.username')
        : item.hostName;

    return Container(
      height: 218,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 122,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: _PartyImage(
                    url: item.coverUrl,
                    assetName: AppAssets.lanhuPartyCover,
                    width: double.infinity,
                    height: 122,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _AudienceBadge(text: item.onlineText),
                ),
                _JoinButton(label: context.l10n.t('party.join')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AvatarImage(url: item.avatarUrl),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  hostName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF282C2B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (item.isLive) ...[
                const SizedBox(width: 6),
                _LiveBadge(label: context.l10n.t('party.onLive')),
              ],
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const _ShareButton(),
            ],
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
  const _AvatarImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: _PartyImage(
        url: url,
        assetName: AppAssets.lanhuPartyAvatar,
        width: 22,
        height: 22,
      ),
    );
  }
}

class _AudienceBadge extends StatelessWidget {
  const _AudienceBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AudioBars(),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioBars extends StatelessWidget {
  const _AudioBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 9,
      height: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _AudioBar(height: 5),
          _AudioBar(height: 9),
          _AudioBar(height: 7),
        ],
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  const _AudioBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: height,
      decoration: BorderRadius.circular(
        1,
      ).toBoxDecoration(color: AppColors.textInverse),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 52,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textInverse,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 49,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Image.asset(AppAssets.lanhuPartyShare, width: 16, height: 16),
    );
  }
}

class _CreatePartyButton extends StatelessWidget {
  const _CreatePartyButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 17,
      bottom: 42,
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.t('profile.comingSoon'))),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.sendButton,
              boxShadow: AppShadows.button,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.textInverse,
              size: 34,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(17, 110, 17, 110),
      children: [
        Icon(Icons.hourglass_empty_rounded, color: AppColors.textPlaceholder),
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
          Center(
            child: TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: AppColors.primaryPink),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

extension on BorderRadius {
  BoxDecoration toBoxDecoration({required Color color}) {
    return BoxDecoration(color: color, borderRadius: this);
  }
}
