import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../model/diary_entry.dart';

class IsarDB {
  IsarDB._();
  static final IsarDB instance = IsarDB._();

  Isar? _isar;

  Future<Isar> get db async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [DiaryEntrySchema],
      directory: dir.path,
    );
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}

