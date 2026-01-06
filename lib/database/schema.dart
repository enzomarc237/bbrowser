import 'database_config.dart';

/// Database schema definitions for SQLite tables
class DatabaseSchema {
  /// SQL statements for creating all tables
  static const List<String> createTableStatements = [
    _createMigrationsTable,
    _createBookmarksTable,
    _createHistoryTable,
    _createTabsTable,
    _createSettingsTable,
  ];

  /// SQL statements for creating indexes
  static const List<String> createIndexStatements = [
    _createBookmarksIndexes,
    _createHistoryIndexes,
    _createTabsIndexes,
    _createSettingsIndexes,
  ];

  /// Schema migrations table for version tracking
  static const String _createMigrationsTable = '''
    CREATE TABLE IF NOT EXISTS ${DatabaseConfig.migrationsTable} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version INTEGER NOT NULL UNIQUE,
      name TEXT NOT NULL,
      executed_at INTEGER NOT NULL,
      execution_time_ms INTEGER NOT NULL,
      checksum TEXT NOT NULL
    )
  ''';

  /// Bookmarks table for storing user bookmarks
  static const String _createBookmarksTable = '''
    CREATE TABLE IF NOT EXISTS ${DatabaseConfig.bookmarksTable} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      url TEXT NOT NULL,
      favicon TEXT,
      parent_id TEXT,
      position INTEGER NOT NULL DEFAULT 0,
      is_folder INTEGER NOT NULL DEFAULT 0,
      description TEXT,
      tags TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      last_accessed_at INTEGER,
      access_count INTEGER NOT NULL DEFAULT 0,
      is_pinned INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      metadata TEXT,
      FOREIGN KEY (parent_id) REFERENCES ${DatabaseConfig.bookmarksTable}(id) ON DELETE CASCADE
    )
  ''';

  /// History table for storing browsing history
  static const String _createHistoryTable = '''
    CREATE TABLE IF NOT EXISTS ${DatabaseConfig.historyTable} (
      id TEXT PRIMARY KEY,
      url TEXT NOT NULL,
      title TEXT NOT NULL,
      favicon TEXT,
      visited_at INTEGER NOT NULL,
      visit_duration INTEGER,
      visit_count INTEGER NOT NULL DEFAULT 1,
      last_visit_at INTEGER NOT NULL,
      referrer_url TEXT,
      is_incognito INTEGER NOT NULL DEFAULT 0,
      page_transition TEXT,
      scroll_position REAL,
      form_data TEXT,
      search_terms TEXT,
      domain TEXT NOT NULL,
      path TEXT,
      query_params TEXT,
      fragment TEXT,
      is_bookmarked INTEGER NOT NULL DEFAULT 0,
      is_favorite INTEGER NOT NULL DEFAULT 0,
      rating INTEGER DEFAULT 0,
      notes TEXT,
      metadata TEXT
    )
  ''';

