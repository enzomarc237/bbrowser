import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../database/database_config.dart';
import '../repositories/bookmark_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/preference_repository.dart';
import '../repositories/folder_repository.dart';
import '../repositories/tab_repository.dart';

/// Service for backing up and restoring browser data
class BackupService {
  final BookmarkRepository _bookmarkRepository;
  final HistoryRepository _historyRepository;
  final PreferenceRepository _preferenceRepository;
  final FolderRepository _folderRepository;
  final TabRepository _tabRepository;

  BackupService({
    BookmarkRepository? bookmarkRepository,
    HistoryRepository? historyRepository,
    PreferenceRepository? preferenceRepository,
    FolderRepository? folderRepository,
    TabRepository? tabRepository,
  }) : _bookmarkRepository = bookmarkRepository ?? BookmarkRepository(),
       _historyRepository = historyRepository ?? HistoryRepository(),
       _preferenceRepository = preferenceRepository ?? PreferenceRepository(),
       _folderRepository = folderRepository ?? FolderRepository(),
       _tabRepository = tabRepository ?? TabRepository();

  /// Create a complete backup of all browser data
  Future<File> createFullBackup({String? customPath}) async {
    try {
      final backupData = await _gatherAllData();
      final backupFile = await _createBackupFile(backupData, customPath);
      return backupFile;
    } catch (e) {
      throw BackupServiceException('Failed to create full backup: $e');
    }
  }

  /// Create a partial backup with selected data types
  Future<File> createPartialBackup({
    bool includeBookmarks = true,
    bool includeHistory = false,
    bool includePreferences = true,
    bool includeFolders = true,
    bool includeTabs = false,
    String? customPath,
  }) async {
    try {
      final backupData = await _gatherPartialData(
        includeBookmarks: includeBookmarks,
        includeHistory: includeHistory,
        includePreferences: includePreferences,
        includeFolders: includeFolders,
        includeTabs: includeTabs,
      );
      
      final backupFile = await _createBackupFile(backupData, customPath);
      return backupFile;
    } catch (e) {
      throw BackupServiceException('Failed to create partial backup: $e');
    }
  }

