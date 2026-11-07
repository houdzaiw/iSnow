import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Invalidation only: the wallet API remains the source of truth for balances.
final accountBalanceRevisionProvider = StateProvider<int>((ref) => 0);