  /// Tabs table for storing tab information
  static const String _createTabsTable = '''
    CREATE TABLE IF NOT EXISTS ${DatabaseConfig.tabsTable} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      url TEXT NOT NULL,
      favicon TEXT,
      position INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 0,
      is_pinned INTEGER NOT NULL DEFAULT 0,
      is_muted INTEGER NOT NULL DEFAULT 0,
      is_loading INTEGER NOT NULL DEFAULT 0,
      can_go_back INTEGER NOT NULL DEFAULT 0,
      can_go_forward INTEGER NOT NULL DEFAULT 0,
      loading_progress REAL NOT NULL DEFAULT 0.0,
      is_secure INTEGER NOT NULL DEFAULT 0,
      has_error INTEGER NOT NULL DEFAULT 0,
      error_message TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      last_accessed_at INTEGER,
      session_id TEXT,
      window_id TEXT,
      group_id TEXT,
      parent_tab_id TEXT,
      zoom_level REAL NOT NULL DEFAULT 1.0,
      scroll_position_x REAL NOT NULL DEFAULT 0.0,
      scroll_position_y REAL NOT NULL DEFAULT 0.0,
      user_agent TEXT,
      referrer_url TEXT,
      navigation_history TEXT,
      form_data TEXT,
      local_storage_data TEXT,
      session_storage_data TEXT,
      cookies_data TEXT,
      permissions TEXT,
      notifications_enabled INTEGER NOT NULL DEFAULT 1,
      javascript_enabled INTEGER NOT NULL DEFAULT 1,
      images_enabled INTEGER NOT NULL DEFAULT 1,
      popup_blocked INTEGER NOT NULL DEFAULT 0,
      download_count INTEGER NOT NULL DEFAULT 0,
      print_count INTEGER NOT NULL DEFAULT 0,
      share_count INTEGER NOT NULL DEFAULT 0,
      bookmark_count INTEGER NOT NULL DEFAULT 0,
      is_private INTEGER NOT NULL DEFAULT 0,
      is_reader_mode INTEGER NOT NULL DEFAULT 0,
      reader_mode_content TEXT,
      custom_css TEXT,
      custom_js TEXT,
      notes TEXT,
      tags TEXT,
      metadata TEXT,
      FOREIGN KEY (parent_tab_id) REFERENCES ${DatabaseConfig.tabsTable}(id) ON DELETE SET NULL
    )
  ''';

  /// Settings table for storing application settings
  static const String _createSettingsTable = '''
    CREATE TABLE IF NOT EXISTS ${DatabaseConfig.settingsTable} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      value_type TEXT NOT NULL DEFAULT 'string',
      description TEXT,
      is_user_setting INTEGER NOT NULL DEFAULT 1,
      is_encrypted INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE(category, key)
    )
  ''';

  /// Indexes for bookmarks table
  static const String _createBookmarksIndexes = '''
    CREATE INDEX IF NOT EXISTS idx_bookmarks_parent_id ON ${DatabaseConfig.bookmarksTable}(parent_id);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_url ON ${DatabaseConfig.bookmarksTable}(url);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_title ON ${DatabaseConfig.bookmarksTable}(title);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_created_at ON ${DatabaseConfig.bookmarksTable}(created_at);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_updated_at ON ${DatabaseConfig.bookmarksTable}(updated_at);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_last_accessed_at ON ${DatabaseConfig.bookmarksTable}(last_accessed_at);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_is_folder ON ${DatabaseConfig.bookmarksTable}(is_folder);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_is_pinned ON ${DatabaseConfig.bookmarksTable}(is_pinned);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_is_archived ON ${DatabaseConfig.bookmarksTable}(is_archived);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_position ON ${DatabaseConfig.bookmarksTable}(parent_id, position);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_tags ON ${DatabaseConfig.bookmarksTable}(tags);
  ''';

  /// Indexes for history table
  static const String _createHistoryIndexes = '''
    CREATE INDEX IF NOT EXISTS idx_history_url ON ${DatabaseConfig.historyTable}(url);
    CREATE INDEX IF NOT EXISTS idx_history_domain ON ${DatabaseConfig.historyTable}(domain);
    CREATE INDEX IF NOT EXISTS idx_history_visited_at ON ${DatabaseConfig.historyTable}(visited_at);
    CREATE INDEX IF NOT EXISTS idx_history_last_visit_at ON ${DatabaseConfig.historyTable}(last_visit_at);
    CREATE INDEX IF NOT EXISTS idx_history_title ON ${DatabaseConfig.historyTable}(title);
    CREATE INDEX IF NOT EXISTS idx_history_visit_count ON ${DatabaseConfig.historyTable}(visit_count);
    CREATE INDEX IF NOT EXISTS idx_history_is_incognito ON ${DatabaseConfig.historyTable}(is_incognito);
    CREATE INDEX IF NOT EXISTS idx_history_is_bookmarked ON ${DatabaseConfig.historyTable}(is_bookmarked);
    CREATE INDEX IF NOT EXISTS idx_history_is_favorite ON ${DatabaseConfig.historyTable}(is_favorite);
    CREATE INDEX IF NOT EXISTS idx_history_search_terms ON ${DatabaseConfig.historyTable}(search_terms);
    CREATE INDEX IF NOT EXISTS idx_history_rating ON ${DatabaseConfig.historyTable}(rating);
    CREATE INDEX IF NOT EXISTS idx_history_domain_visited_at ON ${DatabaseConfig.historyTable}(domain, visited_at);
  ''';

