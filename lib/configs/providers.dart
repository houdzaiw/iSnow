import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider to trigger diary list refresh
final diaryRefreshProvider = StateProvider<int>((ref) => 0);

