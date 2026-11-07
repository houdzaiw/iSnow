import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../manager/auth_session.dart';
import '../../../model/server_response.dart';

typedef MembershipIdentity = ({int uid, String token, int generation});

final membershipSessionProvider = ChangeNotifierProvider<MembershipSession>(
  (ref) => MembershipSession(),
);

/// A login generation also changes when the same UID logs in again.
class MembershipSession extends ChangeNotifier {
  MembershipSession({AuthSession? auth})
    : _auth = auth ?? AuthSession.instance {
    _auth.addListener(_changed);
  }
  final AuthSession _auth;
  int _generation = 0;
  void _changed() {
    _generation++;
    notifyListeners();
  }

  Future<MembershipIdentity> identity() async {
    final generation = _generation;
    final uid = await _auth.uid();
    final token = await _auth.token();
    if (generation != _generation || uid == null || token == null) {
      throw const NadyApiException(message: 'Login session changed');
    }
    return (uid: uid, token: token, generation: generation);
  }

  @override
  void dispose() {
    _auth.removeListener(_changed);
    super.dispose();
  }
}
