import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'database_config.dart';
import 'migrations/migration_manager.dart';

/// SQLite database helper with connection management and migration support
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  static final _connectionPool = <Database>[];
  static bool _isInitialized = false;

  DatabaseHelper._internal();

  /// Singleton instance
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Get database instance with lazy initialization
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with proper configuration
  Future<Database> _initDatabase() async {
    if (_isInitialized) {
      return _database!;
    }

    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, DatabaseConfig.sqliteDatabaseName);
      
      // Ensure directory exists
      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final database = await openDatabase(
        path,
        version: DatabaseConfig.currentSchemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
        onOpen: _onOpen,
        onConfigure: _onConfigure,
      );

      _isInitialized = true;
      return database;
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
    
    // Set journal mode to WAL for better performance
    await db.execute('PRAGMA journal_mode = WAL');
    
    // Set synchronous mode to NORMAL for balance of safety and performance
    await db.execute('PRAGMA synchronous = NORMAL');
    
    // Set cache size (negative value means KB)
    await db.execute('PRAGMA cache_size = -10000'); // 10MB cache
    
    // Set temp store to memory for better performance
    await db.execute('PRAGMA temp_store = MEMORY');
  }

  /// Create initial database schema
  Future<void> _onCreate(Database db, int version) async {
    final migrationManager = MigrationManager();
    await migrationManager.runInitialMigration(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (DatabaseConfig.enableAutoMigration) {
      final migrationManager = MigrationManager();
      await migrationManager.runMigrations(db, oldVersion, newVersion);
    } else {
      throw DatabaseException(
        'Database upgrade from version $oldVersion to $newVersion is not supported. '
        'Auto-migration is disabled.',
      );
    }
  }

  /// Handle database downgrades
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    if (DatabaseConfig.enableMigrationRollback) {
      final migrationManager = MigrationManager();
      await migrationManager.rollbackMigrations(db, oldVersion, newVersion);
    } else {
      throw DatabaseException(
        'Database downgrade from version $oldVersion to $newVersion is not supported. '
        'Migration rollback is disabled.',
      );
    }
  }

  /// Called when database is opened
  Future<void> _onOpen(Database db) async {
    // Verify database integrity
    final result = await db.rawQuery('PRAGMA integrity_check');
    if (result.isNotEmpty && result.first.values.first != 'ok') {
      throw DatabaseException('Database integrity check failed');
    }
  }

  /// Execute a query with timeout and error handling
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      ).timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds));
    } catch (e) {
      throw DatabaseException('Query failed: $e');
    }
  }

  /// Insert data with conflict resolution
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    try {
      final db = await database;
      return await db.insert(
        table,
        values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm ?? ConflictAlgorithm.abort,
      ).timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds));
    } catch (e) {
      throw DatabaseException('Insert failed: $e');
    }
  }

  /// Update data with where clause
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    try {
      final db = await database;
      return await db.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      ).timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds));
    } catch (e) {
      throw DatabaseException('Update failed: $e');
    }
  }

  /// Delete data with where clause
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      ).timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds));
    } catch (e) {
      throw DatabaseException('Delete failed: $e');
    }
  }

  /// Execute raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments)
          .timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds));
    } catch (e) {
      throw DatabaseException('Raw query failed: $e');
    }
  }

  /// Execute raw SQL statement
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    try {
      final db = await database;
      await db.execute(sql, arguments)
          .timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds));
    } catch (e) {
      throw DatabaseException('Execute failed: $e');
    }
  }

  /// Execute multiple statements in a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    try {
      final db = await database;
      return await db.transaction(action)
          .timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds * 2));
    } catch (e) {
      throw DatabaseException('Transaction failed: $e');
    }
  }

  /// Batch operations for better performance
  Future<List<Object?>> batch(List<BatchOperation> operations) async {
    try {
      final db = await database;
      final batch = db.batch();
      
      for (final operation in operations) {
        switch (operation.type) {
          case BatchOperationType.insert:
            batch.insert(
              operation.table,
              operation.values!,
              conflictAlgorithm: operation.conflictAlgorithm,
            );
            break;
          case BatchOperationType.update:
            batch.update(
              operation.table,
              operation.values!,
              where: operation.where,
              whereArgs: operation.whereArgs,
              conflictAlgorithm: operation.conflictAlgorithm,
            );
            break;
          case BatchOperationType.delete:
            batch.delete(
              operation.table,
              where: operation.where,
              whereArgs: operation.whereArgs,
            );
            break;
          case BatchOperationType.rawInsert:
            batch.rawInsert(operation.sql!, operation.arguments);
            break;
          case BatchOperationType.rawUpdate:
            batch.rawUpdate(operation.sql!, operation.arguments);
            break;
          case BatchOperationType.rawDelete:
            batch.rawDelete(operation.sql!, operation.arguments);
            break;
        }
      }
      
      return await batch.commit()
          .timeout(Duration(seconds: DatabaseConfig.queryTimeoutSeconds * 2));
    } catch (e) {
      throw DatabaseException('Batch operation failed: $e');
    }
  }

  /// Get database file size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, DatabaseConfig.sqliteDatabaseName);
      final file = File(path);
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      throw DatabaseException('Failed to get database size: $e');
    }
  }

  /// Vacuum database to reclaim space
  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
    } catch (e) {
      throw DatabaseException('Vacuum failed: $e');
    }
  }

  /// Analyze database for query optimization
  Future<void> analyze() async {
    try {
      final db = await database;
      await db.execute('ANALYZE');
    } catch (e) {
      throw DatabaseException('Analyze failed: $e');
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
    
    // Close connection pool
    for (final db in _connectionPool) {
      if (db.isOpen) {
        await db.close();
      }
    }
    _connectionPool.clear();
  }

  /// Reset database (for testing purposes)
  Future<void> reset() async {
    await close();
    
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, DatabaseConfig.sqliteDatabaseName);
      final file = File(path);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      // Also delete WAL and SHM files
      final walFile = File('$path-wal');
      final shmFile = File('$path-shm');
      
      if (await walFile.exists()) {
        await walFile.delete();
      }
      
      if (await shmFile.exists()) {
        await shmFile.delete();
      }
    } catch (e) {
      throw DatabaseException('Reset failed: $e');
    }
  }
}