  /// Restore data from backup file
  Future<BackupRestoreResult> restoreFromBackup(
    String backupFilePath, {
    bool restoreBookmarks = true,
    bool restoreHistory = false,
    bool restorePreferences = true,
    bool restoreFolders = true,
    bool restoreTabs = false,
    bool overwriteExisting = false,
  }) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw BackupServiceException('Backup file not found');
      }

      final backupContent = await backupFile.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
      
      // Validate backup format
      _validateBackupFormat(backupData);
      
      final result = BackupRestoreResult();
      
      // Restore folders first (dependencies)
      if (restoreFolders && backupData.containsKey('folders')) {
        result.foldersRestored = await _restoreFolders(
          backupData['folders'] as List<dynamic>,
          overwriteExisting,
        );
      }
      
      // Restore preferences
      if (restorePreferences && backupData.containsKey('preferences')) {
        result.preferencesRestored = await _restorePreferences(
          backupData['preferences'] as List<dynamic>,
          overwriteExisting,
        );
      }
      
      // Restore bookmarks
      if (restoreBookmarks && backupData.containsKey('bookmarks')) {
        result.bookmarksRestored = await _restoreBookmarks(
          backupData['bookmarks'] as List<dynamic>,
          overwriteExisting,
        );
      }
      
      // Restore history
      if (restoreHistory && backupData.containsKey('history')) {
        result.historyRestored = await _restoreHistory(
          backupData['history'] as List<dynamic>,
          overwriteExisting,
        );
      }
      
      // Restore tabs
      if (restoreTabs && backupData.containsKey('tabs')) {
        result.tabsRestored = await _restoreTabs(
          backupData['tabs'] as List<dynamic>,
          overwriteExisting,
        );
      }
      
      return result;
    } catch (e) {
      throw BackupServiceException('Failed to restore from backup: $e');
    }
  }

  /// Get list of available backup files
  Future<List<BackupFileInfo>> getAvailableBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFiles = <BackupFileInfo>[];
      
      if (await backupDir.exists()) {
        await for (final entity in backupDir.list()) {
          if (entity is File && entity.path.endsWith(DatabaseConfig.backupFileExtension)) {
            final info = await _getBackupFileInfo(entity);
            backupFiles.add(info);
          }
        }
      }
      
      // Sort by creation date (newest first)
      backupFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return backupFiles;
    } catch (e) {
      throw BackupServiceException('Failed to get available backups: $e');
    }
  }

  /// Delete old backup files
  Future<int> cleanupOldBackups({int maxBackups = 5}) async {
    try {
      final backups = await getAvailableBackups();
      int deletedCount = 0;
      
      if (backups.length > maxBackups) {
        final backupsToDelete = backups.skip(maxBackups);
        
        for (final backup in backupsToDelete) {
          final file = File(backup.filePath);
          if (await file.exists()) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      throw BackupServiceException('Failed to cleanup old backups: $e');
    }
  }

  /// Validate backup file integrity
  Future<bool> validateBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return false;
      }

      final backupContent = await backupFile.readAsString();
      final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
      
      _validateBackupFormat(backupData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get backup file information
  Future<BackupFileInfo> getBackupInfo(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      return await _getBackupFileInfo(backupFile);
    } catch (e) {
      throw BackupServiceException('Failed to get backup info: $e');
    }
  }

  /// Export specific data type to JSON
  Future<String> exportBookmarksToJson({String? folderId}) async {
    return await _bookmarkRepository.exportToJson(folderId: folderId);
  }

  Future<String> exportHistoryToJson({DateTime? startDate, DateTime? endDate}) async {
    return await _historyRepository.exportToJson(startDate: startDate, endDate: endDate);
  }

  Future<String> exportPreferencesToJson({String? category}) async {
    return await _preferenceRepository.exportToJson(category: category);
  }

  Future<String> exportFoldersToJson() async {
    return await _folderRepository.exportToJson();
  }

  Future<String> exportTabsToJson({String? sessionId}) async {
    return await _tabRepository.exportToJson(sessionId: sessionId);
  }

  /// Gather all data for backup
  Future<Map<String, dynamic>> _gatherAllData() async {
    return await _gatherPartialData(
      includeBookmarks: true,
      includeHistory: true,
      includePreferences: true,
      includeFolders: true,
      includeTabs: true,
    );
  }

  /// Gather partial data for backup
  Future<Map<String, dynamic>> _gatherPartialData({
    bool includeBookmarks = true,
    bool includeHistory = false,
    bool includePreferences = true,
    bool includeFolders = true,
    bool includeTabs = false,
  }) async {
    final data = <String, dynamic>{
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // Should come from app config
    };

    if (includeFolders) {
      final folders = await _folderRepository.getAll();
      data['folders'] = folders.map((f) => f.toJson()).toList();
    }

    if (includeBookmarks) {
      final bookmarks = await _bookmarkRepository.getAll();
      data['bookmarks'] = bookmarks.map((b) => b.toJson()).toList();
    }

    if (includeHistory) {
      final history = await _historyRepository.getAll();
      data['history'] = history.map((h) => h.toJson()).toList();
    }

    if (includePreferences) {
      final preferences = await _preferenceRepository.getAll();
      data['preferences'] = preferences.map((p) => p.toJson()).toList();
    }

    if (includeTabs) {
      final tabs = await _tabRepository.getAll();
      data['tabs'] = tabs.map((t) => t.toJson()).toList();
    }

    return data;
  }

  /// Create backup file
  Future<File> _createBackupFile(Map<String, dynamic> backupData, String? customPath) async {
    final backupDir = await _getBackupDirectory();
    await backupDir.create(recursive: true);
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '${DatabaseConfig.backupFilePrefix}$timestamp${DatabaseConfig.backupFileExtension}';
    
    final filePath = customPath ?? path.join(backupDir.path, fileName);
    final backupFile = File(filePath);
    
    final backupJson = jsonEncode(backupData);
    await backupFile.writeAsString(backupJson);
    
    return backupFile;
  }

  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(documentsDir.path, 'backups'));
  }

  /// Get backup file information
  Future<BackupFileInfo> _getBackupFileInfo(File backupFile) async {
    final stat = await backupFile.stat();
    final content = await backupFile.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    
    return BackupFileInfo(
      filePath: backupFile.path,
      fileName: path.basename(backupFile.path),
      size: stat.size,
      createdAt: stat.modified,
      version: data['version'] as String? ?? 'unknown',
      appVersion: data['app_version'] as String? ?? 'unknown',
      dataTypes: _getDataTypes(data),
    );
  }

  /// Get data types included in backup
  List<String> _getDataTypes(Map<String, dynamic> data) {
    final types = <String>[];
    
    if (data.containsKey('bookmarks')) types.add('bookmarks');
    if (data.containsKey('history')) types.add('history');
    if (data.containsKey('preferences')) types.add('preferences');
    if (data.containsKey('folders')) types.add('folders');
    if (data.containsKey('tabs')) types.add('tabs');
    
    return types;
  }

  /// Validate backup format
  void _validateBackupFormat(Map<String, dynamic> data) {
    if (!data.containsKey('version')) {
      throw BackupServiceException('Invalid backup format: missing version');
    }
    
    if (!data.containsKey('created_at')) {
      throw BackupServiceException('Invalid backup format: missing creation date');
    }
  }

  /// Restore folders from backup
  Future<int> _restoreFolders(List<dynamic> foldersData, bool overwrite) async {
    int restoredCount = 0;
    
    for (final folderData in foldersData) {
      try {
        final folder = Folder.fromJson(folderData as Map<String, dynamic>);
        
        if (overwrite || await _folderRepository.getById(folder.id) == null) {
          await _folderRepository.create(folder);
          restoredCount++;
        }
      } catch (e) {
        // Continue with other folders if one fails
      }
    }
    
    return restoredCount;
  }

  /// Restore bookmarks from backup
  Future<int> _restoreBookmarks(List<dynamic> bookmarksData, bool overwrite) async {
    int restoredCount = 0;
    
    for (final bookmarkData in bookmarksData) {
      try {
        final bookmark = Bookmark.fromJson(bookmarkData as Map<String, dynamic>);
        
        if (overwrite || await _bookmarkRepository.getById(bookmark.id) == null) {
          await _bookmarkRepository.create(bookmark);
          restoredCount++;
        }
      } catch (e) {
        // Continue with other bookmarks if one fails
      }
    }
    
    return restoredCount;
  }

  /// Restore history from backup
  Future<int> _restoreHistory(List<dynamic> historyData, bool overwrite) async {
    int restoredCount = 0;
    
    for (final entryData in historyData) {
      try {
        final entry = HistoryEntry.fromJson(entryData as Map<String, dynamic>);
        
        if (overwrite || await _historyRepository.getById(entry.id) == null) {
          await _historyRepository.addVisit(entry.url, title: entry.title, faviconUrl: entry.faviconUrl);
          restoredCount++;
        }
      } catch (e) {
        // Continue with other entries if one fails
      }
    }
    
    return restoredCount;
  }

  /// Restore preferences from backup
  Future<int> _restorePreferences(List<dynamic> preferencesData, bool overwrite) async {
    int restoredCount = 0;
    
    for (final prefData in preferencesData) {
      try {
        final preference = UserPreference.fromJson(prefData as Map<String, dynamic>);
        
        if (overwrite || !await _preferenceRepository.exists(preference.key)) {
          await _preferenceRepository.set(
            preference.key,
            preference.getValue(),
            category: preference.category,
            isEncrypted: preference.isEncrypted,
          );
          restoredCount++;
        }
      } catch (e) {
        // Continue with other preferences if one fails
      }
    }
    
    return restoredCount;
  }

  /// Restore tabs from backup
  Future<int> _restoreTabs(List<dynamic> tabsData, bool overwrite) async {
    int restoredCount = 0;
    
    for (final tabData in tabsData) {
      try {
        final tab = Tab.fromJson(tabData as Map<String, dynamic>);
        
        if (overwrite || await _tabRepository.getById(tab.id) == null) {
          await _tabRepository.create(tab);
          restoredCount++;
        }
      } catch (e) {
        // Continue with other tabs if one fails
      }
    }
    
    return restoredCount;
  }
}

/// Information about a backup file
class BackupFileInfo {
  final String filePath;
  final String fileName;
  final int size;
  final DateTime createdAt;
  final String version;
  final String appVersion;
  final List<String> dataTypes;

  const BackupFileInfo({
    required this.filePath,
    required this.fileName,
    required this.size,
    required this.createdAt,
    required this.version,
    required this.appVersion,
    required this.dataTypes,
  });

  /// Get human-readable file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Result of a backup restore operation
class BackupRestoreResult {
  int bookmarksRestored = 0;
  int historyRestored = 0;
  int preferencesRestored = 0;
  int foldersRestored = 0;
  int tabsRestored = 0;

  /// Get total number of items restored
  int get totalRestored =>
      bookmarksRestored + historyRestored + preferencesRestored + foldersRestored + tabsRestored;

  @override
  String toString() {
    return 'BackupRestoreResult(bookmarks: $bookmarksRestored, history: $historyRestored, '
           'preferences: $preferencesRestored, folders: $foldersRestored, tabs: $tabsRestored)';
  }
}

/// Exception thrown by backup service operations
class BackupServiceException implements Exception {
  final String message;
  
  const BackupServiceException(this.message);
  
  @override
  String toString() => 'BackupServiceException: $message';
}
