import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';

/// Sync status for records
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

/// Sync result class
class SyncResult {
  final String tableName;
  final int totalRecords;
  final int syncedRecords;
  final int failedRecords;
  final List<String> errors;
  final DateTime timestamp;

  SyncResult({
    required this.tableName,
    required this.totalRecords,
    required this.syncedRecords,
    required this.failedRecords,
    required this.errors,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isComplete => totalRecords == syncedRecords;
  bool get hasErrors => failedRecords > 0 || errors.isNotEmpty;
}

/// Data export format for cloud sync
class SyncPayload {
  final String userId;
  final String tableName;
  final List<Map<String, dynamic>> records;
  final DateTime exportedAt;
  final String appVersion;

  SyncPayload({
    required this.userId,
    required this.tableName,
    required this.records,
    DateTime? exportedAt,
    this.appVersion = '1.0.0',
  }) : exportedAt = exportedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'table_name': tableName,
        'records': records,
        'exported_at': exportedAt.toIso8601String(),
        'app_version': appVersion,
        'record_count': records.length,
      };
}

/// Service for handling data synchronization
/// Prepares data for Google Cloud/Drive sync
class SyncService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Tables that should be synced
  static const List<String> syncableTables = [
    'leaf_detections',
    'disease_detections',
    'powder_gradings',
    'sensor_readings',
    'fertilizer_recommendations',
    'alerts',
  ];

  /// Get all unsynced records from a table
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    try {
      return await _db.queryWhere(
        table,
        'synced = ?',
        whereArgs: [0],
      );
    } catch (e) {
      return [];
    }
  }

  /// Get sync status for all tables
  Future<Map<String, int>> getSyncStatus() async {
    final status = <String, int>{};
    for (final table in syncableTables) {
      final records = await getUnsyncedRecords(table);
      status[table] = records.length;
    }
    return status;
  }

  /// Get total unsynced count
  Future<int> getTotalUnsyncedCount() async {
    int total = 0;
    for (final table in syncableTables) {
      final records = await getUnsyncedRecords(table);
      total += records.length;
    }
    return total;
  }

  /// Mark records as synced
  Future<bool> markAsSynced(String table, List<int> recordIds) async {
    try {
      for (final id in recordIds) {
        await _db.update(
          table,
          {'synced': 1},
          'id = ?',
          whereArgs: [id],
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Log sync activity
  Future<void> logSync({
    required String tableName,
    required int recordId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      await _db.insert('sync_log', {
        'table_name': tableName,
        'record_id': recordId,
        'sync_timestamp': DateTime.now().toIso8601String(),
        'sync_status': status,
        'error_message': errorMessage,
      });
    } catch (e) {
      // Ignore logging errors
    }
  }

  /// Get sync history
  Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 50}) async {
    try {
      final db = await _db.database;
      return await db.query(
        'sync_log',
        orderBy: 'sync_timestamp DESC',
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

  /// Export data for a user (for cloud backup)
  Future<SyncPayload> exportUserData(String userId, String table) async {
    try {
      final records = await _db.queryWhere(
        table,
        'user_id = ?',
        whereArgs: [userId],
      );

      return SyncPayload(
        userId: userId,
        tableName: table,
        records: records,
      );
    } catch (e) {
      return SyncPayload(
        userId: userId,
        tableName: table,
        records: [],
      );
    }
  }

  /// Export all user data for backup
  Future<Map<String, SyncPayload>> exportAllUserData(String userId) async {
    final exports = <String, SyncPayload>{};

    for (final table in syncableTables) {
      exports[table] = await exportUserData(userId, table);
    }

    return exports;
  }

  /// Import data from cloud (restore)
  Future<bool> importData(String table, List<Map<String, dynamic>> records) async {
    try {
      for (final record in records) {
        // Remove the id to insert as new record
        final data = Map<String, dynamic>.from(record);
        data.remove('id');
        data['synced'] = 1; // Mark as synced since it came from cloud

        await _db.insert(table, data);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Prepare sync payload for Google Cloud Storage
  /// This method creates a JSON structure ready for upload
  Future<Map<String, dynamic>> prepareCloudPayload(String userId) async {
    final allData = await exportAllUserData(userId);

    final payload = <String, dynamic>{
      'metadata': {
        'user_id': userId,
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'platform': 'flutter',
      },
      'data': {},
    };

    for (final entry in allData.entries) {
      payload['data'][entry.key] = entry.value.toJson();
    }

    return payload;
  }

  /// Calculate data size for sync (approximate)
  Future<int> calculateDataSize(String userId) async {
    final payload = await prepareCloudPayload(userId);
    final jsonString = payload.toString();
    return jsonString.length; // Approximate byte size
  }

  /// Get last sync timestamp for a table
  Future<DateTime?> getLastSyncTime(String table) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'sync_log',
        where: 'table_name = ? AND sync_status = ?',
        whereArgs: [table, 'success'],
        orderBy: 'sync_timestamp DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return DateTime.parse(result.first['sync_timestamp'] as String);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  /// Clear sync log (for testing/maintenance)
  Future<void> clearSyncLog() async {
    try {
      await _db.delete('sync_log', '1 = 1');
    } catch (e) {
      // Ignore
    }
  }
}

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// Provider for unsynced record count
final unsyncedCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getTotalUnsyncedCount();
});

/// Provider for sync status per table
final syncStatusProvider = FutureProvider<Map<String, int>>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getSyncStatus();
});
