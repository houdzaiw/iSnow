import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth_session.dart';

final homeFeedSessionProvider = ChangeNotifierProvider<HomeFeedSession>(
  (ref) => HomeFeedSession(),
);

/// Invalidates home data even when the same account logs in again.
class HomeFeedSession extends ChangeNotifier {
  HomeFeedSession({AuthSession? auth}) : _auth = auth ?? AuthSession.instance {
    _auth.addListener(_changed);
  }
  final AuthSession _auth;
  int generation = 0;
  void _changed() {
    generation++;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_changed);
    super.dispose();
  }
}
