import 'package:sqflite/sqflite.dart';
import 'base_migration.dart';
import '../schema.dart';

/// Initial migration to create the database schema
class MigrationV1_0_0 extends BaseMigration {
  @override
  int get version => 1;

  @override
  String get name => 'initial_schema';

  @override
  String get description => 'Create initial database schema with all tables, indexes, triggers, and views';

  @override
  List<String> get upgradeStatements => DatabaseSchema.getAllSchemaStatements();

  @override
  List<String> get downgradeStatements => [
    // Drop views first
    'DROP VIEW IF EXISTS user_settings',
    'DROP VIEW IF EXISTS active_tabs',
    'DROP VIEW IF EXISTS recent_history',
    'DROP VIEW IF EXISTS bookmark_folders',
    
    // Drop triggers
    'DROP TRIGGER IF EXISTS trigger_settings_updated_at',
    'DROP TRIGGER IF EXISTS trigger_tabs_updated_at',
    'DROP TRIGGER IF EXISTS trigger_history_last_visit_at',
    'DROP TRIGGER IF EXISTS trigger_bookmarks_updated_at',
    
    // Drop indexes (they will be dropped automatically with tables, but explicit for clarity)
    'DROP INDEX IF EXISTS idx_settings_updated_at',
    'DROP INDEX IF EXISTS idx_settings_is_encrypted',
    'DROP INDEX IF EXISTS idx_settings_is_user_setting',
    'DROP INDEX IF EXISTS idx_settings_category_key',
    'DROP INDEX IF EXISTS idx_settings_key',
    'DROP INDEX IF EXISTS idx_settings_category',
    
    'DROP INDEX IF EXISTS idx_tabs_is_reader_mode',
    'DROP INDEX IF EXISTS idx_tabs_is_private',
    'DROP INDEX IF EXISTS idx_tabs_title',
    'DROP INDEX IF EXISTS idx_tabs_url',
    'DROP INDEX IF EXISTS idx_tabs_parent_tab_id',
    'DROP INDEX IF EXISTS idx_tabs_group_id',
    'DROP INDEX IF EXISTS idx_tabs_window_id',
    'DROP INDEX IF EXISTS idx_tabs_session_id',
    'DROP INDEX IF EXISTS idx_tabs_last_accessed_at',
    'DROP INDEX IF EXISTS idx_tabs_updated_at',
    'DROP INDEX IF EXISTS idx_tabs_created_at',
    'DROP INDEX IF EXISTS idx_tabs_is_pinned',
    'DROP INDEX IF EXISTS idx_tabs_is_active',
    'DROP INDEX IF EXISTS idx_tabs_position',
    
    'DROP INDEX IF EXISTS idx_history_domain_visited_at',
    'DROP INDEX IF EXISTS idx_history_rating',
    'DROP INDEX IF EXISTS idx_history_search_terms',
    'DROP INDEX IF EXISTS idx_history_is_favorite',
    'DROP INDEX IF EXISTS idx_history_is_bookmarked',
    'DROP INDEX IF EXISTS idx_history_is_incognito',
    'DROP INDEX IF EXISTS idx_history_visit_count',
    'DROP INDEX IF EXISTS idx_history_title',
    'DROP INDEX IF EXISTS idx_history_last_visit_at',
    'DROP INDEX IF EXISTS idx_history_visited_at',
    'DROP INDEX IF EXISTS idx_history_domain',
    'DROP INDEX IF EXISTS idx_history_url',
    
    'DROP INDEX IF EXISTS idx_bookmarks_tags',
    'DROP INDEX IF EXISTS idx_bookmarks_position',
    'DROP INDEX IF EXISTS idx_bookmarks_is_archived',
    'DROP INDEX IF EXISTS idx_bookmarks_is_pinned',
    'DROP INDEX IF EXISTS idx_bookmarks_is_folder',
    'DROP INDEX IF EXISTS idx_bookmarks_last_accessed_at',
    'DROP INDEX IF EXISTS idx_bookmarks_updated_at',
    'DROP INDEX IF EXISTS idx_bookmarks_created_at',
    'DROP INDEX IF EXISTS idx_bookmarks_title',
    'DROP INDEX IF EXISTS idx_bookmarks_url',
    'DROP INDEX IF EXISTS idx_bookmarks_parent_id',
    
    // Drop tables in reverse dependency order
    'DROP TABLE IF EXISTS settings',
    'DROP TABLE IF EXISTS tabs',
    'DROP TABLE IF EXISTS history',
    'DROP TABLE IF EXISTS bookmarks',
    'DROP TABLE IF EXISTS schema_migrations',
  ];

  @override
  bool get supportsRollback => true;

  @override
  Future<void> beforeMigration(Database db) async {
    // Verify we're starting with a clean database
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    
    if (tables.isNotEmpty) {
      final tableNames = tables.map((t) => t['name']).join(', ');
      throw MigrationException(
        'Database is not empty. Found existing tables: $tableNames. '
        'This migration should only be run on a fresh database.',
      );
    }
  }