  /// Indexes for tabs table
  static const String _createTabsIndexes = '''
    CREATE INDEX IF NOT EXISTS idx_tabs_position ON ${DatabaseConfig.tabsTable}(position);
    CREATE INDEX IF NOT EXISTS idx_tabs_is_active ON ${DatabaseConfig.tabsTable}(is_active);
    CREATE INDEX IF NOT EXISTS idx_tabs_is_pinned ON ${DatabaseConfig.tabsTable}(is_pinned);
    CREATE INDEX IF NOT EXISTS idx_tabs_created_at ON ${DatabaseConfig.tabsTable}(created_at);
    CREATE INDEX IF NOT EXISTS idx_tabs_updated_at ON ${DatabaseConfig.tabsTable}(updated_at);
    CREATE INDEX IF NOT EXISTS idx_tabs_last_accessed_at ON ${DatabaseConfig.tabsTable}(last_accessed_at);
    CREATE INDEX IF NOT EXISTS idx_tabs_session_id ON ${DatabaseConfig.tabsTable}(session_id);
    CREATE INDEX IF NOT EXISTS idx_tabs_window_id ON ${DatabaseConfig.tabsTable}(window_id);
    CREATE INDEX IF NOT EXISTS idx_tabs_group_id ON ${DatabaseConfig.tabsTable}(group_id);
    CREATE INDEX IF NOT EXISTS idx_tabs_parent_tab_id ON ${DatabaseConfig.tabsTable}(parent_tab_id);
    CREATE INDEX IF NOT EXISTS idx_tabs_url ON ${DatabaseConfig.tabsTable}(url);
    CREATE INDEX IF NOT EXISTS idx_tabs_title ON ${DatabaseConfig.tabsTable}(title);
    CREATE INDEX IF NOT EXISTS idx_tabs_is_private ON ${DatabaseConfig.tabsTable}(is_private);
    CREATE INDEX IF NOT EXISTS idx_tabs_is_reader_mode ON ${DatabaseConfig.tabsTable}(is_reader_mode);
  ''';

  /// Indexes for settings table
  static const String _createSettingsIndexes = '''
    CREATE INDEX IF NOT EXISTS idx_settings_category ON ${DatabaseConfig.settingsTable}(category);
    CREATE INDEX IF NOT EXISTS idx_settings_key ON ${DatabaseConfig.settingsTable}(key);
    CREATE INDEX IF NOT EXISTS idx_settings_category_key ON ${DatabaseConfig.settingsTable}(category, key);
    CREATE INDEX IF NOT EXISTS idx_settings_is_user_setting ON ${DatabaseConfig.settingsTable}(is_user_setting);
    CREATE INDEX IF NOT EXISTS idx_settings_is_encrypted ON ${DatabaseConfig.settingsTable}(is_encrypted);
    CREATE INDEX IF NOT EXISTS idx_settings_updated_at ON ${DatabaseConfig.settingsTable}(updated_at);
  ''';

  /// Triggers for automatic timestamp updates
  static const List<String> createTriggerStatements = [
    _createBookmarksUpdateTrigger,
    _createHistoryUpdateTrigger,
    _createTabsUpdateTrigger,
    _createSettingsUpdateTrigger,
  ];