/// Custom exception for database operations
class DatabaseException implements Exception {
  final String message;
  
  const DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}

/// Batch operation types
enum BatchOperationType {
  insert,
  update,
  delete,
  rawInsert,
  rawUpdate,
  rawDelete,
}

/// Batch operation definition
class BatchOperation {
  final BatchOperationType type;
  final String table;
  final Map<String, Object?>? values;
  final String? where;
  final List<Object?>? whereArgs;
  final ConflictAlgorithm? conflictAlgorithm;
  final String? sql;
  final List<Object?>? arguments;

  const BatchOperation({
    required this.type,
    required this.table,
    this.values,
    this.where,
    this.whereArgs,
    this.conflictAlgorithm,
    this.sql,
    this.arguments,
  });

  /// Create insert operation
  factory BatchOperation.insert(
    String table,
    Map<String, Object?> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return BatchOperation(
      type: BatchOperationType.insert,
      table: table,
      values: values,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Create update operation
  factory BatchOperation.update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return BatchOperation(
      type: BatchOperationType.update,
      table: table,
      values: values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Create delete operation
  factory BatchOperation.delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return BatchOperation(
      type: BatchOperationType.delete,
      table: table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Create raw insert operation
  factory BatchOperation.rawInsert(String sql, [List<Object?>? arguments]) {
    return BatchOperation(
      type: BatchOperationType.rawInsert,
      table: '',
      sql: sql,
      arguments: arguments,
    );
  }

  /// Create raw update operation
  factory BatchOperation.rawUpdate(String sql, [List<Object?>? arguments]) {
    return BatchOperation(
      type: BatchOperationType.rawUpdate,
      table: '',
      sql: sql,
      arguments: arguments,
    );
  }

  /// Create raw delete operation
  factory BatchOperation.rawDelete(String sql, [List<Object?>? arguments]) {
    return BatchOperation(
      type: BatchOperationType.rawDelete,
      table: '',
      sql: sql,
      arguments: arguments,
    );
  }
}
