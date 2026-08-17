import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';
import '../profile_homepage_models.dart';

class ProfileHomepageHonorView extends StatelessWidget {
  const ProfileHomepageHonorView({
    super.key,
    required this.info,
    required this.scale,
  });

  final ProfileHomepageInfo info;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final honors = info.honors;
    return Padding(
      padding: EdgeInsets.fromLTRB(7 * scale, 0, 8 * scale, 0),
      child: Column(
        children: [
          _HonorHeader(count: honors.length, scale: scale),
          SizedBox(height: 10 * scale),
          Expanded(
            child: honors.isEmpty
                ? _EmptyHonor(scale: scale)
                : GridView.builder(
                    padding: EdgeInsets.only(bottom: 14 * scale),
                    physics: const BouncingScrollPhysics(),
                    itemCount: honors.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 6 * scale,
                      mainAxisSpacing: 8 * scale,
                      childAspectRatio: 85 / 119,
                    ),
                    itemBuilder: (context, index) {
                      return _HonorCard(honor: honors[index], scale: scale);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HonorHeader extends StatelessWidget {
  const _HonorHeader({required this.count, required this.scale});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.t('profile.achieved', {'count': '$count'}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color.fromRGBO(33, 33, 33, 0.4),
              fontSize: 15 * scale,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          Text(
            context.l10n.t('profile.myBadge'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color.fromRGBO(33, 33, 33, 0.4),
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

class _HonorCard extends StatelessWidget {
  const _HonorCard({required this.honor, required this.scale});

  final ProfileHomepageHonorItem honor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85 * scale,
      height: 119 * scale,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(253, 249, 237, 1),
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(
                  color: const Color.fromRGBO(255, 177, 108, 1),
                  width: 1.2 * scale,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8.5 * scale,
            top: 7 * scale,
            width: 68 * scale,
            height: 68 * scale,
            child: honor.icon.isEmpty
                ? const SizedBox.shrink()
                : CachedNetworkImage(
                    imageUrl: honor.icon,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
          ),
          Positioned(
            left: 8 * scale,
            right: 8 * scale,
            top: 85 * scale,
            child: const _HonorDivider(),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 91 * scale,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4 * scale),
              child: Text(
                honor.displayName(isChinese: context.l10n.isChinese),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromRGBO(207, 143, 23, 1),
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HonorDivider extends StatelessWidget {
  const _HonorDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(255, 177, 108, 0),
              Color.fromRGBO(255, 177, 108, 1),
              Color.fromRGBO(255, 177, 108, 1),
              Color.fromRGBO(255, 177, 108, 0),
            ],
            stops: [0, 0.3, 0.7, 1],
          ),
        ),
      ),
    );
  }
}

class _EmptyHonor extends StatelessWidget {
  const _EmptyHonor({required this.scale});

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
            context.l10n.t('profile.honorEmpty'),
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
