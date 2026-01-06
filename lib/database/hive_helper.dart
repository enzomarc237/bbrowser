import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'database_config.dart';

/// Hive database helper for key-value storage with box management
class HiveHelper {
  static HiveHelper? _instance;
  static bool _isInitialized = false;
  static final Map<String, Box> _openBoxes = {};

  HiveHelper._internal();

  /// Singleton instance
  static HiveHelper get instance {
    _instance ??= HiveHelper._internal();
    return _instance!;
  }

  /// Initialize Hive with proper configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive for Flutter
      await Hive.initFlutter();

      // Set custom path for Hive boxes
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final hivePath = '${documentsDirectory.path}/hive_boxes';
      
      // Ensure directory exists
      final directory = Directory(hivePath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      Hive.init(hivePath);

      // Register adapters if needed (for custom objects)
      _registerAdapters();

      _isInitialized = true;
    } catch (e) {
      throw HiveException('Failed to initialize Hive: $e');
    }
  }

  /// Register custom type adapters
  void _registerAdapters() {
    // Register adapters for custom objects here
    // Example: Hive.registerAdapter(TabAdapter());
  }

  /// Open a box with the given name
  Future<Box<T>> openBox<T>(String boxName) async {
    await _ensureInitialized();

    try {
      if (_openBoxes.containsKey(boxName)) {
        return _openBoxes[boxName] as Box<T>;
      }

      final box = await Hive.openBox<T>(boxName);
      _openBoxes[boxName] = box;
      return box;
    } catch (e) {
      throw HiveException('Failed to open box $boxName: $e');
    }
  }

  /// Open a lazy box for large data
  Future<LazyBox<T>> openLazyBox<T>(String boxName) async {
    await _ensureInitialized();

    try {
      return await Hive.openLazyBox<T>(boxName);
    } catch (e) {
      throw HiveException('Failed to open lazy box $boxName: $e');
    }
  }

  /// Get session data box
  Future<Box<dynamic>> get sessionBox async {
    return await openBox(DatabaseConfig.sessionBoxName);
  }

  /// Get cache data box
  Future<Box<dynamic>> get cacheBox async {
    return await openBox(DatabaseConfig.cacheBoxName);
  }

  /// Get preferences data box
  Future<Box<dynamic>> get preferencesBox async {
    return await openBox(DatabaseConfig.preferencesBoxName);
  }

  /// Get temporary data box
  Future<Box<dynamic>> get tempDataBox async {
    return await openBox(DatabaseConfig.tempDataBoxName);
  }

  /// Store value in a specific box
  Future<void> put(String boxName, String key, dynamic value) async {
    try {
      final box = await openBox(boxName);
      await box.put(key, value);
    } catch (e) {
      throw HiveException('Failed to put value in box $boxName: $e');
    }
  }

  /// Get value from a specific box
  Future<T?> get<T>(String boxName, String key, {T? defaultValue}) async {
    try {
      final box = await openBox(boxName);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      throw HiveException('Failed to get value from box $boxName: $e');
    }
  }

  /// Delete value from a specific box
  Future<void> delete(String boxName, String key) async {
    try {
      final box = await openBox(boxName);
      await box.delete(key);
    } catch (e) {
      throw HiveException('Failed to delete value from box $boxName: $e');
    }
  }

  /// Check if key exists in a specific box
  Future<bool> containsKey(String boxName, String key) async {
    try {
      final box = await openBox(boxName);
      return box.containsKey(key);
    } catch (e) {
      throw HiveException('Failed to check key in box $boxName: $e');
    }
  }

  /// Get all keys from a specific box
  Future<Iterable<dynamic>> getKeys(String boxName) async {
    try {
      final box = await openBox(boxName);
      return box.keys;
    } catch (e) {
      throw HiveException('Failed to get keys from box $boxName: $e');
    }
  }

  /// Get all values from a specific box
  Future<Iterable<dynamic>> getValues(String boxName) async {
    try {
      final box = await openBox(boxName);
      return box.values;
    } catch (e) {
      throw HiveException('Failed to get values from box $boxName: $e');
    }
  }

  /// Clear all data from a specific box
  Future<void> clear(String boxName) async {
    try {
      final box = await openBox(boxName);
      await box.clear();
    } catch (e) {
      throw HiveException('Failed to clear box $boxName: $e');
    }
  }

  /// Get the number of entries in a specific box
  Future<int> length(String boxName) async {
    try {
      final box = await openBox(boxName);
      return box.length;
    } catch (e) {
      throw HiveException('Failed to get length of box $boxName: $e');
    }
  }

  /// Check if a specific box is empty
  Future<bool> isEmpty(String boxName) async {
    try {
      final box = await openBox(boxName);
      return box.isEmpty;
    } catch (e) {
      throw HiveException('Failed to check if box $boxName is empty: $e');
    }
  }

  /// Batch operations for better performance
  Future<void> putAll(String boxName, Map<String, dynamic> entries) async {
    try {
      final box = await openBox(boxName);
      await box.putAll(entries);
    } catch (e) {
      throw HiveException('Failed to put all values in box $boxName: $e');
    }
  }

  /// Delete multiple keys from a specific box
  Future<void> deleteAll(String boxName, Iterable<String> keys) async {
    try {
      final box = await openBox(boxName);
      await box.deleteAll(keys);
    } catch (e) {
      throw HiveException('Failed to delete all values from box $boxName: $e');
    }
  }

  /// Get multiple values from a specific box
  Future<Map<String, dynamic>> getAll(String boxName, Iterable<String> keys) async {
    try {
      final box = await openBox(boxName);
      final result = <String, dynamic>{};
      
      for (final key in keys) {
        if (box.containsKey(key)) {
          result[key] = box.get(key);
        }
      }
      
      return result;
    } catch (e) {
      throw HiveException('Failed to get all values from box $boxName: $e');
    }
  }

  /// Watch for changes in a specific box
  Stream<BoxEvent> watch(String boxName, {String? key}) async* {
    try {
      final box = await openBox(boxName);
      yield* box.watch(key: key);
    } catch (e) {
      throw HiveException('Failed to watch box $boxName: $e');
    }
  }

  /// Compact a box to reduce file size
  Future<void> compact(String boxName) async {
    try {
      final box = await openBox(boxName);
      await box.compact();
    } catch (e) {
      throw HiveException('Failed to compact box $boxName: $e');
    }
  }

  /// Close a specific box
  Future<void> closeBox(String boxName) async {
    try {
      if (_openBoxes.containsKey(boxName)) {
        await _openBoxes[boxName]!.close();
        _openBoxes.remove(boxName);
      }
    } catch (e) {
      throw HiveException('Failed to close box $boxName: $e');
    }
  }

  /// Close all open boxes
  Future<void> closeAllBoxes() async {
    try {
      for (final box in _openBoxes.values) {
        if (box.isOpen) {
          await box.close();
        }
      }
      _openBoxes.clear();
    } catch (e) {
      throw HiveException('Failed to close all boxes: $e');
    }
  }

  /// Delete a box completely
  Future<void> deleteBox(String boxName) async {
    try {
      // Close the box first if it's open
      if (_openBoxes.containsKey(boxName)) {
        await closeBox(boxName);
      }
      
      // Delete the box
      await Hive.deleteBoxFromDisk(boxName);
    } catch (e) {
      throw HiveException('Failed to delete box $boxName: $e');
    }
  }

  /// Get box file size in bytes
  Future<int> getBoxSize(String boxName) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final boxPath = '${documentsDirectory.path}/hive_boxes/$boxName.hive';
      final file = File(boxPath);
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      throw HiveException('Failed to get box size for $boxName: $e');
    }
  }

  /// Get total size of all Hive boxes
  Future<int> getTotalSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final hiveDirectory = Directory('${documentsDirectory.path}/hive_boxes');
      
      if (!await hiveDirectory.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in hiveDirectory.list()) {
        if (entity is File && entity.path.endsWith('.hive')) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      throw HiveException('Failed to get total Hive size: $e');
    }
  }

  /// Session data operations
  Future<void> putSessionData(String key, dynamic value) async {
    await put(DatabaseConfig.sessionBoxName, key, value);
  }

  Future<T?> getSessionData<T>(String key, {T? defaultValue}) async {
    return await get<T>(DatabaseConfig.sessionBoxName, key, defaultValue: defaultValue);
  }

  Future<void> deleteSessionData(String key) async {
    await delete(DatabaseConfig.sessionBoxName, key);
  }

  Future<void> clearSessionData() async {
    await clear(DatabaseConfig.sessionBoxName);
  }

  /// Cache data operations
  Future<void> putCacheData(String key, dynamic value) async {
    await put(DatabaseConfig.cacheBoxName, key, value);
  }

  Future<T?> getCacheData<T>(String key, {T? defaultValue}) async {
    return await get<T>(DatabaseConfig.cacheBoxName, key, defaultValue: defaultValue);
  }

  Future<void> deleteCacheData(String key) async {
    await delete(DatabaseConfig.cacheBoxName, key);
  }

  Future<void> clearCacheData() async {
    await clear(DatabaseConfig.cacheBoxName);
  }

  /// Preferences data operations
  Future<void> putPreference(String key, dynamic value) async {
    await put(DatabaseConfig.preferencesBoxName, key, value);
  }

  Future<T?> getPreference<T>(String key, {T? defaultValue}) async {
    return await get<T>(DatabaseConfig.preferencesBoxName, key, defaultValue: defaultValue);
  }

  Future<void> deletePreference(String key) async {
    await delete(DatabaseConfig.preferencesBoxName, key);
  }

  Future<void> clearPreferences() async {
    await clear(DatabaseConfig.preferencesBoxName);
  }

  /// Temporary data operations
  Future<void> putTempData(String key, dynamic value) async {
    await put(DatabaseConfig.tempDataBoxName, key, value);
  }

  Future<T?> getTempData<T>(String key, {T? defaultValue}) async {
    return await get<T>(DatabaseConfig.tempDataBoxName, key, defaultValue: defaultValue);
  }

  Future<void> deleteTempData(String key) async {
    await delete(DatabaseConfig.tempDataBoxName, key);
  }

  Future<void> clearTempData() async {
    await clear(DatabaseConfig.tempDataBoxName);
  }

  /// Cache with expiration
  Future<void> putWithExpiration(
    String boxName,
    String key,
    dynamic value,
    Duration expiration,
  ) async {
    final expirationTime = DateTime.now().add(expiration).millisecondsSinceEpoch;
    final wrappedValue = {
      'value': value,
      'expiration': expirationTime,
    };
    await put(boxName, key, wrappedValue);
  }

  /// Get cached value with expiration check
  Future<T?> getWithExpiration<T>(String boxName, String key) async {
    final wrappedValue = await get<Map<dynamic, dynamic>>(boxName, key);
    
    if (wrappedValue == null) return null;
    
    final expirationTime = wrappedValue['expiration'] as int?;
    if (expirationTime == null) return wrappedValue['value'] as T?;
    
    if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
      // Value has expired, delete it
      await delete(boxName, key);
      return null;
    }
    
    return wrappedValue['value'] as T?;
  }

  /// Clean up expired cache entries
  Future<void> cleanupExpiredEntries(String boxName) async {
    try {
      final box = await openBox(boxName);
      final keysToDelete = <String>[];
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is Map && value.containsKey('expiration')) {
          final expirationTime = value['expiration'] as int?;
          if (expirationTime != null && currentTime > expirationTime) {
            keysToDelete.add(key.toString());
          }
        }
      }
      
      if (keysToDelete.isNotEmpty) {
        await deleteAll(boxName, keysToDelete);
      }
    } catch (e) {
      throw HiveException('Failed to cleanup expired entries in box $boxName: $e');
    }
  }

  /// Ensure Hive is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Reset all Hive data (for testing purposes)
  Future<void> reset() async {
    try {
      await closeAllBoxes();
      
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final hiveDirectory = Directory('${documentsDirectory.path}/hive_boxes');
      
      if (await hiveDirectory.exists()) {
        await hiveDirectory.delete(recursive: true);
      }
      
      _isInitialized = false;
    } catch (e) {
      throw HiveException('Failed to reset Hive: $e');
    }
  }
}

/// Custom exception for Hive operations
class HiveException implements Exception {
  final String message;
  
  const HiveException(this.message);
  
  @override
  String toString() => 'HiveException: $message';
}
