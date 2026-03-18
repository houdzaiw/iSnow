import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../model/diary_entry.dart';
import '../model/login_model.dart';
import '../model/user_model.dart';
import '../classes/oauth/provider/login_provider.dart';
import '../manager/user_manager.dart';
import 'app_Isar.dart';

/// Provider to trigger diary list refresh
final diaryRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider to fetch all DiaryEntry data from Isar
final diaryEntriesProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  // Watch the refresh provider to refetch when needed
  ref.watch(diaryRefreshProvider);

  final isar = await IsarDB.instance.db;
  // Get all entries - using the exact same query as calendar_page.dart
  final entries = await isar.diaryEntrys.where().findAll();
  // Sort by date descending (most recent first)
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
});

/// Provider to fetch current logged-in user info
final userInfoProvider = FutureProvider<UserModel?>((ref) async {
  final loginProvider = ref.read(loginProviderProvider);
  return loginProvider.getUserInfo();
});

/// Reactive session provider — holds the current [LoginModel].
/// Update it after login:  ref.read(userSessionProvider.notifier).state = model;
/// Clear it after logout:  ref.read(userSessionProvider.notifier).state = null;
final userSessionProvider = StateProvider<LoginModel?>((ref) {
  // Initialise from the singleton (already restored at app launch)
  return UserManager.shared.currentUser;
});
