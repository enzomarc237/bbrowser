import 'package:sqflite/sqflite.dart';
import '../database_config.dart';
import 'base_migration.dart';
import 'migration_v1_0_0.dart';
import 'dart:async';

/// Manages database migrations with version tracking and rollback support
class MigrationManager {
  static MigrationManager? _instance;
  static final List<BaseMigration> _migrations = [];
  static bool _isInitialized = false;

  MigrationManager._internal();

  /// Singleton instance
  static MigrationManager get instance {
    _instance ??= MigrationManager._internal();
    return _instance!;
  }

  /// Initialize migration manager with all available migrations
  static void initialize() {
    if (_isInitialized) return;

    // Register all migrations in order
    _migrations.clear();
    _migrations.addAll([
      MigrationV1_0_0(),
      // Add future migrations here
    ]);

    // Sort migrations by version to ensure proper order
    _migrations.sort((a, b) => a.version.compareTo(b.version));

    _isInitialized = true;
  }

  /// Get all registered migrations
  List<BaseMigration> get migrations {
    if (!_isInitialized) initialize();
    return List.unmodifiable(_migrations);
  }

  /// Get migration by version
  BaseMigration? getMigration(int version) {
    return migrations.where((m) => m.version == version).firstOrNull;
  }

  /// Get current database schema version
  Future<int> getCurrentVersion(Database db) async {
    try {
      // Check if migrations table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConfig.migrationsTable}'",
      );

      if (tables.isEmpty) {
        return 0; // No migrations table means version 0
      }

      // Get the highest version from migrations table
      final result = await db.rawQuery(
        'SELECT MAX(version) as max_version FROM ${DatabaseConfig.migrationsTable}',
      );

      final maxVersion = result.first['max_version'] as int?;
      return maxVersion ?? 0;
    } catch (e) {
      throw MigrationException('Failed to get current database version: $e');
    }
  }

  /// Run initial migration (create schema from scratch)
  Future<void> runInitialMigration(Database db) async {
    final currentVersion = await getCurrentVersion(db);
    
    if (currentVersion > 0) {
      throw MigrationException(
        'Database already has version $currentVersion. Use runMigrations() for upgrades.',
      );
    }

    // Run all migrations from version 0 to latest
    final latestVersion = migrations.isNotEmpty ? migrations.last.version : 0;
    await runMigrations(db, 0, latestVersion);
  }

  /// Run migrations from current version to target version
  Future<List<MigrationResult>> runMigrations(
    Database db,
    int fromVersion,
    int toVersion,
  ) async {
    if (!_isInitialized) initialize();

    final currentVersion = fromVersion == 0 ? await getCurrentVersion(db) : fromVersion;
    
    if (currentVersion == toVersion) {
      return []; // No migrations needed
    }

    final context = MigrationContext(
      database: db,
      currentVersion: currentVersion,
      targetVersion: toVersion,
    );

    if (context.isUpgrade) {
      return await _runUpgradeMigrations(context);
    } else {
      return await _runDowngradeMigrations(context);
    }
  }

  /// Run upgrade migrations
  Future<List<MigrationResult>> _runUpgradeMigrations(MigrationContext context) async {
    final results = <MigrationResult>[];
    final migrationsToRun = <BaseMigration>[];

    // Find migrations to run
    for (final version in context.versionRange) {
      final migration = getMigration(version);
      if (migration == null) {
        throw MigrationException('Migration for version $version not found');
      }
      migrationsToRun.add(migration);
    }

    // Validate dependencies
    await _validateMigrationDependencies(migrationsToRun, context.database);

    // Create migrations table if it doesn't exist
    await _ensureMigrationsTableExists(context.database);

    // Execute migrations
    for (final migration in migrationsToRun) {
      final result = await _executeMigration(migration, context, isUpgrade: true);
      results.add(result);

      if (!result.success) {
        throw MigrationException(
          'Migration ${migration.version} failed: ${result.error}',
        );
      }
    }

    return results;
  }

  /// Run downgrade migrations
  Future<List<MigrationResult>> _runDowngradeMigrations(MigrationContext context) async {
    final results = <MigrationResult>[];
    final migrationsToRun = <BaseMigration>[];

    // Find migrations to rollback (in reverse order)
    for (final version in context.versionRange) {
      final migration = getMigration(version);
      if (migration == null) {
        throw MigrationException('Migration for version $version not found');
      }
      
      if (!migration.supportsRollback) {
        throw MigrationException(
          'Migration $version (${migration.name}) does not support rollback',
        );
      }
      
      migrationsToRun.add(migration);
    }

    // Execute rollbacks
    for (final migration in migrationsToRun) {
      final result = await _executeMigration(migration, context, isUpgrade: false);
      results.add(result);

      if (!result.success) {
        throw MigrationException(
          'Migration rollback ${migration.version} failed: ${result.error}',
        );
      }
    }

    return results;
  }

  /// Execute a single migration
  Future<MigrationResult> _executeMigration(
    BaseMigration migration,
    MigrationContext context,
    {required bool isUpgrade}
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Validate migration if not skipped
      if (!context.skipValidation) {
        await migration.validate(context.database);
      }

      // Call pre-migration hook
      await migration.beforeMigration(context.database);

      if (context.dryRun) {
        // Dry run - just validate, don't execute
        stopwatch.stop();
        return MigrationResult(
          migration: migration,
          success: true,
          executionTime: stopwatch.elapsedMilliseconds,
        );
      }

      // Execute migration
      if (isUpgrade) {
        await migration.upgrade(context.database);
        await _recordMigration(context.database, migration);
      } else {
        await migration.downgrade(context.database);
        await _removeMigrationRecord(context.database, migration.version);
      }

      // Call post-migration hook
      await migration.afterMigration(context.database);

      stopwatch.stop();
      return MigrationResult(
        migration: migration,
        success: true,
        executionTime: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      
      // Call failure hook
      await migration.onMigrationFailure(context.database, e);
      
      return MigrationResult(
        migration: migration,
        success: false,
        executionTime: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
    }
  }

  /// Validate migration dependencies
  Future<void> _validateMigrationDependencies(
    List<BaseMigration> migrationsToRun,
    Database db,
  ) async {
    for (final migration in migrationsToRun) {
      for (final dependency in migration.dependencies) {
        // Check if dependency is in the current batch
        final dependencyInBatch = migrationsToRun.any((m) => m.version == dependency);
        
        if (!dependencyInBatch) {
          // Check if dependency is already applied
          final result = await db.query(
            DatabaseConfig.migrationsTable,
            where: 'version = ?',
            whereArgs: [dependency],
          );
          
          if (result.isEmpty) {
            throw MigrationException(
              'Migration ${migration.version} depends on migration $dependency which has not been applied',
            );
          }
        }
      }
    }
  }

  /// Ensure migrations table exists
  Future<void> _ensureMigrationsTableExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConfig.migrationsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version INTEGER NOT NULL UNIQUE,
        name TEXT NOT NULL,
        executed_at INTEGER NOT NULL,
        execution_time_ms INTEGER NOT NULL,
        checksum TEXT NOT NULL
      )
    ''');
  }

  /// Record successful migration
  Future<void> _recordMigration(Database db, BaseMigration migration) async {
    await db.insert(
      DatabaseConfig.migrationsTable,
      {
        'version': migration.version,
        'name': migration.name,
        'executed_at': DateTime.now().millisecondsSinceEpoch,
        'execution_time_ms': migration.estimatedExecutionTime,
        'checksum': migration.checksum,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove migration record (for rollbacks)
  Future<void> _removeMigrationRecord(Database db, int version) async {
    await db.delete(
      DatabaseConfig.migrationsTable,
      where: 'version = ?',
      whereArgs: [version],
    );
  }

  /// Get migration history
  Future<List<Map<String, dynamic>>> getMigrationHistory(Database db) async {
    try {
      return await db.query(
        DatabaseConfig.migrationsTable,
        orderBy: 'version ASC',
      );
    } catch (e) {
      return [];
    }
  }

  /// Check if migration has been applied
  Future<bool> isMigrationApplied(Database db, int version) async {
    try {
      final result = await db.query(
        DatabaseConfig.migrationsTable,
        where: 'version = ?',
        whereArgs: [version],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get pending migrations
  Future<List<BaseMigration>> getPendingMigrations(Database db) async {
    final currentVersion = await getCurrentVersion(db);
    return migrations.where((m) => m.version > currentVersion).toList();
  }

  /// Get applied migrations
  Future<List<BaseMigration>> getAppliedMigrations(Database db) async {
    final currentVersion = await getCurrentVersion(db);
    return migrations.where((m) => m.version <= currentVersion).toList();
  }

  /// Rollback to specific version
  Future<List<MigrationResult>> rollbackToVersion(Database db, int targetVersion) async {
    final currentVersion = await getCurrentVersion(db);
    
    if (targetVersion >= currentVersion) {
      throw MigrationException(
        'Target version $targetVersion must be less than current version $currentVersion',
      );
    }

    return await runMigrations(db, currentVersion, targetVersion);
  }

  /// Rollback last migration
  Future<MigrationResult> rollbackLastMigration(Database db) async {
    final currentVersion = await getCurrentVersion(db);
    
    if (currentVersion == 0) {
      throw MigrationException('No migrations to rollback');
    }

    final results = await rollbackToVersion(db, currentVersion - 1);
    return results.last;
  }

  /// Verify migration integrity
  Future<bool> verifyMigrationIntegrity(Database db) async {
    try {
      final history = await getMigrationHistory(db);
      
      for (final record in history) {
        final version = record['version'] as int;
        final storedChecksum = record['checksum'] as String;
        
        final migration = getMigration(version);
        if (migration == null) {
          return false; // Migration not found
        }
        
        if (migration.checksum != storedChecksum) {
          return false; // Checksum mismatch
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get migration status summary
  Future<MigrationStatus> getMigrationStatus(Database db) async {
    final currentVersion = await getCurrentVersion(db);
    final latestVersion = migrations.isNotEmpty ? migrations.last.version : 0;
    final pendingMigrations = await getPendingMigrations(db);
    final appliedMigrations = await getAppliedMigrations(db);
    final integrityValid = await verifyMigrationIntegrity(db);

    return MigrationStatus(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      pendingMigrations: pendingMigrations,
      appliedMigrations: appliedMigrations,
      integrityValid: integrityValid,
      isUpToDate: currentVersion == latestVersion,
    );
  }

  /// Reset migrations (dangerous - for testing only)
  Future<void> resetMigrations(Database db) async {
    await db.execute('DROP TABLE IF EXISTS ${DatabaseConfig.migrationsTable}');
  }

  /// Create migration batch for multiple operations
  MigrationBatch createBatch(
    Database db,
    int fromVersion,
    int toVersion,
  ) {
    final context = MigrationContext(
      database: db,
      currentVersion: fromVersion,
      targetVersion: toVersion,
    );

    final migrationsToRun = <BaseMigration>[];
    for (final version in context.versionRange) {
      final migration = getMigration(version);
      if (migration != null) {
        migrationsToRun.add(migration);
      }
    }

    return MigrationBatch(
      migrations: migrationsToRun,
      context: context,
    );
  }
}

/// Migration status information
class MigrationStatus {
  const MigrationStatus({
    required this.currentVersion,
    required this.latestVersion,
    required this.pendingMigrations,
    required this.appliedMigrations,
    required this.integrityValid,
    required this.isUpToDate,
  });

  /// Current database version
  final int currentVersion;

  /// Latest available migration version
  final int latestVersion;

  /// List of pending migrations
  final List<BaseMigration> pendingMigrations;

  /// List of applied migrations
  final List<BaseMigration> appliedMigrations;

  /// Whether migration integrity is valid
  final bool integrityValid;

  /// Whether database is up to date
  final bool isUpToDate;

  /// Get status summary
  String get summary {
    if (!integrityValid) {
      return 'Migration integrity check failed';
    }
    
    if (isUpToDate) {
      return 'Database is up to date (version $currentVersion)';
    }
    
    return 'Database needs update: $currentVersion → $latestVersion (${pendingMigrations.length} pending migrations)';
  }

  @override
  String toString() => summary;
}

/// Extension to add firstOrNull to Iterable
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