  /// Trigger for bookmarks table
  static const String _createBookmarksUpdateTrigger = '''
    CREATE TRIGGER IF NOT EXISTS trigger_bookmarks_updated_at
    AFTER UPDATE ON ${DatabaseConfig.bookmarksTable}
    FOR EACH ROW
    BEGIN
      UPDATE ${DatabaseConfig.bookmarksTable}
      SET updated_at = strftime('%s', 'now') * 1000
      WHERE id = NEW.id;
    END
  ''';

  /// Trigger for history table
  static const String _createHistoryUpdateTrigger = '''
    CREATE TRIGGER IF NOT EXISTS trigger_history_last_visit_at
    AFTER UPDATE ON ${DatabaseConfig.historyTable}
    FOR EACH ROW
    WHEN NEW.visit_count > OLD.visit_count
    BEGIN
      UPDATE ${DatabaseConfig.historyTable}
      SET last_visit_at = strftime('%s', 'now') * 1000
      WHERE id = NEW.id;
    END
  ''';

  /// Trigger for tabs table
  static const String _createTabsUpdateTrigger = '''
    CREATE TRIGGER IF NOT EXISTS trigger_tabs_updated_at
    AFTER UPDATE ON ${DatabaseConfig.tabsTable}
    FOR EACH ROW
    BEGIN
      UPDATE ${DatabaseConfig.tabsTable}
      SET updated_at = strftime('%s', 'now') * 1000
      WHERE id = NEW.id;
    END
  ''';

  /// Trigger for settings table
  static const String _createSettingsUpdateTrigger = '''
    CREATE TRIGGER IF NOT EXISTS trigger_settings_updated_at
    AFTER UPDATE ON ${DatabaseConfig.settingsTable}
    FOR EACH ROW
    BEGIN
      UPDATE ${DatabaseConfig.settingsTable}
      SET updated_at = strftime('%s', 'now') * 1000
      WHERE id = NEW.id;
    END
  ''';

  /// Views for common queries
  static const List<String> createViewStatements = [
    _createBookmarkFoldersView,
    _createRecentHistoryView,
    _createActiveTabsView,
    _createUserSettingsView,
  ];

  /// View for bookmark folders
  static const String _createBookmarkFoldersView = '''
    CREATE VIEW IF NOT EXISTS bookmark_folders AS
    SELECT 
      id,
      title,
      parent_id,
      position,
      created_at,
      updated_at,
      (SELECT COUNT(*) FROM ${DatabaseConfig.bookmarksTable} b2 WHERE b2.parent_id = b1.id) as child_count
    FROM ${DatabaseConfig.bookmarksTable} b1
    WHERE is_folder = 1 AND is_archived = 0
    ORDER BY position ASC
  ''';

  /// View for recent history
  static const String _createRecentHistoryView = '''
    CREATE VIEW IF NOT EXISTS recent_history AS
    SELECT 
      id,
      url,
      title,
      favicon,
      visited_at,
      visit_count,
      last_visit_at,
      domain,
      is_bookmarked,
      is_favorite,
      rating
    FROM ${DatabaseConfig.historyTable}
    WHERE is_incognito = 0
    ORDER BY last_visit_at DESC
    LIMIT 1000
  ''';

  /// View for active tabs
  static const String _createActiveTabsView = '''
    CREATE VIEW IF NOT EXISTS active_tabs AS
    SELECT 
      id,
      title,
      url,
      favicon,
      position,
      is_active,
      is_pinned,
      is_loading,
      loading_progress,
      created_at,
      last_accessed_at,
      session_id,
      window_id,
      group_id
    FROM ${DatabaseConfig.tabsTable}
    WHERE is_private = 0
    ORDER BY is_pinned DESC, position ASC
  ''';

  /// View for user settings
  static const String _createUserSettingsView = '''
    CREATE VIEW IF NOT EXISTS user_settings AS
    SELECT 
      category,
      key,
      value,
      value_type,
      description,
      updated_at
    FROM ${DatabaseConfig.settingsTable}
    WHERE is_user_setting = 1
    ORDER BY category ASC, key ASC
  ''';

