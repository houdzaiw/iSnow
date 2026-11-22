import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../manager/http_api.dart';
import '../../../../manager/http_dio_manager.dart';
import '../../../../model/server_response.dart';
import '../../../wallet/wallet_models.dart';
import '../../../wallet/wallet_repository.dart';
import 'room_first_recharge_models.dart';

final roomFirstRechargeRepositoryProvider = Provider(
  (ref) => RoomFirstRechargeRepository(
    HttpDioManager(),
    ref.read(walletRepositoryProvider),
  ),
);

class RoomFirstRechargeRepository {
  RoomFirstRechargeRepository(this._http, this._wallet);
  final HttpDioManager _http;
  final WalletRepository _wallet;
  Future<WalletPurse> fetchPurse() => _wallet.fetchPurse();
  Future<List<RoomFirstRechargePack>> fetchPacks() async {
    final raw = await _http.get(HttpApi.walletFirstRechargePacks);
    if (raw is! Map) {
      throw const NadyApiException(message: 'Invalid recharge response');
    }
    final server = NadyServerResponse<List<RoomFirstRechargePack>>.fromJson(
      Map<String, dynamic>.from(raw),
      (data) => [
        if (data is List)
          for (final item in data)
            if (item is Map)
              RoomFirstRechargePack.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
    if (!server.isSuccess) throw server.toException();
    return [...?server.data]..sort((a, b) => a.sortNo.compareTo(b.sortNo));
  }
}
