/// Database configuration constants and settings
class DatabaseConfig {
  // Database names and versions
  static const String sqliteDatabaseName = 'bbrowser.db';
  static const int currentSchemaVersion = 1;
  
  // Hive box names
  static const String sessionBoxName = 'session_data';
  static const String cacheBoxName = 'cache_data';
  static const String preferencesBoxName = 'preferences_data';
  static const String tempDataBoxName = 'temp_data';
  
  // SQLite table names
  static const String bookmarksTable = 'bookmarks';
  static const String historyTable = 'history';
  static const String tabsTable = 'tabs';
  static const String settingsTable = 'settings';
  static const String migrationsTable = 'schema_migrations';
  
  // Performance settings
  static const int connectionPoolSize = 5;
  static const int queryTimeoutSeconds = 30;
  static const int cacheMaxSize = 1000;
  static const Duration cacheExpiration = Duration(hours: 1);
  
  // Security settings
  static const String encryptionKeyAlias = 'bbrowser_encryption_key';
  static const int encryptionKeyLength = 256;
  
  // Backup settings
  static const String backupFilePrefix = 'bbrowser_backup_';
  static const String backupFileExtension = '.bak';
  static const int maxBackupFiles = 5;
  
  // Migration settings
  static const bool enableAutoMigration = true;
  static const bool enableMigrationRollback = true;
  static const Duration migrationTimeout = Duration(minutes: 5);
}
