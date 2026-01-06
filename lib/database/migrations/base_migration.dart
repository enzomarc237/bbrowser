import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:crypto';

/// Base class for all database migrations
abstract class BaseMigration {
  /// Version number for this migration
  int get version;

  /// Human-readable name for this migration
  String get name;

  /// Description of what this migration does
  String get description;

  /// SQL statements to execute for upgrading
  List<String> get upgradeStatements;

  /// SQL statements to execute for downgrading (optional)
  List<String> get downgradeStatements => [];

  /// Whether this migration supports rollback
  bool get supportsRollback => downgradeStatements.isNotEmpty;

  /// Dependencies - other migration versions that must be applied first
  List<int> get dependencies => [];

  /// Execute the migration upgrade
  Future<void> upgrade(Database db) async {
    await _executeMigration(db, upgradeStatements, 'upgrade');
  }

  /// Execute the migration downgrade
  Future<void> downgrade(Database db) async {
    if (!supportsRollback) {
      throw MigrationException(
        'Migration $version ($name) does not support rollback',
      );
    }
    await _executeMigration(db, downgradeStatements, 'downgrade');
  }

  /// Execute migration statements with transaction support
  Future<void> _executeMigration(
    Database db,
    List<String> statements,
    String operation,
  ) async {
    if (statements.isEmpty) return;

    await db.transaction((txn) async {
      for (final statement in statements) {
        if (statement.trim().isEmpty) continue;
        
        try {
          await txn.execute(statement);
        } catch (e) {
          throw MigrationException(
            'Failed to execute $operation statement in migration $version ($name): $e\n'
            'Statement: $statement',
          );
        }
      }
    });
  }

  /// Validate migration before execution
  Future<bool> validate(Database db) async {
    try {
      // Check if all dependencies are satisfied
      for (final dependency in dependencies) {
        final result = await db.query(
          'schema_migrations',
          where: 'version = ?',
          whereArgs: [dependency],
        );
        
        if (result.isEmpty) {
          throw MigrationException(
            'Migration $version ($name) depends on migration $dependency which has not been applied',
          );
        }
      }

      // Validate SQL syntax by preparing statements
      for (final statement in upgradeStatements) {
        if (statement.trim().isEmpty) continue;
        
        // Basic SQL validation - check for common issues
        if (!_isValidSqlStatement(statement)) {
          throw MigrationException(
            'Invalid SQL statement in migration $version ($name): $statement',
          );
        }
      }

      return true;
    } catch (e) {
      if (e is MigrationException) rethrow;
      throw MigrationException('Migration validation failed: $e');
    }
  }

  /// Basic SQL statement validation
  bool _isValidSqlStatement(String statement) {
    final trimmed = statement.trim().toUpperCase();
    
    // Check for empty statements
    if (trimmed.isEmpty) return false;
    
    // Check for dangerous statements in production
    final dangerousKeywords = ['DROP DATABASE', 'TRUNCATE', 'DELETE FROM'];
    for (final keyword in dangerousKeywords) {
      if (trimmed.contains(keyword) && !_isAllowedDangerousStatement(trimmed)) {
        return false;
      }
    }
    
    // Check for basic SQL structure
    final validStarters = [
      'CREATE', 'ALTER', 'DROP', 'INSERT', 'UPDATE', 'DELETE',
      'PRAGMA', 'WITH', 'SELECT'
    ];
    
    return validStarters.any((starter) => trimmed.startsWith(starter));
  }

  /// Check if a dangerous statement is allowed (e.g., for cleanup)
  bool _isAllowedDangerousStatement(String statement) {
    // Override in specific migrations if needed
    return false;
  }

