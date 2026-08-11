part of '../rank_page.dart';

class _RankPodiumView extends StatelessWidget {
  const _RankPodiumView({required this.entries, required this.category});

  final List<_RankEntry> entries;
  final _RankCategory category;

  _RankEntry? _entryAt(int index) {
    return entries.length > index ? entries[index] : null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 312,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_entryAt(1) != null)
            Positioned(
              left: -5,
              top: 82,
              child: _RankTopCard(
                entry: _entryAt(1)!,
                category: category,
                assetName: AppAssets.lanhuRankTop2Card,
                width: 128,
                height: 202,
                avatarSize: 62,
                avatarTop: 35,
                nameTop: 103,
                badgeTop: 126,
                valueTop: 163,
              ),
            ),
          if (_entryAt(2) != null)
            Positioned(
              right: 4,
              top: 82,
              child: _RankTopCard(
                entry: _entryAt(2)!,
                category: category,
                assetName: AppAssets.lanhuRankTop3Card,
                width: 106,
                height: 201,
                avatarSize: 56,
                avatarTop: 40,
                nameTop: 103,
                badgeTop: 126,
                valueTop: 163,
              ),
            ),
          if (_entryAt(0) != null)
            Positioned(
              left: 100,
              top: 0,
              child: _RankTopCard(
                entry: _entryAt(0)!,
                category: category,
                assetName: AppAssets.lanhuRankTop1Card,
                width: 174,
                height: 250,
                avatarSize: 78,
                avatarTop: 56,
                nameTop: 134,
                badgeTop: 157,
                valueTop: 201,
              ),
            ),
        ],
      ),
    );
  }
}

class _RankTopCard extends StatelessWidget {
  const _RankTopCard({
    required this.entry,
    required this.category,
    required this.assetName,
    required this.width,
    required this.height,
    required this.avatarSize,
    required this.avatarTop,
    required this.nameTop,
    required this.badgeTop,
    required this.valueTop,
  });

  final _RankEntry entry;
  final _RankCategory category;
  final String assetName;
  final double width;
  final double height;
  final double avatarSize;
  final double avatarTop;
  final double nameTop;
  final double badgeTop;
  final double valueTop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(child: Image.asset(assetName, fit: BoxFit.fill)),
          Positioned(
            top: avatarTop,
            child: _RankAvatar(entry: entry, size: avatarSize),
          ),
          Positioned(
            top: nameTop,
            left: 10,
            right: 10,
            child: Text(
              entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _topNameColor(entry.seqNo),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          Positioned(
            top: badgeTop,
            child: _RankBadges(
              entry: entry,
              category: category,
              compact: width < 140,
            ),
          ),
          Positioned(
            top: valueTop,
            child: _RankValueText(entry: entry, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _topNameColor(int rank) {
    return switch (rank) {
      2 => const Color.fromRGBO(253, 219, 220, 1),
      3 => const Color.fromRGBO(231, 242, 253, 1),
      _ => const Color.fromRGBO(255, 239, 91, 1),
    };
  }
}
