import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_config.dart';
import '../entities/user_preference.dart';

/// Repository for managing user preferences data operations
class PreferenceRepository {
  final DatabaseHelper _databaseHelper;

  PreferenceRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Create or update a preference
  Future<UserPreference> set(String key, dynamic value, {String category = 'general', bool isEncrypted = false}) async {
    try {
      final existing = await getByKey(key);
      
      if (existing != null) {
        // Update existing preference
        final updated = existing.updateValue(value).copyWith(
          category: category,
          isEncrypted: isEncrypted,
        );
        
        await _databaseHelper.update(
          DatabaseConfig.preferencesTable,
          updated.toMap(),
          where: 'key = ?',
          whereArgs: [key],
        );
        
        return updated;
      } else {
        // Create new preference
        final preference = UserPreference.create(
          key: key,
          value: value,
          category: category,
          isEncrypted: isEncrypted,
        );
        
        final id = await _databaseHelper.insert(
          DatabaseConfig.preferencesTable,
          preference.toMap(),
        );
        
        return preference.copyWith(id: id);
      }
    } catch (e) {
      throw PreferenceRepositoryException('Failed to set preference: $e');
    }
  }

  /// Get preference by key
  Future<UserPreference?> getByKey(String key) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.preferencesTable,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return UserPreference.fromMap(results.first);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get preference by key: $e');
    }
  }

  /// Get preference by ID
  Future<UserPreference?> getById(int id) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.preferencesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return UserPreference.fromMap(results.first);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get preference by ID: $e');
    }
  }

  /// Get all preferences
  Future<List<UserPreference>> getAll({String? category}) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.preferencesTable,
        where: category != null ? 'category = ?' : null,
        whereArgs: category != null ? [category] : null,
        orderBy: 'category ASC, key ASC',
      );

      return results.map((map) => UserPreference.fromMap(map)).toList();
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get preferences: $e');
    }
  }

  /// Get preferences by category
  Future<List<UserPreference>> getByCategory(String category) async {
    return getAll(category: category);
  }

  /// Get all categories
  Future<List<String>> getCategories() async {
    try {
      final results = await _databaseHelper.rawQuery(
        'SELECT DISTINCT category FROM ${DatabaseConfig.preferencesTable} ORDER BY category',
      );

      return results.map((map) => map['category'] as String).toList();
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get categories: $e');
    }
  }

  /// Get typed value by key
  Future<T?> getValue<T>(String key, {T? defaultValue}) async {
    try {
      final preference = await getByKey(key);
      return preference?.getValue<T>() ?? defaultValue;
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get value: $e');
    }
  }

  /// Get string value
  Future<String> getString(String key, [String defaultValue = '']) async {
    final preference = await getByKey(key);
    return preference?.getStringValue(defaultValue) ?? defaultValue;
  }

  /// Get integer value
  Future<int> getInt(String key, [int defaultValue = 0]) async {
    final preference = await getByKey(key);
    return preference?.getIntValue(defaultValue) ?? defaultValue;
  }

  /// Get double value
  Future<double> getDouble(String key, [double defaultValue = 0.0]) async {
    final preference = await getByKey(key);
    return preference?.getDoubleValue(defaultValue) ?? defaultValue;
  }

  /// Get boolean value
  Future<bool> getBool(String key, [bool defaultValue = false]) async {
    final preference = await getByKey(key);
    return preference?.getBoolValue(defaultValue) ?? defaultValue;
  }

  /// Get list value
  Future<List<String>> getList(String key, [List<String> defaultValue = const []]) async {
    final preference = await getByKey(key);
    return preference?.getListValue(defaultValue) ?? defaultValue;
  }

  /// Get map value
  Future<Map<String, String>> getMap(String key, [Map<String, String> defaultValue = const {}]) async {
    final preference = await getByKey(key);
    return preference?.getMapValue(defaultValue) ?? defaultValue;
  }

  /// Check if preference exists
  Future<bool> exists(String key) async {
    try {
      final preference = await getByKey(key);
      return preference != null;
    } catch (e) {
      throw PreferenceRepositoryException('Failed to check if preference exists: $e');
    }
  }

  /// Update preference
  Future<UserPreference> update(UserPreference preference) async {
    try {
      final updated = preference.copyWith(updatedAt: DateTime.now());
      
      await _databaseHelper.update(
        DatabaseConfig.preferencesTable,
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [preference.id],
      );

      return updated;
    } catch (e) {
      throw PreferenceRepositoryException('Failed to update preference: $e');
    }
  }

  /// Delete preference by key
  Future<void> delete(String key) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.preferencesTable,
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e) {
      throw PreferenceRepositoryException('Failed to delete preference: $e');
    }
  }

  /// Delete preference by ID
  Future<void> deleteById(int id) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.preferencesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw PreferenceRepositoryException('Failed to delete preference by ID: $e');
    }
  }

  /// Delete preferences by category
  Future<void> deleteByCategory(String category) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.preferencesTable,
        where: 'category = ?',
        whereArgs: [category],
      );
    } catch (e) {
      throw PreferenceRepositoryException('Failed to delete preferences by category: $e');
    }
  }

  /// Clear all preferences
  Future<void> clear() async {
    try {
      await _databaseHelper.delete(DatabaseConfig.preferencesTable);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to clear preferences: $e');
    }
  }

  /// Search preferences
  Future<List<UserPreference>> search(String query) async {
    try {
      final searchQuery = '%${query.toLowerCase()}%';
      final results = await _databaseHelper.query(
        DatabaseConfig.preferencesTable,
        where: '''
          LOWER(key) LIKE ? OR 
          LOWER(value) LIKE ? OR 
          LOWER(category) LIKE ?
        ''',
        whereArgs: [searchQuery, searchQuery, searchQuery],
        orderBy: 'category ASC, key ASC',
      );

      return results.map((map) => UserPreference.fromMap(map)).toList();
    } catch (e) {
      throw PreferenceRepositoryException('Failed to search preferences: $e');
    }
  }

  /// Get preference count
  Future<int> getCount({String? category}) async {
    try {
      final results = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConfig.preferencesTable}' +
        (category != null ? ' WHERE category = ?' : ''),
        category != null ? [category] : null,
      );

      return results.first['count'] as int;
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get preference count: $e');
    }
  }

  /// Bulk set preferences
  Future<void> setBulk(Map<String, dynamic> preferences, {String category = 'general'}) async {
    try {
      await _databaseHelper.transaction((txn) async {
        for (final entry in preferences.entries) {
          final existing = await getByKey(entry.key);
          
          if (existing != null) {
            final updated = existing.updateValue(entry.value);
            await txn.update(
              DatabaseConfig.preferencesTable,
              updated.toMap(),
              where: 'key = ?',
              whereArgs: [entry.key],
            );
          } else {
            final preference = UserPreference.create(
              key: entry.key,
              value: entry.value,
              category: category,
            );
            
            await txn.insert(
              DatabaseConfig.preferencesTable,
              preference.toMap(),
            );
          }
        }
      });
    } catch (e) {
      throw PreferenceRepositoryException('Failed to set preferences in bulk: $e');
    }
  }

  /// Get preferences as map
  Future<Map<String, dynamic>> getAsMap({String? category}) async {
    try {
      final preferences = await getAll(category: category);
      final map = <String, dynamic>{};
      
      for (final preference in preferences) {
        map[preference.key] = preference.getValue();
      }
      
      return map;
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get preferences as map: $e');
    }
  }

  /// Export preferences to JSON
  Future<String> exportToJson({String? category}) async {
    try {
      final preferences = await getAll(category: category);
      final jsonData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'category': category,
        'preferences': preferences.map((pref) => pref.toJson()).toList(),
      };
      
      return jsonEncode(jsonData);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to export preferences: $e');
    }
  }

  /// Import preferences from JSON
  Future<List<UserPreference>> importFromJson(String jsonString, {bool overwrite = false}) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final preferencesData = jsonData['preferences'] as List<dynamic>;
      
      final importedPreferences = <UserPreference>[];
      
      await _databaseHelper.transaction((txn) async {
        for (final prefData in preferencesData) {
          final preference = UserPreference.fromJson(prefData as Map<String, dynamic>);
          
          if (overwrite || !await exists(preference.key)) {
            final id = await txn.insert(
              DatabaseConfig.preferencesTable,
              preference.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            
            importedPreferences.add(preference.copyWith(id: id));
          }
        }
      });
      
      return importedPreferences;
    } catch (e) {
      throw PreferenceRepositoryException('Failed to import preferences: $e');
    }
  }

  /// Backup preferences to file
  Future<File> backupToFile(String filePath, {String? category}) async {
    try {
      final jsonData = await exportToJson(category: category);
      final file = File(filePath);
      await file.writeAsString(jsonData);
      return file;
    } catch (e) {
      throw PreferenceRepositoryException('Failed to backup preferences: $e');
    }
  }

  /// Restore preferences from file
  Future<List<UserPreference>> restoreFromFile(String filePath, {bool overwrite = false}) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importFromJson(jsonString, overwrite: overwrite);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to restore preferences: $e');
    }
  }

  /// Reset preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      await clear();
      
      // Set default preferences
      final defaults = {
        PreferenceKeys.themeMode: 'system',
        PreferenceKeys.defaultSearchEngine: 'google',
        PreferenceKeys.homepageUrl: 'about:blank',
        PreferenceKeys.enableJavaScript: true,
        PreferenceKeys.blockPopups: true,
        PreferenceKeys.historyRetentionDays: 90,
        PreferenceKeys.autoSaveSession: true,
        PreferenceKeys.restoreSessionOnStartup: true,
        PreferenceKeys.showBookmarksBar: true,
        PreferenceKeys.enableHttpsOnly: false,
        PreferenceKeys.enableCookies: true,
      };
      
      await setBulk(defaults);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to reset preferences to defaults: $e');
    }
  }

  /// Get recently updated preferences
  Future<List<UserPreference>> getRecentlyUpdated({int limit = 10}) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.preferencesTable,
        orderBy: 'updated_at DESC',
        limit: limit,
      );

      return results.map((map) => UserPreference.fromMap(map)).toList();
    } catch (e) {
      throw PreferenceRepositoryException('Failed to get recently updated preferences: $e');
    }
  }

  /// Batch delete preferences
  Future<void> deleteBatch(List<String> keys) async {
    try {
      final operations = keys.map((key) => 
        BatchOperation.delete(
          DatabaseConfig.preferencesTable,
          where: 'key = ?',
          whereArgs: [key],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to delete preferences in batch: $e');
    }
  }

  /// Batch update preferences
  Future<void> updateBatch(List<UserPreference> preferences) async {
    try {
      final operations = preferences.map((preference) => 
        BatchOperation.update(
          DatabaseConfig.preferencesTable,
          preference.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [preference.id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw PreferenceRepositoryException('Failed to update preferences in batch: $e');
    }
  }
}

/// Exception thrown by preference repository operations
class PreferenceRepositoryException implements Exception {
  final String message;
  
  const PreferenceRepositoryException(this.message);
  
  @override
  String toString() => 'PreferenceRepositoryException: $message';
}