  /// Get migration checksum for integrity verification
  String get checksum {
    final content = '$version:$name:${upgradeStatements.join(';')}';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get migration metadata
  Map<String, dynamic> get metadata => {
    'version': version,
    'name': name,
    'description': description,
    'checksum': checksum,
    'supports_rollback': supportsRollback,
    'dependencies': dependencies,
    'upgrade_statements_count': upgradeStatements.length,
    'downgrade_statements_count': downgradeStatements.length,
  };

  /// Estimate migration execution time (in milliseconds)
  int get estimatedExecutionTime {
    // Base time per statement + complexity factor
    const baseTimePerStatement = 100; // ms
    const complexityFactor = 50; // ms per character in statement
    
    int totalTime = 0;
    for (final statement in upgradeStatements) {
      totalTime += baseTimePerStatement + (statement.length * complexityFactor ~/ 1000);
    }
    
    return totalTime;
  }

  /// Check if migration affects specific tables
  bool affectsTable(String tableName) {
    final upperTableName = tableName.toUpperCase();
    return upgradeStatements.any((statement) =>
        statement.toUpperCase().contains(upperTableName));
  }

  /// Get list of tables affected by this migration
  Set<String> get affectedTables {
    final tables = <String>{};
    final tableRegex = RegExp(r'\b(?:CREATE|ALTER|DROP)\s+TABLE\s+(?:IF\s+(?:NOT\s+)?EXISTS\s+)?(\w+)', caseSensitive: false);
    
    for (final statement in upgradeStatements) {
      final matches = tableRegex.allMatches(statement);
      for (final match in matches) {
        final tableName = match.group(1);
        if (tableName != null) {
          tables.add(tableName.toLowerCase());
        }
      }
    }
    
    return tables;
  }

  /// Check if migration is reversible
  bool get isReversible => supportsRollback;

  /// Get migration type based on operations
  MigrationType get type {
    final statements = upgradeStatements.join(' ').toUpperCase();
    
    if (statements.contains('CREATE TABLE')) {
      return MigrationType.schema;
    } else if (statements.contains('ALTER TABLE')) {
      return MigrationType.schema;
    } else if (statements.contains('INSERT') || statements.contains('UPDATE')) {
      return MigrationType.data;
    } else if (statements.contains('CREATE INDEX')) {
      return MigrationType.index;
    } else if (statements.contains('CREATE TRIGGER') || statements.contains('CREATE VIEW')) {
      return MigrationType.structure;
    }
    
    return MigrationType.other;
  }

  /// Pre-migration hook - called before migration execution
  Future<void> beforeMigration(Database db) async {
    // Override in subclasses if needed
  }

  /// Post-migration hook - called after successful migration execution
  Future<void> afterMigration(Database db) async {
    // Override in subclasses if needed
  }

  /// Cleanup hook - called if migration fails
  Future<void> onMigrationFailure(Database db, Object error) async {
    // Override in subclasses if needed
  }

  @override
  String toString() {
    return 'Migration(version: $version, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseMigration && other.version == version;
  }

  @override
  int get hashCode => version.hashCode;
}

/// Types of migrations
enum MigrationType {
  schema,    // Table creation/modification
  data,      // Data insertion/updates
  index,     // Index creation/modification
  structure, // Views, triggers, procedures
  other,     // Other operations
}

/// Migration execution result
class MigrationResult {
  const MigrationResult({
    required this.migration,
    required this.success,
    required this.executionTime,
    this.error,
    this.affectedRows,
  });

  /// The migration that was executed
  final BaseMigration migration;

  /// Whether the migration succeeded
  final bool success;

  /// How long the migration took to execute (in milliseconds)
  final int executionTime;

  /// Error message if migration failed
  final String? error;

  /// Number of rows affected (if applicable)
  final int? affectedRows;

  /// Get result summary
  String get summary {
    if (success) {
      return 'Migration ${migration.version} (${migration.name}) completed successfully in ${executionTime}ms';
    } else {
      return 'Migration ${migration.version} (${migration.name}) failed: $error';
    }
  }

  @override
  String toString() => summary;
}

/// Custom exception for migration errors
class MigrationException implements Exception {
  const MigrationException(this.message);

  final String message;

  @override
  String toString() => 'MigrationException: $message';
}

/// Migration execution context
class MigrationContext {
  const MigrationContext({
    required this.database,
    required this.currentVersion,
    required this.targetVersion,
    this.dryRun = false,
    this.skipValidation = false,
    this.continueOnError = false,
  });

  /// Database instance
  final Database database;

  /// Current schema version
  final int currentVersion;

  /// Target schema version
  final int targetVersion;

  /// Whether to perform a dry run (validation only)
  final bool dryRun;

  /// Whether to skip migration validation
  final bool skipValidation;

  /// Whether to continue on non-critical errors
  final bool continueOnError;

  /// Whether this is an upgrade operation
  bool get isUpgrade => targetVersion > currentVersion;

  /// Whether this is a downgrade operation
  bool get isDowngrade => targetVersion < currentVersion;

  /// Get version range for migration
  List<int> get versionRange {
    if (isUpgrade) {
      return List.generate(
        targetVersion - currentVersion,
        (index) => currentVersion + index + 1,
      );
    } else {
      return List.generate(
        currentVersion - targetVersion,
        (index) => currentVersion - index,
      ).reversed.toList();
    }
  }
}

/// Migration batch for executing multiple migrations
class MigrationBatch {
  const MigrationBatch({
    required this.migrations,
    required this.context,
  });

  /// List of migrations to execute
  final List<BaseMigration> migrations;

  /// Execution context
  final MigrationContext context;

  /// Get total estimated execution time
  int get estimatedExecutionTime {
    return migrations.fold(0, (total, migration) => total + migration.estimatedExecutionTime);
  }

  /// Get all affected tables
  Set<String> get affectedTables {
    final tables = <String>{};
    for (final migration in migrations) {
      tables.addAll(migration.affectedTables);
    }
    return tables;
  }

  /// Check if batch is reversible
  bool get isReversible {
    return migrations.every((migration) => migration.isReversible);
  }

  /// Get batch summary
  String get summary {
    return 'Migration batch: ${migrations.length} migrations, '
           'estimated time: ${estimatedExecutionTime}ms, '
           'affected tables: ${affectedTables.join(', ')}';
  }
}
