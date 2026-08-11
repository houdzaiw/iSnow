part of '../rank_page.dart';

class _RankListView extends StatelessWidget {
  const _RankListView({required this.entries, required this.category});

  final List<_RankEntry> entries;
  final _RankCategory category;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox(height: 24);
    }

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 0, 6, 6),
            child: _RankListTile(entry: entry, category: category),
          ),
      ],
    );
  }
}

class _RankListTile extends StatelessWidget {
  const _RankListTile({required this.entry, required this.category});

  final _RankEntry entry;
  final _RankCategory category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 61,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AppAssets.lanhuRankListItem, fit: BoxFit.fill),
          ),
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  entry.seqNo == 0 ? '-' : '${entry.seqNo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _RankAvatar(entry: entry, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _RankBadges(
                      entry: entry,
                      category: category,
                      compact: true,
                    ),
                  ],
                ),
              ),
              _RankValueText(entry: entry, fontSize: 12),
              const SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankMeBar extends StatelessWidget {
  const _RankMeBar({required this.entry, required this.category});

  final _RankEntry entry;
  final _RankCategory category;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 82,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 70,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      AppAssets.lanhuRankMeBar,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 58,
                        child: Text(
                          entry.seqNo == 0 ? '-' : '${entry.seqNo}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _RankAvatar(entry: entry, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _RankBadges(
                              entry: entry,
                              category: category,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                      _RankValueText(entry: entry, fontSize: 14),
                      const SizedBox(width: 28),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
