import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';

import '../config/app_config.dart';

part 'local_store.g.dart';

/// Thin, typed wrapper over a sembast [Database] for non-sensitive local data
/// (caches, offline copies, preferences). Features depend on this rather than
/// touching sembast directly, keeping store names and access in one place.
///
/// Records are stored as `Map<String, Object?>` (JSON-shaped); the data layer
/// converts to/from DTOs via their `toJson`/`fromJson`.
class LocalStore {
  LocalStore(this._db);

  final Database _db;

  StoreRef<String, Map<String, Object?>> _store(String name) =>
      stringMapStoreFactory.store(name);

  Future<Map<String, Object?>?> read(String storeName, String key) =>
      _store(storeName).record(key).get(_db);

  Future<List<Map<String, Object?>>> readAll(String storeName) async {
    final records = await _store(storeName).find(_db);
    return records.map((record) => record.value).toList();
  }

  Future<void> write(String storeName, String key, Map<String, Object?> value) =>
      _store(storeName).record(key).put(_db, value);

  /// Atomically replaces a set of records (used by repositories to refresh a
  /// cached collection in one transaction).
  Future<void> writeAll(
    String storeName,
    Map<String, Map<String, Object?>> entries,
  ) {
    return _db.transaction((txn) async {
      final store = _store(storeName);
      for (final entry in entries.entries) {
        await store.record(entry.key).put(txn, entry.value);
      }
    });
  }

  Future<void> delete(String storeName, String key) =>
      _store(storeName).record(key).delete(_db);

  Future<void> clear(String storeName) => _store(storeName).delete(_db);
}

/// Opens (once) the on-device sembast database. Closed automatically when the
/// provider is disposed.
///
/// Native (io) platforms only — for web, swap `databaseFactoryIo` for
/// `databaseFactoryWeb` from `package:sembast_web/sembast_web.dart`.
@riverpod
Future<Database> appDatabase(Ref ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, AppConfig.databaseName);
  final db = await databaseFactoryIo.openDatabase(dbPath);
  ref.onDispose(db.close);
  return db;
}

@riverpod
Future<LocalStore> localStore(Ref ref) async =>
    LocalStore(await ref.watch(appDatabaseProvider.future));
