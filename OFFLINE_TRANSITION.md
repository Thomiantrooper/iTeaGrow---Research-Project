# Offline-First Hybrid Architecture: SQLite + MongoDB

**Status:** Implementation Master Plan
**Objective:** Run `SQLite` (Mobile) and `MongoDB` (Cloud) in parallel to achieve 100% offline capability with cloud synchronization.

---

## 📂 Project Folder Structure

We will introduce a new "Offline Layer" without breaking the existing Clean Architecture.

```text
lib/
├── core/
│   ├── database/                    <-- [NEW] Local Storage Layer
│   │   ├── local_database.dart      <-- SQLite Singleton (The "Phone's Brain")
│   │   └── migrations/              <-- Database version upgrades
│   ├── sync/                        <-- [NEW] The Bridge
│   │   ├── sync_service.dart        <-- Manager for Push/Pull logic
│   │   └── sync_worker.dart         <-- Background task handler (WorkManager)
├── features/
│   ├── disease_detection/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── detection_dto.dart  <-- [NEW] Data Transfer Object (translates SQLite <-> JSON)
│   │   │   ├── datasources/
│   │   │   │   ├── detection_local_ds.dart  <-- [NEW] Reads/Writes to SQLite
│   │   │   │   └── detection_remote_ds.dart <-- Existing API calls (now used only by Sync)
│   │   │   └── repositories/
│   │   │       └── detection_repo.dart      <-- UPDATED: Logic to decide "Local first, then Sync"
```

---

## 🏗️ The Dual-Database Strategy

| Feature | Mobile (Offline) | Cloud (Online) |
| :--- | :--- | :--- |
| **Engine** | **SQLite** (`sqflite`) | **MongoDB** |
| **Data Shape** | Relational Tables | JSON Documents |
| **Role** | **Immediate UI Response**<br>No loading spinners. Instant save. | **Global Storage**<br>Analytics, Backup, Web Dashboard access. |

---

## 🛠️ Step-by-Step Implementation Guide

### 1. Dependencies (`pubspec.yaml`)
Add these packages to support local storage and background syncing.

```yaml
dependencies:
  sqflite: ^2.3.0          # Local Database
  path: ^1.9.0             # File path helper
  connectivity_plus: ^5.0.0 # Check Wi-Fi status
  workmanager: ^0.5.0      # Background Sync (Android Headless)
  uuid: ^4.0.0             # Generate unique IDs offline
```

### 2. The Local Database (`local_database.dart`)
This is the entry point for all offline data.

```dart
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  // Define Table Name
  static const tableDetections = 'detections';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iteagrow_hybrid.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Note: 'id' is TEXT because we generate UUIDs on the phone (e.g. "550e8400-e29b...")
    await db.execute('''
      CREATE TABLE $tableDetections (
        id TEXT PRIMARY KEY,
        mongo_id TEXT,                  -- Null until synced
        disease_name TEXT NOT NULL,
        confidence REAL NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0     -- 0 = Dirty, 1 = Clean
      )
    ''');
  }
}
```

### 3. The Data Transfer Object (`detection_dto.dart`)
This class converts data between the 3 worlds: **Dart App**, **SQLite Table**, and **MongoDB JSON**.

```dart
class DetectionDto {
  final String id;
  final String? mongoId;
  final String diseaseName;
  final double confidence;
  final String imagePath;
  final DateTime createdAt;
  final bool isSynced;

  // ... (Constructor)

  // 1. Convert for SQLite (Insert/Update)
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'mongo_id': mongoId,
      'disease_name': diseaseName,
      'confidence': confidence,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // 2. Convert for MongoDB API (Upload)
  Map<String, dynamic> toMongoJson() {
    return {
      'local_id': id, // Send local ID so backend prevents duplicates
      'disease_class': diseaseName,
      'confidence_score': confidence,
      'timestamp': createdAt.toIso8601String(),
      'device_meta': {'platform': 'android'}
    };
  }
}
```

### 4. The Sync Service (`sync_service.dart`)
The engine that moves data from SQLite -> MongoDB.

```dart
class SyncService {
  final _db = LocalDatabase.instance;
  final _api = ApiService.instance; // Your existing API wrapper

  /// Called when Connectivity comes back online
  Future<void> syncPush() async {
    final db = await _db.database;
    
    // 1. Find Dirty Records
    final dirtyRows = await db.query(
      LocalDatabase.tableDetections,
      where: 'is_synced = ?',
      whereArgs: [0], 
    );

    if (dirtyRows.isEmpty) {
      print("Sync: Nothing to upload.");
      return;
    }

    // 2. Upload Each Record
    for (final row in dirtyRows) {
      final dto = DetectionDto.fromSql(row);
      
      try {
        final mongoId = await _api.uploadDetection(dto.toMongoJson());
        
        // 3. Mark as Synced
        await db.update(
          LocalDatabase.tableDetections,
          {
            'is_synced': 1,
            'mongo_id': mongoId,
          },
          where: 'id = ?',
          whereArgs: [dto.id],
        );
      } catch (e) {
        print("Failed to sync ${dto.id}: $e");
        // Skip, try again next time
      }
    }
  }
}
```

---

## 🔄 The New Workflow

### Scenario A: User is Offline (In the field)
1.  User snaps a photo of a tea leaf.
2.  App calculates disease (TFLite).
3.  App generates a **UUID** (`uuid.v4()`).
4.  App saves to SQLite: `is_synced = 0`.
5.  **UI**: "Saved to Device (Pending Sync)".

### Scenario B: User finds Wi-Fi
1.  `ConnectivityPlus` detects internet.
2.  Triggers `SyncService.syncPush()`.
3.  App uploads the pending record to MongoDB.
4.  App updates SQLite: `is_synced = 1`.
5.  **UI**: "All Data Synced".

### Scenario C: User gets a new Phone
1.  User installs App & Logs in.
2.  App calls `SyncService.syncPull()`.
3.  Downloads all records from MongoDB.
4.  Inserts them into SQLite.
5.  App is ready.

---

## ⚠️ Important Implementation Notes

1.  **Images:**
    *   **SQLite:** Store the *path* (`/data/user/0/.../image.jpg`), NOT the image bytes.
    *   **Cloud:** Upload the image file to your backend storage (S3/MinIO) and store the *URL* in MongoDB.

2.  **Conflicts:**
    *   Since detections are usually "Write Once" (Creation), conflicts are rare.
    *   Use the **UUID** generated on the phone as the primary key reference to avoid double-entry if the network crashes mid-sync.

3.  **Background Sync:**
    *   Use `workmanager` to run `syncPush()` every 15 minutes in the background, so the user doesn't have to keep the app open to upload 50 photos.
