import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../oauth/provider/login_provider.dart';
import 'profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(LoginProvider());
});

class ProfileRepository {
  const ProfileRepository(this._loginProvider);

  final LoginProvider _loginProvider;

  Future<ProfileAccountSummary?> cachedProfile() async {
    final user = await _loginProvider.cachedUser();
    if (user == null) return null;
    return ProfileAccountSummary.cached(user);
  }

  Future<ProfileAccountSummary> fetchProfile() async {
    final me = await _loginProvider.getMyProfileInfo();
    return ProfileAccountSummary.fromMe(me);
  }

  Future<void> logout() {
    return _loginProvider.logout();
  }

  Future<void> deleteAccount() {
    return _loginProvider.logoff();
  }
}
