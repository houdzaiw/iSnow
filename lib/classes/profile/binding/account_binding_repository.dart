import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:project/lib/crypt_util.dart';
import '../../../manager/http_api.dart';
import '../../../manager/auth_session.dart';
import '../../../model/country_info.dart';
import '../../../model/server_response.dart';
import '../tools/profile_feature_repository.dart';

class BoundAccount {
  const BoundAccount(this.type, this.bound, this.account, this.area);
  final int type;
  final bool bound;
  final String account, area;
  factory BoundAccount.fromJson(Map<String, dynamic> j) => BoundAccount(
    membershipInt(j['bandingType']),
    j['isBanding'] == true,
    membershipString(j['accountId']),
    '${j['attachCode'] ?? ''}',
  );
}

final accountBindingRepositoryProvider = Provider(
  (ref) => AccountBindingRepository(
    ref.watch(profileFeatureRepositoryProvider),
    savePhone: (account, phone, area) => AuthSession.instance.saveBoundPhone(
      expectedUid: account.uid,
      expectedToken: account.token,
      phone: phone,
      areaCode: area,
    ),
  ),
);

class AccountBindingRepository {
  AccountBindingRepository(
    this.features, {
    Future<String> Function(String)? encrypt,
    this.savePhone,
  }) : _encrypt = encrypt ?? CryptUtil.encrypt;
  final ProfileFeatureRepository features;
  final Future<String> Function(String) _encrypt;
  final Future<void> Function(MembershipIdentity, String, String)? savePhone;
  Future<List<BoundAccount>> accounts() async => membershipList(
    await features.request('POST', HttpApi.profileAccountBindings),
    BoundAccount.fromJson,
  );
  Future<List<CountryInfo>> countries() async => membershipList(
    await features.request('GET', HttpApi.supportedCountry),
    CountryInfo.fromJson,
  );
  Future<void> send(
    String phone,
    String area, {
    required bool verifyOld,
    int type = 1,
    bool Function()? isCurrent,
  }) async {
    final account = await features.identity();
    if (!verifyOld) {
      final raw = await features.request(
        'GET',
        HttpApi.hasUser,
        account: account,
        params: {'phone': phone, 'areaCode': area},
      );
      if (membershipMap(raw)['hasUser'] == true) {
        throw const NadyApiException(
          message: 'This phone number is already in use',
        );
      }
    }
    await features.request(
      'POST',
      HttpApi.sendSms,
      account: account,
      isCurrent: isCurrent,
      params: {
        'phoneNo': phone,
        'areaCode': area,
        'purpose': verifyOld ? 5 : 4,
        'type': type,
        'language': features.language,
      },
    );
  }

  Future<void> verify(
    String phone,
    String area,
    String code, {
    bool Function()? isCurrent,
  }) async {
    final verified = await features.request(
      'POST',
      HttpApi.verifyCode,
      isCurrent: isCurrent,
      params: {'code': phone, 'areaCode': area, 'smsCode': code},
    );
    if (verified == false) {
      throw const NadyApiException(message: 'Verification failed');
    }
  }

  Future<bool> bind(
    String phone,
    String area,
    String code,
    String password, {
    required bool needsPassword,
    bool Function()? isCurrent,
  }) async {
    final account = await features.identity();
    final verified = await features.request(
      'POST',
      HttpApi.verifyCode,
      account: account,
      isCurrent: isCurrent,
      params: {'code': phone, 'areaCode': area, 'smsCode': code},
    );
    if (verified == false) {
      throw const NadyApiException(message: 'Verification failed');
    }
    final encrypted = needsPassword ? await _encrypt(password) : '';
    await features.check(account);
    await features.request(
      'POST',
      HttpApi.profileBindPhone,
      account: account,
      isCurrent: isCurrent,
      params: {'passwd': encrypted, 'phone': phone, 'areaCode': area},
    );
    await features.check(account);
    try {
      await savePhone?.call(account, phone, area);
      return await features.synchronize(account);
    } catch (_) {
      // Binding already succeeded; never suggest submitting it again.
      return false;
    }
  }
}
