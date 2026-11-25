import '../../../model/user_profile.dart';
import '../membership/membership_models.dart';

class HonorStage {
  const HonorStage({
    required this.stage,
    required this.description,
    required this.englishDescription,
    required this.icon,
    required this.animation,
    this.expireTime,
    this.obtainTime,
  });
  final int stage;
  final String description, englishDescription, icon, animation;
  final DateTime? expireTime, obtainTime;
  String text(String language) => language == 'zh' && description.isNotEmpty
      ? description
      : englishDescription.isNotEmpty
      ? englishDescription
      : description;
  static DateTime? date(Object? value) {
    if (value == null) return null;
    final number = num.tryParse('$value');
    if (number != null) {
      if (!number.isFinite || number <= 0) return null;
      final milliseconds = number < 100000000000 ? number * 1000 : number;
      return milliseconds > 8640000000000000
          ? null
          : DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt());
    }
    return DateTime.tryParse('$value');
  }

  factory HonorStage.fromJson(Map<String, dynamic> j) => HonorStage(
    stage: membershipInt(j['stage']),
    description: membershipString(j['desc']),
    englishDescription: membershipString(j['descEn']),
    icon: membershipString(j['icon']),
    animation: membershipString(j['animation']),
    expireTime: date(j['expireTime']),
    obtainTime: date(j['obtainTime']),
  );
}

class HonorBadge {
  const HonorBadge({
    required this.id,
    required this.type,
    required this.name,
    required this.englishName,
    required this.currentStage,
    required this.stages,
    this.giftIcon = '',
  });
  final String id, name, englishName, giftIcon;
  final int type, currentStage;
  final List<HonorStage> stages;
  String title(String language) => language == 'zh' && name.isNotEmpty
      ? name
      : englishName.isNotEmpty
      ? englishName
      : name;
  HonorStage? get ownedStage => currentStage > 0
      ? stages.where((s) => s.stage == currentStage).firstOrNull
      : null;
  HonorStage? get displayStage => ownedStage ?? stages.firstOrNull;
  bool wearable(DateTime now) =>
      ownedStage != null &&
      (ownedStage!.expireTime == null || ownedStage!.expireTime!.isAfter(now));
  factory HonorBadge.fromJson(Map<String, dynamic> j) => HonorBadge(
    id: membershipString(j['id']),
    type: membershipInt(j['medalType']),
    name: membershipString(j['medalName']),
    englishName: membershipString(j['medalNameEn']),
    giftIcon: membershipString(j['giftIcon']),
    currentStage: membershipInt(j['currentStage']),
    stages: membershipList(j['medalStages'], HonorStage.fromJson)
      ..sort((a, b) => a.stage.compareTo(b.stage)),
  );
}

class HonorEquipment {
  const HonorEquipment(this.user, this.limit);
  final UserData user;
  final int limit;
  List<String> get ids => user.wornMedals
      .map((m) => m.id)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();
  static int nobleLimit(int level) => switch (level) {
    4 => 6,
    5 => 8,
    6 => 10,
    _ => 3,
  };
}
