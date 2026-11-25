import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../manager/http_api.dart';
import '../../manager/profile_media_manager.dart';
import '../../manager/room_share_manager.dart';
import '../../model/room_share_models.dart';
import '../../model/server_response.dart';
import '../oauth/provider/login_provider.dart';
import '../profile/tools/profile_feature_repository.dart';
import '../profile/tools/profile_menu_repository.dart';
import '../profile/tools/profile_tools_config.dart';
import '../room/gift/recharge/room_first_recharge_repository.dart';
import '../room/room_repository.dart';
import '../wallet/wallet_models.dart';
import '../wallet/wallet_repository.dart';
import '../wallet/wallet_payment_service.dart';

final profileWebActionsProvider = Provider(
  (ref) => ProfileWebActions(
    features: ref.watch(profileFeatureRepositoryProvider),
    menu: ref.watch(profileMenuRepositoryProvider),
    share: ref.watch(roomShareManagerProvider),
    media: ref.watch(profileMediaManagerProvider),
    wallet: ref.watch(walletRepositoryProvider),
    payment: ref.watch(walletPaymentServiceProvider),
    firstRecharge: ref.watch(roomFirstRechargeRepositoryProvider),
    roomId: () =>
        ref.read(roomRepositoryProvider).roomState.currentRoomId ?? '',
  ),
);

/// Business and platform actions for trusted profile H5 pages; View owns routes.
class ProfileWebActions {
  ProfileWebActions({
    required this.features,
    required this.menu,
    required this.share,
    required this.media,
    required this.wallet,
    required this.payment,
    required this.firstRecharge,
    required this.roomId,
    Future<String> Function(String)? upload,
  }) : _upload =
           upload ??
           ((path) =>
               LoginProvider().uploadAvatarFile(path, returnFullUrl: true));
  final ProfileFeatureRepository features;
  final ProfileMenuRepository menu;
  final RoomShareManager share;
  final ProfileMediaManager media;
  final WalletRepository wallet;
  final WalletPaymentService payment;
  final RoomFirstRechargeRepository firstRecharge;
  final String Function() roomId;
  final Future<String> Function(String) _upload;
  void authorize(Uri source) {
    if (!const ProfileToolsConfig().trusted(source)) {
      throw const NadyApiException(message: 'Untrusted page');
    }
  }

  Future<Map<String, dynamic>> userInfo() async {
    final data = membershipMap(
      await features.request('GET', HttpApi.myUserInfo),
    );
    Object? sanitize(Object? value) => value is Map
        ? {
            for (final e in value.entries)
              if (!RegExp(
                r'token|password|passwd|secret',
                caseSensitive: false,
              ).hasMatch('${e.key}'))
                '${e.key}': sanitize(e.value),
          }
        : value is List
        ? value.map(sanitize).toList()
        : value;
    return {'userInfo': sanitize(data), 'currentRoomID': roomId()};
  }

  Future<bool> auditing() async =>
      (await menu.client())['isVersionAuditing'] == true;
  Future<String?> ownRoom() async {
    final data = membershipMap(
      await features.request('GET', HttpApi.myUserInfo),
    );
    final id = '${membershipMap(data['userBaseInfo'])['roomId'] ?? ''}'.trim();
    return id.isEmpty || id == '0' ? null : id;
  }

  Future<String?> selectPicture({
    required bool camera,
    required bool Function() isCurrent,
  }) async {
    final account = await features.identity();
    if (!isCurrent()) return null;
    final path = await media.pick(camera: camera);
    await features.check(account);
    if (!isCurrent() || path == null) return null;
    final url = await _upload(path);
    await features.check(account);
    return isCurrent() ? url : null;
  }

  Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.userInfo.isNotEmpty ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<RoomShareOutcome?> shareContent(
    String name,
    Map<String, dynamic> data,
    Rect origin, {
    required bool Function() isCurrent,
  }) async {
    final account = await features.identity();
    final link = Uri.tryParse('${data['linkUrl'] ?? ''}');
    if (link == null ||
        !{'http', 'https'}.contains(link.scheme) ||
        link.host.isEmpty ||
        link.userInfo.isNotEmpty) {
      throw const NadyApiException(message: 'Invalid share link');
    }
    final content = RoomShareContent(
      description: '${data['description'] ?? data['title'] ?? ''}',
      link: link,
    );
    await features.check(account);
    if (!isCurrent()) return null;
    if (name == 'copy') {
      await share.copyText(content.text);
      return null;
    }
    final action = switch (name.toLowerCase()) {
      'whatsapp' => RoomShareAction.whatsapp,
      'facebook' => RoomShareAction.facebook,
      'messenger' => RoomShareAction.messenger,
      'twitter' || 'x' => RoomShareAction.x,
      'telegram' => RoomShareAction.telegram,
      'instagram' => RoomShareAction.instagram,
      'snapchat' => RoomShareAction.snapchat,
      'contacts' => RoomShareAction.contacts,
      _ => RoomShareAction.system,
    };
    if (action == RoomShareAction.system) {
      return share.shareText(text: content.text, origin: origin);
    }
    if (!await share.openChannel(action, content)) {
      throw const NadyApiException(message: 'Unable to open this application');
    }
    return RoomShareOutcome.unavailable;
  }

  Future<List<WalletRechargeProduct>> products(String type) async {
    final account = await features.identity();
    if (type == 'first') {
      final packs = await firstRecharge.fetchPacks();
      await features.check(account);
      return packs
          .where((p) => p.purchasable)
          .map((p) => p.paymentProduct)
          .toList();
    }
    final list = await wallet.fetchRechargePackages();
    await features.check(account);
    return list.where((p) => p.useType == (type == 'agent' ? 4 : 1)).toList();
  }

  Future<Map<String, dynamic>> paymentList(String type) async {
    final account = await features.identity();
    final list = await products(type);
    if (list.isEmpty || !await payment.isAvailable()) {
      return {'type': type, 'list': const []};
    }
    final native = await payment.queryProducts(list.map((p) => p.id).toSet());
    await features.check(account);
    if (native.error != null) {
      throw const NadyApiException(message: 'Payment products unavailable');
    }
    return {
      'type': type,
      'list': [
        for (final p in list)
          if (native.productDetails.where((v) => v.id == p.id).firstOrNull
              case final actual?)
            {
              'id': p.id,
              'name': p.name,
              'channel': p.channel,
              'currency': actual.currencyCode,
              'currencyAmount': (actual.rawPrice * 100).round(),
              'coinAmount': p.coinAmount,
              'sortNo': p.sortNo,
              'remark': p.remark,
              'merchant': p.merchant,
              'dollarAmount': p.dollarAmount,
              'useType': p.useType,
            },
      ],
    };
  }
}
