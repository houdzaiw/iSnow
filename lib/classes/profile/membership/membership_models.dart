import '../../../model/user_profile.dart';

Map<String, dynamic> membershipMap(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};
int membershipInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String membershipString(Object? value) => value is String ? value.trim() : '';
List<T> membershipList<T>(
  Object? value,
  T Function(Map<String, dynamic>) parse,
) => value is List
    ? value
          .whereType<Map>()
          .map((v) => parse(v.cast<String, dynamic>()))
          .toList(growable: false)
    : const [];

enum MembershipKind { vip, noble }

enum MembershipAction { buyVip, buyNoble, experienceCard, reward, unblock }

class MembershipGrade {
  const MembershipGrade({
    required this.id,
    required this.price,
    required this.days,
    this.discountPrice,
  });
  final int id, price, days;
  final int? discountPrice;
  bool get valid => id > 0 && price >= 0 && days > 0;
  int get payable =>
      discountPrice != null && discountPrice! >= 0 && discountPrice! < price
      ? discountPrice!
      : price;
  factory MembershipGrade.fromJson(Map<String, dynamic> j) => MembershipGrade(
    id: membershipInt(j['id']),
    price: j['price'] == null ? -1 : membershipInt(j['price']),
    days: membershipInt(j['day']),
    discountPrice: j['discountPrice'] == null
        ? null
        : membershipInt(j['discountPrice']),
  );
}

class MembershipPrivilege {
  const MembershipPrivilege({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.active,
    this.detail,
  });
  final int id;
  final String name, icon, description;
  final bool active;
  final MembershipPrivilegeDetail? detail;
  factory MembershipPrivilege.fromJson(Map<String, dynamic> j) =>
      MembershipPrivilege(
        id: membershipInt(j['id']),
        name: membershipString(j['name']),
        icon: membershipString(j['iconUrl']),
        description: membershipString(j['describe']),
        active: membershipInt(j['status']) == 0,
        detail: j['detail'] is Map
            ? MembershipPrivilegeDetail.fromJson(membershipMap(j['detail']))
            : null,
      );
}

class MembershipPrivilegeDetail {
  const MembershipPrivilegeDetail({
    required this.title,
    required this.icon,
    required this.description,
    required this.image,
  });
  final String title, icon, description, image;
  factory MembershipPrivilegeDetail.fromJson(Map<String, dynamic> j) =>
      MembershipPrivilegeDetail(
        title: membershipString(j['title']),
        icon: membershipString(j['iconUrl']),
        description: membershipString(j['describe']),
        image: membershipString(j['image']),
      );
}

class VipMembership {
  const VipMembership({
    required this.user,
    required this.grades,
    required this.levels,
    this.level = 0,
    this.status = 0,
    this.experience = 0,
    this.maxExperience = 0,
    this.endTime = 0,
    this.timeProtection = false,
  });
  final UserData user;
  final List<MembershipGrade> grades;
  final List<VipMembershipLevel> levels;
  final int level, status, experience, maxExperience, endTime;
  final bool timeProtection;
  bool get active => status == 1;
  Duration remaining(DateTime now) => timeProtection
      ? Duration.zero
      : Duration(
          milliseconds: (endTime - now.millisecondsSinceEpoch).clamp(
            0,
            8640000000000000,
          ),
        );
  factory VipMembership.fromJson(Map<String, dynamic> j) {
    final info = membershipMap(j['userVipInfo']);
    return VipMembership(
      user: UserData.fromJson(membershipMap(j['userInfo'])),
      grades: membershipList(
        j['grades'],
        MembershipGrade.fromJson,
      ).where((g) => g.valid).toList(growable: false),
      levels: membershipList(j['vipInfos'], VipMembershipLevel.fromJson),
      level: membershipInt(info['level']),
      status: membershipInt(info['status']),
      experience: membershipInt(info['experience']),
      maxExperience: membershipInt(info['maxExperience']),
      endTime: membershipInt(info['endTime']),
      timeProtection: info['timeProtection'] == true,
    );
  }
}

class VipMembershipLevel {
  const VipMembershipLevel({
    required this.level,
    required this.icon,
    required this.name,
    required this.animation,
    required this.preview,
    required this.activeCount,
    required this.total,
    required this.privileges,
  });
  final int level, activeCount, total;
  final String icon, name, animation, preview;
  final List<MembershipPrivilege> privileges;
  factory VipMembershipLevel.fromJson(Map<String, dynamic> j) =>
      VipMembershipLevel(
        level: membershipInt(j['level']),
        icon: membershipString(j['iconUrl']),
        name: membershipString(j['enName']),
        animation: membershipString(j['animationUrl']),
        preview: membershipString(j['showIconUrl']),
        activeCount: membershipInt(j['number']),
        total: membershipInt(j['total']),
        privileges: membershipList(
          j['privilegeInfoVOS'],
          MembershipPrivilege.fromJson,
        ),
      );
}

