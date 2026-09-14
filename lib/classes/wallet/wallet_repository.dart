import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/lib/crypt_util.dart';
import '../../manager/http_api.dart';
import '../../manager/http_dio_manager.dart';
import '../../model/server_response.dart';
import 'wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(HttpDioManager());
});

class WalletRepository {
  const WalletRepository(this._httpManager);

  final HttpDioManager _httpManager;

  Future<WalletPurse> fetchPurse() async {
    final response = await _httpManager.get(HttpApi.walletPurse);
    return _requireData(response, (json) => WalletPurse.fromJson(_asMap(json)));
  }

  Future<List<WalletRechargeProduct>> fetchRechargePackages() async {
    final channel = _platformChannel;
    if (channel.isEmpty) return const <WalletRechargeProduct>[];

    final response = await _httpManager.post(
      HttpApi.walletRechargePackageList,
      data: const <String, dynamic>{},
      queryParameters: {'channel': channel, 'merchant': channel},
    );
    final server = NadyServerResponse<List<WalletRechargeProduct>>.fromJson(
      _asMap(response),
      (json) => _extractList(json)
          .whereType<Map>()
          .map(
            (item) =>
                WalletRechargeProduct.fromJson(item.cast<String, dynamic>()),
          )
          .where((product) => product.id.isNotEmpty)
          .toList(growable: false),
    );
    if (!server.isSuccess) throw server.toException();

    final products = [...server.data ?? const <WalletRechargeProduct>[]];
    products.sort((a, b) => a.sortNo.compareTo(b.sortNo));
    return products;
  }

  Future<WalletConvertProportion> fetchDiamondReminder() async {
    final response = await _httpManager.get(
      HttpApi.walletConvertProportion,
      queryParameters: const {'currencyType': 2},
    );
    return _requireData(
      response,
      (json) => WalletConvertProportion.fromJson(_asMap(json)),
    );
  }

  Future<String> createGoogleRechargeOrder(
    WalletRechargeProduct product,
  ) async {
    final request = WalletRechargeRequest(
      productId: product.id,
      channel: 'google',
      merchant: 1,
    );
    final response = await _httpManager.post(
      HttpApi.walletRechargeGoogleCreation,
      data: {'rechargeReqJson': await _encrypt(request.toJson())},
    );
    final server = NadyServerResponse<dynamic>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) throw server.toException();
    final orderId = server.data?.toString() ?? '';
    if (orderId.isEmpty) {
      throw const NadyApiException(
        message: 'Google recharge order id is empty',
      );
    }
    return orderId;
  }

  Future<void> createAppleRechargeRecord({
    required WalletRechargeProduct product,
    required String orderId,
    required String purchaseToken,
  }) async {
    final request = WalletRechargeRequest(
      productId: product.id,
      channel: 'apple',
      merchant: 2,
      orderId: orderId,
      purchaseToken: purchaseToken,
    );
    final response = await _httpManager.post(
      HttpApi.walletRechargeCreation,
      data: {'rechargeReqJson': await _encrypt(request.toJson())},
    );
    final server = NadyServerResponse<dynamic>.fromJson(
      _asMap(response),
      (json) => json,
    );
    if (!server.isSuccess) throw server.toException();
  }

  String get _platformChannel {
    if (Platform.isAndroid) return 'google';
    if (Platform.isIOS) return 'apple';
    return '';
  }

  Future<String> _encrypt(Map<String, dynamic> request) {
    return CryptUtil.encrypt(jsonEncode(request));
  }

  T _requireData<T>(dynamic response, T Function(Object? json) fromJson) {
    final server = NadyServerResponse<T>.fromJson(_asMap(response), fromJson);
    if (!server.isSuccess || server.data == null) throw server.toException();
    return server.data!;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const NadyApiException(message: 'Invalid server response');
  }

  List<dynamic> _extractList(Object? value) {
    if (value is List) return value;
    if (value is Map && value['list'] is List) return value['list'] as List;
    if (value is Map && value['data'] != null) {
      return _extractList(value['data']);
    }
    return const <dynamic>[];
  }
}
