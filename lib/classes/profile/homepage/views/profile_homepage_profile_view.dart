import 'package:flutter/material.dart';

import '../../../../localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../profile_homepage_models.dart';

class ProfileHomepageProfileView extends StatelessWidget {
  const ProfileHomepageProfileView({
    super.key,
    required this.info,
    required this.scale,
  });

  final ProfileHomepageInfo info;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final user = info.user;
    final joinedDays = _joinedDays(user.createTime);

    return Padding(
      padding: EdgeInsets.fromLTRB(18 * scale, 0, 15 * scale, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.t('profile.joined'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              SizedBox(width: 14 * scale),
              Text(
                joinedDays == null
                    ? '--'
                    : context.l10n.t('profile.days', {'days': '$joinedDays'}),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 26 * scale),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                // width: 99 * scale,
                child: Text(
                  '${context.l10n.t('profile.bio')}:',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: 52 * scale),
                  padding: EdgeInsets.fromLTRB(
                    8 * scale,
                    8 * scale,
                    8 * scale,
                    8 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(6 * scale),
                  ),
                  child: Text(
                    _displayBio(context, user),
                    style: TextStyle(
                      color: const Color(0x4D212121),
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _displayBio(BuildContext context, ProfileHomepageUser user) {
  final bio = user.userDesc?.trim();
  if (bio == null || bio.isEmpty) return context.l10n.t('profile.bioEmpty');
  return bio;
}

int? _joinedDays(int? createTime) {
  if (createTime == null || createTime <= 0) return null;
  final created = DateTime.fromMillisecondsSinceEpoch(createTime);
  return DateTime.now().difference(created).inDays.abs();
}
