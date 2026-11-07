import 'dart:async';

import 'package:project/classes/profile/membership/membership_repository.dart';
import 'package:project/classes/profile/membership/membership_session.dart';
import 'package:project/manager/http_api.dart';
import 'package:project/theme/app_assets.dart';

final membershipNow = DateTime.utc(2026, 11, 3, 12);
const membershipAccount = (uid: 10, token: 'fake-token', generation: 1);
typedef MembershipCall = ({
  String method,
  String path,
  Map<String, dynamic> arguments,
});
Map<String, dynamic> membershipUser({
  int uid = 10,
  int vip = 6,
  int noble = 6,
}) => {
  'uid': uid,
  'userNo': uid + 10000,
  'nick': 'A very long membership nickname',
  'avatar': AppAssets.membershipVipBadge,
  'userStatus': 'USER_STATUS_NORMAL',
  'blocked': false,
  'userLevel': {'vipLevel': vip, 'aristocracyLevel': noble},
};
Map<String, dynamic> membershipPerk(int id) => {
  'id': id,
  'name': 'Exclusive membership privilege $id',
  'iconUrl': AppAssets.membershipVipBadge,
  'status': id == 1 ? 0 : 1,
  'describe': 'Privilege description',
  'detail': {
    'id': id,
    'title': 'Privilege details',
    'iconUrl': AppAssets.membershipVipBadge,
    'describe': 'Paragraph one.\nParagraph two.',
    'image': AppAssets.membershipVipBadge,
  },
};
Map<String, dynamic> membershipVip({int level = 6, int noble = 6}) => {
  'userInfo': membershipUser(vip: level, noble: noble),
  'userVipInfo': {
    'vipIcon': AppAssets.membershipVipBadge,
    'level': level,
    'experience': 650,
    'maxExperience': 1000,
    'endTime': membershipNow
        .add(const Duration(days: 10))
        .millisecondsSinceEpoch,
    'timeProtection': false,
    'status': level > 0 ? 1 : 0,
  },
  'grades': [
    for (var id = 1; id <= 3; id++)
      {'id': id, 'price': id * 100, 'day': id * 7},
  ],
  'vipInfos': [
    for (var level = 1; level <= 6; level++)
      {
        'level': level,
        'iconUrl': AppAssets.membershipVipBadge,
        'enName': 'VIP $level',
        'arName': '',
        'animationUrl': '',
        'showIconUrl': '',
        'number': 1,
        'total': 3,
        'privilegeInfoVOS': [
          for (var id = 1; id <= 3; id++) membershipPerk(id),
        ],
      },
  ],
};
List<Map<String, dynamic>> membershipNobles({int owned = 6}) => [
  for (var id = 1; id <= 6; id++)
    {
      'id': id,
      'name': ['Baron', 'Count', 'Marquis', 'Duke', 'King', 'Emperor'][id - 1],
      'iconUrl': AppAssets.membershipNobleBadge,
      'animationUrl': '',
      'mp4Url': '',
      'status': 0,
      'userInfo': id == owned
          ? {
              'remainTime':
                  membershipNow
                      .add(const Duration(days: 8))
                      .millisecondsSinceEpoch ~/
                  1000,
            }
          : null,
      'grades': [
        {'id': id * 10, 'price': 200, 'discountPrice': 150, 'day': 7},
        {'id': id * 10 + 1, 'price': 500, 'discountPrice': 450, 'day': 30},
      ],
      'privileges': [for (var id = 1; id <= 3; id++) membershipPerk(id)],
    },
];

class MembershipApiFake implements MembershipApi {
  MembershipApiFake() {
    responses.addAll({
      HttpApi.membershipVip: membershipVip(),
      HttpApi.membershipNoble: membershipNobles(),
      HttpApi.membershipVipExperienceCard: 2,
      HttpApi.userVipSetting: {
        'invisibleEnter': {
          'id': 1,
          'limitLevel': 3,
          'enName': 'Invisible entry',
          'open': false,
        },
        'invisibleVisitor': {
          'id': 2,
          'limitLevel': 3,
          'enName': 'Invisible visit',
          'open': true,
        },
        'noDisturb': {
          'id': 3,
          'limitLevel': 5,
          'enName': 'Do not disturb',
          'open': true,
        },
      },
      HttpApi.userHomepage: {
        'userBaseInfo': membershipUser(uid: 20, vip: 0, noble: 0),
      },
      HttpApi.membershipVipBlock: {
        'status': 1,
        'coins': 50,
        'userInfo': membershipUser(uid: 20),
      },
      HttpApi.membershipNobleRewards: {
        'infos': [
          {
            'aristocracyId': 2,
            'icon': AppAssets.membershipNobleBadge,
            'enName': 'Count',
            'arName': '',
            'day': 1,
            'limitCount': 5,
            'sendCount': 1,
          },
        ],
      },
      HttpApi.membershipNobleTitles: [
        {
          'id': 1,
          'englishName': 'King of stars',
          'englishImageUrl': AppAssets.membershipNobleBadge,
          'userSimple': null,
        },
      ],
      HttpApi.membershipVipHistory: {
        'list': [
          {
            'type': 1,
            'value': 100,
            'time': membershipNow.millisecondsSinceEpoch,
            'source': 'VIP activation',
          },
        ],
        'total': 1,
      },
      HttpApi.membershipNobleHistory: {
        'list': [
          {
            'id': 1,
            'source': 0,
            'getTime': membershipNow.millisecondsSinceEpoch,
            'effectiveDays': 7,
            'iconUrl': AppAssets.membershipNobleBadge,
          },
        ],
        'total': 1,
      },
    });
  }
  final Map<String, Object?> responses = {};
  final Map<String, Object> failures = {};
  final List<MembershipCall> calls = [];
  String? heldPath;
  Completer<void>? gate;
  void Function(String)? onSubmit;
  int count(String path, {String? method}) => calls
      .where((c) => c.path == path && (method == null || c.method == method))
      .length;
  @override
  Future<Object?> get(String path, [Map<String, dynamic>? query]) async {
    calls.add((method: 'GET', path: path, arguments: {...?query}));
    final result = responses[path];
    if (path == heldPath) await gate?.future;
    if (failures[path] case final error?) throw error;
    return {'code': 200, 'data': result};
  }

  @override
  Future<Object?> post(String path, Map<String, dynamic> body) async {
    calls.add((method: 'POST', path: path, arguments: {...body}));
    if (path == heldPath) await gate?.future;
    if (failures[path] case final error?) throw error;
    onSubmit?.call(path);
    return {'code': 200, 'data': null};
  }
}

class MembershipFixture {
  MembershipFixture() {
    repository = MembershipRepository(
      api,
      identity: () async => account,
      refreshUser: () async {
        userRefreshes++;
        if (failRefresh) throw StateError('refresh');
      },
      refreshBalance: () async {
        balanceRefreshes++;
      },
    );
  }
  final api = MembershipApiFake();
  late final MembershipRepository repository;
  MembershipIdentity account = membershipAccount;
  int userRefreshes = 0, balanceRefreshes = 0;
  bool failRefresh = false;
}
