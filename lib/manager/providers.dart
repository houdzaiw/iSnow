import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

import '../model/diary_entry.dart';
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

