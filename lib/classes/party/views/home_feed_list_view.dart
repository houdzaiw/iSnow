part of '../party_page.dart';

class _HomeFeedListView extends StatelessWidget {
  const _HomeFeedListView({
    required this.tabController,
    required this.tabs,
    required this.rooms,
    required this.onRefresh,
  });

  final TabController tabController;
  final List<_CountryFilterTab> tabs;
  final List<_HomeRoomItem> rooms;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ExtendedTabBarView(
      controller: tabController,
      cacheExtent: 1,
      children: [
        for (final tab in tabs)
          _HomeRoomGrid(
            key: ValueKey(tab.countryCode ?? 'hot'),
            rooms: rooms,
            onRefresh: onRefresh,
          ),
      ],
    );
  }
}

class _HomeRoomGrid extends StatelessWidget {
  const _HomeRoomGrid({
    super.key,
    required this.rooms,
    required this.onRefresh,
  });

  final List<_HomeRoomItem> rooms;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryPink,
      onRefresh: onRefresh,
      child: rooms.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: _StateList(text: context.l10n.t('home.roomsEmpty')),
                ),
              ],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
              itemCount: rooms.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 8,
                childAspectRatio: 175 / 188,
              ),
              itemBuilder: (context, index) {
                return _HomeRoomCard(room: rooms[index]);
              },
            ),
    );
  }
}

class _HomeRoomCard extends StatelessWidget {
  const _HomeRoomCard({required this.room});

  final _HomeRoomItem room;

  @override
  Widget build(BuildContext context) {
    final tagType = room.tagType;
    final roomId = room.roomId;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: roomId == null || roomId.isEmpty
            ? null
            : () =>
                  context.pushNamed('room', pathParameters: {'roomId': roomId}),
        child: Stack(
          children: [
            Positioned.fill(
              child: _PartyImage(
                url: room.cover,
                assetName: AppAssets.lanhuHomeRoomBanner,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            const Positioned.fill(child: _RoomCardGradient()),
            if (tagType != null)
              Positioned(
                top: 12,
                right: 8,
                child: _RoomTag(
                  label: _homeRoomTagLabel(tagType),
                  assetName: _homeRoomTagAsset(tagType),
                ),
              ),
            Positioned(
              left: 13,
              bottom: 45,
              child: _RoomCountryBadge(countryCode: room.countryCode),
            ),
            Positioned(
              right: 10,
              bottom: 45,
              child: _RoomOnlineBadge(text: room.onlineText),
            ),
            Positioned(
              left: 13,
              right: 8,
              bottom: 18,
              child: _RoomTitle(title: room.title),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCardGradient extends StatelessWidget {
  const _RoomCardGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0),
            Color.fromRGBO(0, 0, 0, 0.08),
            Color.fromRGBO(0, 0, 0, 0.56),
          ],
          stops: [0, 0.58, 1],
        ),
      ),
    );
  }
}

class _RoomTag extends StatelessWidget {
  const _RoomTag({required this.label, required this.assetName});

  final String label;
  final String assetName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetName, width: 22, height: 17),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCountryBadge extends StatelessWidget {
  const _RoomCountryBadge({required this.countryCode});

  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    final code = countryCode?.toUpperCase();
    return Container(
      width: 31,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: code == null || code.isEmpty
          ? const DecoratedBox(
              decoration: BoxDecoration(color: AppColors.avatarPlaceholder),
            )
          : CountryFlag.fromCountryCode(
              code,
              theme: ImageTheme(
                width: 31,
                height: 18,
                shape: RoundedRectangle(4),
              ),
            ),
    );
  }
}

class _RoomOnlineBadge extends StatelessWidget {
  const _RoomOnlineBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _HomeAudioBars(),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textInverse,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HomeAudioBars extends StatelessWidget {
  const _HomeAudioBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _HomeAudioBar(height: 8),
          _HomeAudioBar(height: 14),
          _HomeAudioBar(height: 10),
        ],
      ),
    );
  }
}

class _HomeAudioBar extends StatelessWidget {
  const _HomeAudioBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BorderRadius.circular(
        2,
      ).toBoxDecoration(color: const Color(0xFFE13BFF)),
    );
  }
}

class _RoomTitle extends StatelessWidget {
  const _RoomTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.isEmpty
        ? context.l10n.t('party.untitled')
        : title;
    return Row(
      children: [
        const Icon(Icons.local_florist, color: Color(0xFFFF79A7), size: 16),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String _homeRoomTagLabel(_HomeRoomTagType type) {
  return switch (type) {
    _HomeRoomTagType.pk => 'PK',
    _HomeRoomTagType.lucky => 'Lucky',
    _HomeRoomTagType.bigWin => 'Big Win',
  };
}

String _homeRoomTagAsset(_HomeRoomTagType type) {
  return switch (type) {
    _HomeRoomTagType.pk => AppAssets.lanhuHomeBadgePk,
    _HomeRoomTagType.lucky => AppAssets.lanhuHomeBadgeMining,
    _HomeRoomTagType.bigWin => AppAssets.lanhuHomeBadgeBigWin,
  };
}
