import 'dart:async';
import 'dart:convert';
import '../database/hive_helper.dart';
import '../database/database_config.dart';

/// Cache manager for fast data access using Hive
class CacheManager {
  final HiveHelper _hiveHelper;
  final Map<String, Timer> _expirationTimers = {};
  
  static const String _cacheMetadataKey = 'cache_metadata';
  static const Duration _defaultExpiration = Duration(hours: 1);

  CacheManager({HiveHelper? hiveHelper})
      : _hiveHelper = hiveHelper ?? HiveHelper.instance;

  /// Initialize cache manager
  Future<void> initialize() async {
    await _hiveHelper.initialize();
    await _cleanupExpiredEntries();
  }

  /// Put value in cache with optional expiration
  Future<void> put(String key, dynamic value, {Duration? expiration}) async {
    try {
      final expirationDuration = expiration ?? _defaultExpiration;
      final expirationTime = DateTime.now().add(expirationDuration);
      
      // Store the value with expiration metadata
      await _hiveHelper.putWithExpiration(
        DatabaseConfig.cacheBoxName,
        key,
        value,
        expirationDuration,
      );
      
      // Set up expiration timer
      _setExpirationTimer(key, expirationDuration);
      
      // Update metadata
      await _updateCacheMetadata(key, expirationTime);
    } catch (e) {
      throw CacheManagerException('Failed to put value in cache: $e');
    }
  }

  /// Get value from cache
  Future<T?> get<T>(String key) async {
    try {
      return await _hiveHelper.getWithExpiration<T>(DatabaseConfig.cacheBoxName, key);
    } catch (e) {
      throw CacheManagerException('Failed to get value from cache: $e');
    }
  }

  /// Check if key exists in cache and is not expired
  Future<bool> containsKey(String key) async {
    try {
      final value = await get(key);
      return value != null;
    } catch (e) {
      return false;
    }
  }

  /// Remove value from cache
  Future<void> remove(String key) async {
    try {
      await _hiveHelper.deleteCacheData(key);
      _cancelExpirationTimer(key);
      await _removeCacheMetadata(key);
    } catch (e) {
      throw CacheManagerException('Failed to remove value from cache: $e');
    }
  }

