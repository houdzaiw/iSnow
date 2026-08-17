import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../profile_homepage_models.dart';

class ProfileHomepageGiftsView extends StatelessWidget {
  const ProfileHomepageGiftsView({
    super.key,
    required this.info,
    required this.scale,
  });

  final ProfileHomepageInfo info;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final giftWall = info.giftWall;
    final gifts = giftWall.gifts;
    final total = giftWall.total > 0 ? giftWall.total : gifts.length;
    final receive = giftWall.receive;

    return Padding(
      padding: EdgeInsets.fromLTRB(18 * scale, 0, 15 * scale, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GiftWallHeader(
            title: context.l10n.t('profile.giftValue'),
            receive: receive,
            total: total,
            scale: scale,
          ),
          SizedBox(height: 14 * scale),
          Expanded(
            child: gifts.isEmpty
                ? _EmptyGiftWall(scale: scale)
                : GridView.builder(
                    padding: EdgeInsets.only(bottom: 14 * scale),
                    physics: const BouncingScrollPhysics(),
                    itemCount: gifts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8 * scale,
                      mainAxisSpacing: 14 * scale,
                      childAspectRatio: 72 / 94,
                    ),
                    itemBuilder: (context, index) {
                      return _GiftWallItemCard(
                        item: gifts[index],
                        scale: scale,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GiftWallHeader extends StatelessWidget {
  const _GiftWallHeader({
    required this.title,
    required this.receive,
    required this.total,
    required this.scale,
  });

  final String title;
  final int receive;
  final int total;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22 * scale,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          SizedBox(width: 8 * scale),
          Text(
            total <= 0 ? _formatCompactCount(receive) : '$receive/$total',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftWallItemCard extends StatelessWidget {
  const _GiftWallItemCard({required this.item, required this.scale});

  final ProfileHomepageGiftWallItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 64 * scale,
          height: 64 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8 * scale),
                    child: item.icon.isEmpty
                        ? const SizedBox.shrink()
                        : CachedNetworkImage(
                            imageUrl: item.icon,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                  ),
                ),
              ),
              if (item.giftCount > 0)
                Positioned(
                  right: -3 * scale,
                  bottom: -3 * scale,
                  child: _GiftCountBadge(count: item.giftCount, scale: scale),
                ),
            ],
          ),
        ),
        SizedBox(height: 7 * scale),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.6),
            fontSize: 11 * scale,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _GiftCountBadge extends StatelessWidget {
  const _GiftCountBadge({required this.count, required this.scale});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 22 * scale),
      height: 18 * scale,
      padding: EdgeInsets.symmetric(horizontal: 5 * scale),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.sendButton,
        borderRadius: BorderRadius.circular(98 * scale),
        border: Border.all(color: Colors.white, width: 1.5 * scale),
      ),
      child: Text(
        'x${_formatCompactCount(count)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 * scale,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _EmptyGiftWall extends StatelessWidget {
  const _EmptyGiftWall({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 20 * scale, bottom: 14 * scale),
      children: [
        Container(
          width: double.infinity,
          height: 70 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Text(
            context.l10n.t('profile.relationsEmpty'),
            style: TextStyle(
              color: const Color(0x4D212121),
              fontSize: 15 * scale,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCompactCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}
