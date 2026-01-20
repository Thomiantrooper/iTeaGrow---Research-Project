import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iteagrow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        language_preference TEXT DEFAULT 'en',
        created_at TEXT NOT NULL,
        full_name TEXT,
        email TEXT,
        phone TEXT
      )
    ''');

    // IoT Devices table
    await db.execute('''
      CREATE TABLE iot_devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_name TEXT NOT NULL,
        device_type TEXT NOT NULL,
        mac_address TEXT UNIQUE,
        connection_type TEXT NOT NULL,
        paired_at TEXT NOT NULL,
        last_connected TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Sensor Readings table
    await db.execute('''
      CREATE TABLE sensor_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        soil_moisture REAL,
        soil_ph REAL,
        nitrogen REAL,
        phosphorus REAL,
        potassium REAL,
        temperature REAL,
        humidity REAL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (device_id) REFERENCES iot_devices (id)
      )
    ''');

    // Leaf Detections table
    await db.execute('''
      CREATE TABLE leaf_detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        classification TEXT NOT NULL,
        confidence REAL NOT NULL,
        tender_count INTEGER DEFAULT 0,
        mature_count INTEGER DEFAULT 0,
        coarser_count INTEGER DEFAULT 0,
        yield_prediction REAL,
        good_leaf_percentage REAL,
        gradcam_path TEXT,
        synced INTEGER DEFAULT 0,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Disease Detections table
    await db.execute('''
      CREATE TABLE disease_detections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        disease_type TEXT NOT NULL,
        confidence REAL NOT NULL,
        severity TEXT,
        recommendations TEXT,
        environmental_correlation TEXT,
        synced INTEGER DEFAULT 0,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Powder Gradings table
    await db.execute('''
      CREATE TABLE powder_gradings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        grade TEXT NOT NULL,
        confidence REAL NOT NULL,
        market_price REAL,
        quality_score REAL,
        synced INTEGER DEFAULT 0,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Fertilizer Recommendations table
    await db.execute('''
      CREATE TABLE fertilizer_recommendations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        nitrogen_value REAL,
        phosphorus_value REAL,
        potassium_value REAL,
        ph_value REAL,
        recommendation TEXT NOT NULL,
        fertilizer_type TEXT,
        quantity REAL,
        application_method TEXT,
        applied INTEGER DEFAULT 0,
        applied_at TEXT,
        synced INTEGER DEFAULT 0,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        severity TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        read INTEGER DEFAULT 0,
        user_role TEXT,
        action_required TEXT,
        dismissed INTEGER DEFAULT 0
      )
    ''');

    // System Configuration table
    await db.execute('''
      CREATE TABLE system_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        config_key TEXT NOT NULL UNIQUE,
        config_value TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        updated_by INTEGER,
        FOREIGN KEY (updated_by) REFERENCES users (id)
      )
    ''');

    // Sync Log table
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        sync_timestamp TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        error_message TEXT
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_sensor_readings_timestamp ON sensor_readings(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_leaf_detections_timestamp ON leaf_detections(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_alerts_read ON alerts(read, user_role)',
    );

    // Insert default demo users with SHA256 hashed passwords
    // admin / admin123
    await db.execute('''
      INSERT INTO users (username, password_hash, role, created_at, full_name, email)
      VALUES ('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'admin', datetime('now'), 'System Administrator', 'admin@iteagrow.com')
    ''');

    // manager / manager123
    await db.execute('''
      INSERT INTO users (username, password_hash, role, created_at, full_name, email)
      VALUES ('manager', '866485796cfa8d7c0cf7111640205b83076433547577511d81f8030ae99ecea5', 'manager', datetime('now'), 'Plantation Manager', 'manager@iteagrow.com')
    ''');

    // farmer / farmer123
    await db.execute('''
      INSERT INTO users (username, password_hash, role, created_at, full_name, email)
      VALUES ('farmer', '26c07fc7be1668f8ea7e3801d4ffdbf33de487a593a69028936ec49f2c89f6ab', 'farmer', datetime('now'), 'Tea Farmer', 'farmer@iteagrow.com')
    ''');

    // Insert default system configurations
    await db.execute('''
      INSERT INTO system_config (config_key, config_value, updated_at)
      VALUES 
        ('soil_moisture_min', '30', datetime('now')),
        ('soil_moisture_max', '70', datetime('now')),
        ('soil_ph_min', '4.5', datetime('now')),
        ('soil_ph_max', '6.5', datetime('now')),
        ('temp_min', '18', datetime('now')),
        ('temp_max', '30', datetime('now')),
        ('humidity_min', '70', datetime('now')),
        ('humidity_max', '90', datetime('now'))
    ''');
  }

  // Generic query methods
  Future<List<Map<String, dynamic>>> query(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where, {
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String where, {
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where,
      {List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
