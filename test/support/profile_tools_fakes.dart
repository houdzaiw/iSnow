import 'dart:async';

import 'package:project/classes/profile/membership/membership_repository.dart';
import 'package:project/classes/profile/tools/profile_feature_repository.dart';
import 'package:project/manager/http_api.dart';

class ProfileToolsFake implements MembershipApi {
  ProfileToolsFake() {
    features = ProfileFeatureRepository(
      this,
      identity: () async => account,
      refresh: () async {
        refreshes++;
        if (failRefresh) throw StateError('refresh failed');
      },
    );
    data.addAll({
      HttpApi.profileClientInit: {'isVersionAuditing': false},
      HttpApi.homeResourceBanner: {'list': [], 'total': 0},
      HttpApi.profileAgentPurseVisible: true,
      HttpApi.storeNewProducts: {
        'newProductFlagItemList': [
          {'type': 3, 'markNewProduct': 1},
        ],
      },
      HttpApi.storeProducts: {
        'shopPropList': [product()],
        'totalPage': 2,
      },
      HttpApi.walletPurse: {'coin': 1000, 'diamond': 200},
      HttpApi.userHomepage: {
        'info': {
          'userBaseInfo': {
            'uid': 88,
            'userNo': 10088,
            'nick': 'Receiver',
            'userStatus': 'USER_STATUS_NORMAL',
          },
        },
      },
      HttpApi.profileProps: [prop()],
      HttpApi.dailySignInfo: sign(),
      HttpApi.dailySign: true,
      HttpApi.dailyMissions: [
        {
          'missionType': 1,
          'typeDesc': 'Daily tasks',
          'missionInfos': [task()],
        },
      ],
      HttpApi.dailyClaim: [reward()],
      HttpApi.profileAccountBindings: [
        {'bandingType': 5, 'isBanding': false},
      ],
      HttpApi.supportedCountry: [
        {'name': 'Saudi Arabia', 'isoCode': 'SA', 'dialCode': '+966'},
      ],
      HttpApi.hasUser: {'hasUser': false},
      HttpApi.myUserInfo: {
        'userBaseInfo': {
          'uid': 10,
          'nick': 'Owner',
          'oauthToken': 'must-not-leak',
        },
      },
    });
  }
  late final ProfileFeatureRepository features;
  MembershipIdentity account = (uid: 10, token: 'fixture', generation: 1);
  final data = <String, Object?>{};
  final errors = <String, Object>{};
  final envelopes = <String, Map<String, dynamic>>{};
  final calls = <({String method, String path, Map<String, dynamic> params})>[];
  String? held;
  Completer<void>? gate;
  void Function(String, Map<String, dynamic>)? onPost;
  int refreshes = 0;
  bool failRefresh = false;
  int count(String path, {String? method}) => calls
      .where((c) => c.path == path && (method == null || c.method == method))
      .length;
  Future<Object?> _call(
    String method,
    String path,
    Map<String, dynamic> params,
  ) async {
    calls.add((method: method, path: path, params: {...params}));
    final result = data[path];
    if (path == held) await gate?.future;
    if (errors[path] case final error?) throw error;
    if (method == 'POST') onPost?.call(path, params);
    return envelopes[path] ?? {'code': 200, 'data': result};
  }

  @override
  Future<Object?> get(String path, [Map<String, dynamic>? query]) =>
      _call('GET', path, query ?? {});
  @override
  Future<Object?> post(String path, Map<String, dynamic> body) =>
      _call('POST', path, body);

  static Map<String, dynamic> product({
    int id = 1,
    int type = 3,
    int currency = 1,
    int price = 50,
  }) => {
    'id': id,
    'type': type,
    'name': 'Frame $id',
    'icon': '',
    'markNewProduct': 1,
    'priceList': [
      {'currencyType': currency, 'day': 7, 'price': price},
    ],
  };
  static Map<String, dynamic> prop({int id = 1, int state = 1, int? expiry}) =>
      {
        'id': id,
        'goodsId': 55,
        'goodsType': 3,
        'name': 'Owned frame',
        'icon': '',
        'expireTime': expiry ?? DateTime.utc(2030).millisecondsSinceEpoch,
        'state': state,
      };
  static Map<String, dynamic> reward() => {
    'enName': 'Coins',
    'prizeIcon': '',
    'amount': 5,
  };
  static Map<String, dynamic> sign({bool signed = false}) => {
    'continuousDays': 2,
    'signInfos': [
      {
        'dayIdx': 3,
        'thisDay': true,
        'signed': signed,
        'rewardVOs': [reward()],
      },
    ],
  };
  static Map<String, dynamic> task({int id = 1, int status = 2}) => {
    'missionId': id,
    'missionName': 'Spend time in room',
    'missionDesc': 'Visit a room',
    'icon': '',
    'status': status,
    'rate': 5,
    'taskVal': 5,
    'rewardVOs': [reward()],
  };
}
