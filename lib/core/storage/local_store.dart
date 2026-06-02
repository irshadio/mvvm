import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast.dart';

part 'local_store.g.dart';

/// Contract for non-sensitive local persistence (caches, offline copies).
///
/// Records are JSON-shaped `Map<String, Object?>`; the data layer converts
/// to/from DTOs via their `toJson`/`fromJson`.
abstract interface class LocalStore {
  Future<Map<String, Object?>?> read(String storeName, String key);
  Future<List<Map<String, Object?>>> readAll(String storeName);
  Future<void> write(String storeName, String key, Map<String, Object?> value);

  /// Upserts a set of records in one transaction (existing records with other
  /// keys are left untouched). For refreshing a *snapshot* — where records
  /// removed at the source must not linger — use [replaceAll].
  Future<void> writeAll(
    String storeName,
    Map<String, Map<String, Object?>> entries,
  );

  /// Atomically replaces the ENTIRE contents of [storeName] with [entries]
  /// (clear + write in a single transaction).
  Future<void> replaceAll(
    String storeName,
    Map<String, Map<String, Object?>> entries,
  );

  Future<void> delete(String storeName, String key);
  Future<void> clear(String storeName);
}

/// sembast-backed [LocalStore]. The [Database] is opened once in
/// `core/bootstrap` and injected here.
class LocalStoreImpl implements LocalStore {
  LocalStoreImpl(this._db);

  final Database _db;

  StoreRef<String, Map<String, Object?>> _store(String name) =>
      stringMapStoreFactory.store(name);

  @override
  Future<Map<String, Object?>?> read(String storeName, String key) =>
      _store(storeName).record(key).get(_db);

  @override
  Future<List<Map<String, Object?>>> readAll(String storeName) async {
    final records = await _store(storeName).find(_db);
    return records.map((record) => record.value).toList();
  }

  @override
  Future<void> write(
    String storeName,
    String key,
    Map<String, Object?> value,
  ) => _store(storeName).record(key).put(_db, value);

  /// Upserts a set of records in one transaction (keys not in [entries] are
  /// left as-is). See [replaceAll] for snapshot-style refreshes.
  @override
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

  @override
  Future<void> replaceAll(
    String storeName,
    Map<String, Map<String, Object?>> entries,
  ) {
    return _db.transaction((txn) async {
      final store = _store(storeName);
      await store.delete(txn); // clear the old snapshot first
      for (final entry in entries.entries) {
        await store.record(entry.key).put(txn, entry.value);
      }
    });
  }

  @override
  Future<void> delete(String storeName, String key) =>
      _store(storeName).record(key).delete(_db);

  @override
  Future<void> clear(String storeName) => _store(storeName).delete(_db);
}

/// Bound to [LocalStoreImpl] in `core/bootstrap` (after the database is opened).
@riverpod
LocalStore localStore(Ref ref) => throw UnimplementedError(
  'localStoreProvider must be overridden in ProviderScope — see core/bootstrap.',
);
