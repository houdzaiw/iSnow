import '../tools/profile_feature_repository.dart';

class DailyRewardItem {
  const DailyRewardItem(this.name, this.icon, this.amount);
  final String name, icon;
  final int amount;
  factory DailyRewardItem.fromJson(Map<String, dynamic> j) => DailyRewardItem(
    membershipString(j['enName']),
    membershipString(j['prizeIcon']),
    membershipInt(j['amount']),
  );
}

class SignDay {
  const SignDay(this.day, this.signed, this.today, this.rewards);
  final int day;
  final bool signed, today;
  final List<DailyRewardItem> rewards;
  factory SignDay.fromJson(Map<String, dynamic> j) => SignDay(
    membershipInt(j['dayIdx']),
    j['signed'] == true,
    j['thisDay'] == true,
    membershipList(j['rewardVOs'], DailyRewardItem.fromJson),
  );
}

class DailySignInfo {
  const DailySignInfo(this.days, this.items, this.nobleReward);
  final int days;
  final List<SignDay> items;
  final DailyRewardItem? nobleReward;
  bool get canSign => items.any((d) => d.today && !d.signed);
  factory DailySignInfo.fromJson(Map<String, dynamic> j) => DailySignInfo(
    membershipInt(j['continuousDays']),
    membershipList(j['signInfos'], SignDay.fromJson),
    membershipMap(j['aristocracySignInfo'])['rewardVOs'] is Map
        ? DailyRewardItem.fromJson(
            membershipMap(membershipMap(j['aristocracySignInfo'])['rewardVOs']),
          )
        : null,
  );
}

class DailyTask {
  const DailyTask(
    this.id,
    this.name,
    this.description,
    this.icon,
    this.status,
    this.progress,
    this.total,
    this.rewards,
  );
  final int id, status, progress, total;
  final String name, description, icon;
  final List<DailyRewardItem> rewards;
  factory DailyTask.fromJson(Map<String, dynamic> j) => DailyTask(
    membershipInt(j['missionId']),
    membershipString(j['missionName']),
    membershipString(j['missionDesc']),
    membershipString(j['icon']),
    membershipInt(j['status']),
    membershipInt(j['rate']),
    membershipInt(j['taskVal']),
    membershipList(j['rewardVOs'], DailyRewardItem.fromJson),
  );
}

class DailyTaskGroup {
  const DailyTaskGroup(this.title, this.items);
  final String title;
  final List<DailyTask> items;
  factory DailyTaskGroup.fromJson(Map<String, dynamic> j) => DailyTaskGroup(
    membershipString(j['typeDesc']),
    membershipList(j['missionInfos'], DailyTask.fromJson),
  );
}

class DailyOutcome {
  const DailyOutcome(this.rewards, this.refreshed);
  final List<DailyRewardItem> rewards;
  final bool refreshed;
}

class DailyRoomTarget {
  const DailyRoomTarget(this.roomId, this.uid);
  final String roomId;
  final int uid;
}

enum DailyDestinationKind { room, createRoom, binding, unavailable }

class DailyDestination {
  const DailyDestination(this.kind, {this.room, this.lobbyType = 0});
  final DailyDestinationKind kind;
  final DailyRoomTarget? room;
  final int lobbyType;
}