class NobleMembership {
  const NobleMembership({
    required this.id,
    required this.name,
    required this.icon,
    required this.animation,
    required this.preview,
    required this.enabled,
    required this.grades,
    required this.privileges,
    this.expiresAt,
  });
  final int id;
  final String name, icon, animation, preview;
  final bool enabled;
  final int? expiresAt;
  final List<MembershipGrade> grades;
  final List<MembershipPrivilege> privileges;
  bool get owned => expiresAt != null;
  Duration remaining(DateTime now) => Duration(
    milliseconds: ((expiresAt ?? 0) * 1000 - now.millisecondsSinceEpoch).clamp(
      0,
      8640000000000000,
    ),
  );
  factory NobleMembership.fromJson(Map<String, dynamic> j) => NobleMembership(
    id: membershipInt(j['id']),
    name: membershipString(j['name']),
    icon: membershipString(j['iconUrl']),
    animation: membershipString(j['animationUrl']),
    preview: membershipString(j['mp4Url']),
    enabled: j['status'] != null && membershipInt(j['status']) == 0,
    expiresAt: j['userInfo'] is Map
        ? membershipInt(membershipMap(j['userInfo'])['remainTime'])
        : null,
    grades: membershipList(
      j['grades'],
      MembershipGrade.fromJson,
    ).where((g) => g.valid).toList(growable: false),
    privileges: membershipList(j['privileges'], MembershipPrivilege.fromJson),
  );
}

class MembershipRecipient {
  const MembershipRecipient({
    required this.user,
    required this.blocked,
    required this.normal,
    this.blockStatus = 0,
    this.unblockCoins = 0,
  });
  final UserData user;
  final bool blocked, normal;
  final int blockStatus, unblockCoins;
  factory MembershipRecipient.fromHomepage(Map<String, dynamic> j) {
    final raw = membershipMap(j['userBaseInfo']);
    return MembershipRecipient(
      user: UserData.fromJson(raw),
      blocked: raw['blocked'] == true,
      normal:
          nadyLoginStatusFromJson(raw['userStatus']) == NadyLoginStatus.normal,
    );
  }
  factory MembershipRecipient.fromBlock(Map<String, dynamic> j) =>
      MembershipRecipient(
        user: UserData.fromJson(membershipMap(j['userInfo'])),
        blocked: membershipInt(j['status']) == 1,
        normal: true,
        blockStatus: membershipInt(j['status']),
        unblockCoins: membershipInt(j['coins']),
      );
}

class VipSettingItem {
  const VipSettingItem({
    required this.id,
    required this.name,
    required this.limit,
    required this.open,
    this.type = '',
  });
  final int id, limit;
  final String name;
  final String type;
  final bool open;
  factory VipSettingItem.fromJson(Map<String, dynamic> j) => VipSettingItem(
    id: membershipInt(j['id']),
    name: membershipString(j['enName']),
    limit: membershipInt(j['limitLevel']),
    open: j['open'] == true,
    type: membershipString(j['type']),
  );
}

class NobleReward {
  const NobleReward({
    required this.id,
    required this.name,
    required this.icon,
    required this.days,
    required this.limit,
    required this.sent,
  });
  final int id, days, limit, sent;
  final String name, icon;
  int get remaining => (limit - sent).clamp(0, limit < 0 ? 0 : limit);
  factory NobleReward.fromJson(Map<String, dynamic> j) => NobleReward(
    id: membershipInt(j['aristocracyId']),
    name: membershipString(j['enName']),
    icon: membershipString(j['icon']),
    days: membershipInt(j['day']),
    limit: membershipInt(j['limitCount']),
    sent: membershipInt(j['sendCount']),
  );
}

class NobleTitle {
  const NobleTitle({
    required this.id,
    required this.name,
    required this.image,
    this.owner,
  });
  final int id;
  final String name, image;
  final UserData? owner;
  factory NobleTitle.fromJson(Map<String, dynamic> j) => NobleTitle(
    id: membershipInt(j['id']),
    name: membershipString(j['englishName']),
    image: membershipString(j['englishImageUrl']),
    owner: j['userSimple'] is Map
        ? UserData.fromJson(membershipMap(j['userSimple']))
        : null,
  );
}

class MembershipRecord {
  const MembershipRecord({
    required this.key,
    required this.title,
    required this.time,
    required this.amount,
    this.icon = '',
    this.source,
  });
  final String key, title, icon;
  final int time, amount;
  final int? source;
  DateTime? get occurredAt {
    if (time <= 0) return null;
    final millis = time < 100000000000 ? time * 1000 : time;
    if (millis > 8640000000000000) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  factory MembershipRecord.vip(Map<String, dynamic> j) => MembershipRecord(
    key: '${j['time']}:${j['type']}:${j['value']}:${j['source']}',
    title: membershipString(j['source']),
    time: membershipInt(j['time']),
    amount: membershipInt(j['value']),
  );
  factory MembershipRecord.noble(Map<String, dynamic> j) => MembershipRecord(
    key: '${j['id']}',
    title: '',
    time: membershipInt(j['getTime']),
    amount: membershipInt(j['effectiveDays']),
    icon: membershipString(j['iconUrl']),
    source: membershipInt(j['source']),
  );
}

class MembershipRecordPage {
  const MembershipRecordPage(this.items, this.total);
  final List<MembershipRecord> items;
  final int total;
}