  @override
  Future<void> afterMigration(Database db) async {
    // Verify all tables were created successfully
    final expectedTables = DatabaseSchema.getTableNames();
    final actualTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    
    final actualTableNames = actualTables.map((t) => t['name'] as String).toSet();
    
    for (final expectedTable in expectedTables) {
      if (!actualTableNames.contains(expectedTable)) {
        throw MigrationException(
          'Table $expectedTable was not created successfully',
        );
      }
    }

    // Verify all views were created successfully
    final expectedViews = DatabaseSchema.getViewNames();
    final actualViews = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='view'",
    );
    
    final actualViewNames = actualViews.map((v) => v['name'] as String).toSet();
    
    for (final expectedView in expectedViews) {
      if (!actualViewNames.contains(expectedView)) {
        throw MigrationException(
          'View $expectedView was not created successfully',
        );
      }
    }

    // Verify foreign key constraints are enabled
    final pragmaResult = await db.rawQuery('PRAGMA foreign_keys');
    final foreignKeysEnabled = pragmaResult.first['foreign_keys'] == 1;
    
    if (!foreignKeysEnabled) {
      throw MigrationException(
        'Foreign key constraints are not enabled',
      );
    }

    // Insert default settings
    await _insertDefaultSettings(db);
    
    // Verify database integrity
    final integrityResult = await db.rawQuery('PRAGMA integrity_check');
    final integrityStatus = integrityResult.first.values.first as String;
    
    if (integrityStatus != 'ok') {
      throw MigrationException(
        'Database integrity check failed: $integrityStatus',
      );
    }
  }

  /// Insert default application settings
  Future<void> _insertDefaultSettings(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final defaultSettings = [
      // General settings
      {
        'category': 'general',
        'key': 'default_search_engine',
        'value': 'https://www.google.com/search?q=%s',
        'value_type': 'string',
        'description': 'Default search engine URL',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'category': 'general',
        'key': 'home_page',
        'value': 'about:blank',
        'value_type': 'string',
        'description': 'Home page URL',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'category': 'general',
        'key': 'startup_behavior',
        'value': 'restore_session',
        'value_type': 'string',
        'description': 'What to do on startup (new_tab, home_page, restore_session)',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      
      // Privacy settings
      {
        'category': 'privacy',
        'key': 'tracking_protection',
        'value': 'true',
        'value_type': 'boolean',
        'description': 'Enable tracking protection',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'category': 'privacy',
        'key': 'cookie_policy',
        'value': 'block_third_party',
        'value_type': 'string',
        'description': 'Cookie acceptance policy (accept_all, block_third_party, block_all)',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      
      // Appearance settings
      {
        'category': 'appearance',
        'key': 'theme',
        'value': 'system',
        'value_type': 'string',
        'description': 'UI theme (light, dark, system)',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'category': 'appearance',
        'key': 'font_size',
        'value': '16',
        'value_type': 'integer',
        'description': 'Default font size in pixels',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      
      // Security settings
      {
        'category': 'security',
        'key': 'https_only',
        'value': 'false',
        'value_type': 'boolean',
        'description': 'Force HTTPS connections when possible',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'category': 'security',
        'key': 'safe_browsing',
        'value': 'true',
        'value_type': 'boolean',
        'description': 'Enable safe browsing protection',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      
      // Performance settings
      {
        'category': 'performance',
        'key': 'hardware_acceleration',
        'value': 'true',
        'value_type': 'boolean',
        'description': 'Use hardware acceleration when available',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      
      // Content settings
      {
        'category': 'content',
        'key': 'javascript_enabled',
        'value': 'true',
        'value_type': 'boolean',
        'description': 'Enable JavaScript execution',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'category': 'content',
        'key': 'popup_blocking',
        'value': 'true',
        'value_type': 'boolean',
        'description': 'Block popup windows',
        'is_user_setting': 1,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      
      // System settings (not user-configurable)
      {
        'category': 'system',
        'key': 'database_version',
        'value': '1',
        'value_type': 'integer',
        'description': 'Current database schema version',
        'is_user_setting': 0,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'category': 'system',
        'key': 'first_run',
        'value': 'true',
        'value_type': 'boolean',
        'description': 'Whether this is the first run of the application',
        'is_user_setting': 0,
        'is_encrypted': 0,
        'created_at': now,
        'updated_at': now,
      },
    ];

    // Insert all default settings
    for (final setting in defaultSettings) {
      await db.insert('settings', setting);
    }
  }

  @override
  Future<void> onMigrationFailure(Database db, Object error) async {
    // Clean up any partially created objects
    try {
      // Drop any tables that might have been created
      final tables = DatabaseSchema.getTableNames();
      for (final table in tables.reversed) {
        await db.execute('DROP TABLE IF EXISTS $table');
      }
      
      // Drop any views that might have been created
      final views = DatabaseSchema.getViewNames();
      for (final view in views.reversed) {
        await db.execute('DROP VIEW IF EXISTS $view');
      }
    } catch (e) {
      // Ignore cleanup errors - the main error is more important
    }
  }

  @override
  bool _isAllowedDangerousStatement(String statement) {
    // Allow DROP statements in the downgrade for cleanup
    return statement.startsWith('DROP');
  }
}