  /// Clear all cache data
  Future<void> clear() async {
    try {
      await _hiveHelper.clearCacheData();
      _cancelAllTimers();
      await _clearCacheMetadata();
    } catch (e) {
      throw CacheManagerException('Failed to clear cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getSize() async {
    try {
      return await _hiveHelper.getBoxSize(DatabaseConfig.cacheBoxName);
    } catch (e) {
      throw CacheManagerException('Failed to get cache size: $e');
    }
  }

  /// Get number of cached items
  Future<int> getCount() async {
    try {
      return await _hiveHelper.length(DatabaseConfig.cacheBoxName);
    } catch (e) {
      throw CacheManagerException('Failed to get cache count: $e');
    }
  }

  /// Get all cache keys
  Future<List<String>> getKeys() async {
    try {
      final keys = await _hiveHelper.getKeys(DatabaseConfig.cacheBoxName);
      return keys.cast<String>().toList();
    } catch (e) {
      throw CacheManagerException('Failed to get cache keys: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final count = await getCount();
      final size = await getSize();
      final metadata = await _getCacheMetadata();
      
      final now = DateTime.now();
      final expiredCount = metadata.values
          .where((expiration) => expiration.isBefore(now))
          .length;
      
      return {
        'total_items': count,
        'size_bytes': size,
        'expired_items': expiredCount,
        'active_items': count - expiredCount,
        'hit_rate': await _calculateHitRate(),
      };
    } catch (e) {
      throw CacheManagerException('Failed to get cache statistics: $e');
    }
  }

  /// Cleanup expired entries
  Future<int> cleanupExpired() async {
    try {
      return await _cleanupExpiredEntries();
    } catch (e) {
      throw CacheManagerException('Failed to cleanup expired entries: $e');
    }
  }

  /// Compact cache storage
  Future<void> compact() async {
    try {
      await _hiveHelper.compact(DatabaseConfig.cacheBoxName);
    } catch (e) {
      throw CacheManagerException('Failed to compact cache: $e');
    }
  }

  /// Cache with automatic refresh
  Future<T> cacheWithRefresh<T>(
    String key,
    Future<T> Function() refreshFunction, {
    Duration? expiration,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedValue = await get<T>(key);
        if (cachedValue != null) {
          return cachedValue;
        }
      }
      
      // Refresh data
      final freshValue = await refreshFunction();
      await put(key, freshValue, expiration: expiration);
      
      return freshValue;
    } catch (e) {
      throw CacheManagerException('Failed to cache with refresh: $e');
    }
  }

  /// Batch put multiple values
  Future<void> putBatch(Map<String, dynamic> entries, {Duration? expiration}) async {
    try {
      for (final entry in entries.entries) {
        await put(entry.key, entry.value, expiration: expiration);
      }
    } catch (e) {
      throw CacheManagerException('Failed to put batch values: $e');
    }
  }

  /// Batch get multiple values
  Future<Map<String, dynamic>> getBatch(List<String> keys) async {
    try {
      final result = <String, dynamic>{};
      
      for (final key in keys) {
        final value = await get(key);
        if (value != null) {
          result[key] = value;
        }
      }
      
      return result;
    } catch (e) {
      throw CacheManagerException('Failed to get batch values: $e');
    }
  }

  /// Batch remove multiple values
  Future<void> removeBatch(List<String> keys) async {
    try {
      for (final key in keys) {
        await remove(key);
      }
    } catch (e) {
      throw CacheManagerException('Failed to remove batch values: $e');
    }
  }

  /// Set expiration timer for a key
  void _setExpirationTimer(String key, Duration expiration) {
    _cancelExpirationTimer(key);
    
    _expirationTimers[key] = Timer(expiration, () async {
      await remove(key);
    });
  }

  /// Cancel expiration timer for a key
  void _cancelExpirationTimer(String key) {
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);
  }

  /// Cancel all expiration timers
  void _cancelAllTimers() {
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();
  }

  /// Update cache metadata
  Future<void> _updateCacheMetadata(String key, DateTime expiration) async {
    try {
      final metadata = await _getCacheMetadata();
      metadata[key] = expiration;
      
      await _hiveHelper.putCacheData(
        _cacheMetadataKey,
        jsonEncode(metadata.map((k, v) => MapEntry(k, v.toIso8601String()))),
      );
    } catch (e) {
      // Ignore metadata errors
    }
  }

  /// Remove cache metadata for a key
  Future<void> _removeCacheMetadata(String key) async {
    try {
      final metadata = await _getCacheMetadata();
      metadata.remove(key);
      
      await _hiveHelper.putCacheData(
        _cacheMetadataKey,
        jsonEncode(metadata.map((k, v) => MapEntry(k, v.toIso8601String()))),
      );
    } catch (e) {
      // Ignore metadata errors
    }
  }

  /// Clear all cache metadata
  Future<void> _clearCacheMetadata() async {
    try {
      await _hiveHelper.deleteCacheData(_cacheMetadataKey);
    } catch (e) {
      // Ignore metadata errors
    }
  }

  /// Get cache metadata
  Future<Map<String, DateTime>> _getCacheMetadata() async {
    try {
      final metadataJson = await _hiveHelper.getCacheData<String>(_cacheMetadataKey);
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        return metadata.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Cleanup expired entries
  Future<int> _cleanupExpiredEntries() async {
    try {
      final metadata = await _getCacheMetadata();
      final now = DateTime.now();
      int cleanedCount = 0;
      
      final expiredKeys = metadata.entries
          .where((entry) => entry.value.isBefore(now))
          .map((entry) => entry.key)
          .toList();
      
      for (final key in expiredKeys) {
        await remove(key);
        cleanedCount++;
      }
      
      return cleanedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate cache hit rate (simplified)
  Future<double> _calculateHitRate() async {
    try {
      // This is a simplified implementation
      // In a real scenario, you'd track hits and misses
      final metadata = await _getCacheMetadata();
      final now = DateTime.now();
      
      final activeEntries = metadata.values
          .where((expiration) => expiration.isAfter(now))
          .length;
      
      final totalEntries = metadata.length;
      
      return totalEntries > 0 ? activeEntries / totalEntries : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Dispose cache manager
  Future<void> dispose() async {
    _cancelAllTimers();
  }
}

/// Exception thrown by cache manager operations
class CacheManagerException implements Exception {
  final String message;
  
  const CacheManagerException(this.message);
  
  @override
  String toString() => 'CacheManagerException: $message';
}