  /// Get all schema creation statements in order
  static List<String> getAllSchemaStatements() {
    final statements = <String>[];
    
    // Add table creation statements
    statements.addAll(createTableStatements);
    
    // Add index creation statements (split by semicolon)
    for (final indexStatement in createIndexStatements) {
      statements.addAll(
        indexStatement
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    }
    
    // Add trigger creation statements
    statements.addAll(createTriggerStatements);
    
    // Add view creation statements
    statements.addAll(createViewStatements);
    
    return statements;
  }

  /// Get table names
  static List<String> getTableNames() {
    return [
      DatabaseConfig.migrationsTable,
      DatabaseConfig.bookmarksTable,
      DatabaseConfig.historyTable,
      DatabaseConfig.tabsTable,
      DatabaseConfig.settingsTable,
    ];
  }

  /// Get view names
  static List<String> getViewNames() {
    return [
      'bookmark_folders',
      'recent_history',
      'active_tabs',
      'user_settings',
    ];
  }

  /// Validate schema integrity
  static bool validateSchema(List<Map<String, dynamic>> tables) {
    final expectedTables = getTableNames();
    final actualTables = tables
        .where((table) => table['type'] == 'table')
        .map((table) => table['name'] as String)
        .toSet();

    // Check if all expected tables exist
    for (final tableName in expectedTables) {
      if (!actualTables.contains(tableName)) {
        return false;
      }
    }

    return true;
  }

  /// Get foreign key constraints
  static Map<String, List<String>> getForeignKeyConstraints() {
    return {
      DatabaseConfig.bookmarksTable: [
        'FOREIGN KEY (parent_id) REFERENCES ${DatabaseConfig.bookmarksTable}(id) ON DELETE CASCADE',
      ],
      DatabaseConfig.tabsTable: [
        'FOREIGN KEY (parent_tab_id) REFERENCES ${DatabaseConfig.tabsTable}(id) ON DELETE SET NULL',
      ],
    };
  }

  /// Get column definitions for a table
  static Map<String, String> getColumnDefinitions(String tableName) {
    switch (tableName) {
      case DatabaseConfig.bookmarksTable:
        return {
          'id': 'TEXT PRIMARY KEY',
          'title': 'TEXT NOT NULL',
          'url': 'TEXT NOT NULL',
          'favicon': 'TEXT',
          'parent_id': 'TEXT',
          'position': 'INTEGER NOT NULL DEFAULT 0',
          'is_folder': 'INTEGER NOT NULL DEFAULT 0',
          'description': 'TEXT',
          'tags': 'TEXT',
          'created_at': 'INTEGER NOT NULL',
          'updated_at': 'INTEGER NOT NULL',
          'last_accessed_at': 'INTEGER',
          'access_count': 'INTEGER NOT NULL DEFAULT 0',
          'is_pinned': 'INTEGER NOT NULL DEFAULT 0',
          'is_archived': 'INTEGER NOT NULL DEFAULT 0',
          'metadata': 'TEXT',
        };
      case DatabaseConfig.historyTable:
        return {
          'id': 'TEXT PRIMARY KEY',
          'url': 'TEXT NOT NULL',
          'title': 'TEXT NOT NULL',
          'favicon': 'TEXT',
          'visited_at': 'INTEGER NOT NULL',
          'visit_duration': 'INTEGER',
          'visit_count': 'INTEGER NOT NULL DEFAULT 1',
          'last_visit_at': 'INTEGER NOT NULL',
          'referrer_url': 'TEXT',
          'is_incognito': 'INTEGER NOT NULL DEFAULT 0',
          'page_transition': 'TEXT',
          'scroll_position': 'REAL',
          'form_data': 'TEXT',
          'search_terms': 'TEXT',
          'domain': 'TEXT NOT NULL',
          'path': 'TEXT',
          'query_params': 'TEXT',
          'fragment': 'TEXT',
          'is_bookmarked': 'INTEGER NOT NULL DEFAULT 0',
          'is_favorite': 'INTEGER NOT NULL DEFAULT 0',
          'rating': 'INTEGER DEFAULT 0',
          'notes': 'TEXT',
          'metadata': 'TEXT',
        };
      case DatabaseConfig.tabsTable:
        return {
          'id': 'TEXT PRIMARY KEY',
          'title': 'TEXT NOT NULL',
          'url': 'TEXT NOT NULL',
          'favicon': 'TEXT',
          'position': 'INTEGER NOT NULL DEFAULT 0',
          'is_active': 'INTEGER NOT NULL DEFAULT 0',
          'is_pinned': 'INTEGER NOT NULL DEFAULT 0',
          'is_muted': 'INTEGER NOT NULL DEFAULT 0',
          'is_loading': 'INTEGER NOT NULL DEFAULT 0',
          'can_go_back': 'INTEGER NOT NULL DEFAULT 0',
          'can_go_forward': 'INTEGER NOT NULL DEFAULT 0',
          'loading_progress': 'REAL NOT NULL DEFAULT 0.0',
          'is_secure': 'INTEGER NOT NULL DEFAULT 0',
          'has_error': 'INTEGER NOT NULL DEFAULT 0',
          'error_message': 'TEXT',
          'created_at': 'INTEGER NOT NULL',
          'updated_at': 'INTEGER NOT NULL',
          'last_accessed_at': 'INTEGER',
          'session_id': 'TEXT',
          'window_id': 'TEXT',
          'group_id': 'TEXT',
          'parent_tab_id': 'TEXT',
          'zoom_level': 'REAL NOT NULL DEFAULT 1.0',
          'scroll_position_x': 'REAL NOT NULL DEFAULT 0.0',
          'scroll_position_y': 'REAL NOT NULL DEFAULT 0.0',
          'user_agent': 'TEXT',
          'referrer_url': 'TEXT',
          'navigation_history': 'TEXT',
          'form_data': 'TEXT',
          'local_storage_data': 'TEXT',
          'session_storage_data': 'TEXT',
          'cookies_data': 'TEXT',
          'permissions': 'TEXT',
          'notifications_enabled': 'INTEGER NOT NULL DEFAULT 1',
          'javascript_enabled': 'INTEGER NOT NULL DEFAULT 1',
          'images_enabled': 'INTEGER NOT NULL DEFAULT 1',
          'popup_blocked': 'INTEGER NOT NULL DEFAULT 0',
          'download_count': 'INTEGER NOT NULL DEFAULT 0',
          'print_count': 'INTEGER NOT NULL DEFAULT 0',
          'share_count': 'INTEGER NOT NULL DEFAULT 0',
          'bookmark_count': 'INTEGER NOT NULL DEFAULT 0',
          'is_private': 'INTEGER NOT NULL DEFAULT 0',
          'is_reader_mode': 'INTEGER NOT NULL DEFAULT 0',
          'reader_mode_content': 'TEXT',
          'custom_css': 'TEXT',
          'custom_js': 'TEXT',
          'notes': 'TEXT',
          'tags': 'TEXT',
          'metadata': 'TEXT',
        };
      case DatabaseConfig.settingsTable:
        return {
          'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
          'category': 'TEXT NOT NULL',
          'key': 'TEXT NOT NULL',
          'value': 'TEXT NOT NULL',
          'value_type': 'TEXT NOT NULL DEFAULT \'string\'',
          'description': 'TEXT',
          'is_user_setting': 'INTEGER NOT NULL DEFAULT 1',
          'is_encrypted': 'INTEGER NOT NULL DEFAULT 0',
          'created_at': 'INTEGER NOT NULL',
          'updated_at': 'INTEGER NOT NULL',
        };
      default:
        return {};
    }
  }
}
