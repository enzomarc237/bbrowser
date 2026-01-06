import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_config.dart';
import '../entities/history_entry.dart';

/// Repository for managing browsing history data operations
class HistoryRepository {
  final DatabaseHelper _databaseHelper;

  HistoryRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Add a visit to history
  Future<HistoryEntry> addVisit(String url, {String? title, String? faviconUrl, bool wasTyped = false}) async {
    try {
      // Check if URL already exists in history
      final existing = await getByUrl(url);
      
      if (existing != null) {
        // Update existing entry
        final updated = existing.recordVisit(wasTyped: wasTyped);
        final updatedWithMetadata = updated.updateMetadata(
          title: title ?? existing.title,
          faviconUrl: faviconUrl ?? existing.faviconUrl,
        );
        
        await _databaseHelper.update(
          DatabaseConfig.historyTable,
          updatedWithMetadata.toMap(),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        
        return updatedWithMetadata;
      } else {
        // Create new entry
        final newEntry = HistoryEntry.create(
          url: url,
          title: title,
          faviconUrl: faviconUrl,
          wasTyped: wasTyped,
        );
        
        final id = await _databaseHelper.insert(
          DatabaseConfig.historyTable,
          newEntry.toMap(),
        );
        
        return newEntry.copyWith(id: id);
      }
    } catch (e) {
      throw HistoryRepositoryException('Failed to add visit: $e');
    }
  }

  /// Get history entry by ID
  Future<HistoryEntry?> getById(int id) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.historyTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return HistoryEntry.fromMap(results.first);
    } catch (e) {
      throw HistoryRepositoryException('Failed to get history entry by ID: $e');
    }
  }

  /// Get history entry by URL
  Future<HistoryEntry?> getByUrl(String url) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.historyTable,
        where: 'url = ? AND is_hidden = 0',
        whereArgs: [url],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return HistoryEntry.fromMap(results.first);
    } catch (e) {
      throw HistoryRepositoryException('Failed to get history entry by URL: $e');
    }
  }

  /// Get all history entries
  Future<List<HistoryEntry>> getAll({
    bool includeHidden = false,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String where = includeHidden ? '' : 'is_hidden = 0';
      List<Object?> whereArgs = [];

      if (!includeHidden) {
        whereArgs.add(0);
      }

      if (startDate != null) {
        final condition = 'last_visited >= ?';
        if (where.isNotEmpty) {
          where = '$where AND $condition';
        } else {
          where = condition;
        }
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        final condition = 'last_visited <= ?';
        if (where.isNotEmpty) {
          where = '$where AND $condition';
        } else {
          where = condition;
        }
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      final results = await _databaseHelper.query(
        DatabaseConfig.historyTable,
        where: where.isNotEmpty ? where : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'last_visited DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => HistoryEntry.fromMap(map)).toList();
    } catch (e) {
      throw HistoryRepositoryException('Failed to get history entries: $e');
    }
  }

  /// Get recent history entries
  Future<List<HistoryEntry>> getRecent({int limit = 50}) async {
    return getAll(limit: limit);
  }

  /// Get history for today
  Future<List<HistoryEntry>> getToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getAll(startDate: startOfDay, endDate: endOfDay);
  }

  /// Get history for a specific date range
  Future<List<HistoryEntry>> getByDateRange(DateTime startDate, DateTime endDate) async {
    return getAll(startDate: startDate, endDate: endDate);
  }

  /// Get most visited sites
  Future<List<HistoryEntry>> getMostVisited({int limit = 20}) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.historyTable,
        where: 'is_hidden = 0',
        whereArgs: [0],
        orderBy: 'visit_count DESC, last_visited DESC',
        limit: limit,
      );

      return results.map((map) => HistoryEntry.fromMap(map)).toList();
    } catch (e) {
      throw HistoryRepositoryException('Failed to get most visited sites: $e');
    }
  }

  /// Get frequently visited sites (high visit frequency)
  Future<List<HistoryEntry>> getFrequentlyVisited({int limit = 20}) async {
    try {
      final results = await _databaseHelper.rawQuery('''
        SELECT *, 
               CAST(visit_count AS REAL) / 
               MAX(1, (strftime('%s', 'now') * 1000 - first_visited) / (24 * 60 * 60 * 1000)) as frequency
        FROM ${DatabaseConfig.historyTable}
        WHERE is_hidden = 0 AND visit_count > 1
        ORDER BY frequency DESC, visit_count DESC
        LIMIT ?
      ''', [limit]);

      return results.map((map) => HistoryEntry.fromMap(map)).toList();
    } catch (e) {
      throw HistoryRepositoryException('Failed to get frequently visited sites: $e');
    }
  }

  /// Search history entries
  Future<List<HistoryEntry>> search(String query, {int? limit}) async {
    try {
      final searchQuery = '%${query.toLowerCase()}%';
      final results = await _databaseHelper.query(
        DatabaseConfig.historyTable,
        where: '''
          is_hidden = 0 AND (
            LOWER(url) LIKE ? OR 
            LOWER(title) LIKE ?
          )
        ''',
        whereArgs: [0, searchQuery, searchQuery],
        orderBy: 'visit_count DESC, last_visited DESC',
        limit: limit,
      );

      return results.map((map) => HistoryEntry.fromMap(map)).toList();
    } catch (e) {
      throw HistoryRepositoryException('Failed to search history: $e');
    }
  }

  /// Search history by domain
  Future<List<HistoryEntry>> searchByDomain(String domain) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.historyTable,
        where: 'is_hidden = 0 AND url LIKE ?',
        whereArgs: [0, '%$domain%'],
        orderBy: 'last_visited DESC',
      );

      return results.map((map) => HistoryEntry.fromMap(map)).toList();
    } catch (e) {
      throw HistoryRepositoryException('Failed to search history by domain: $e');
    }
  }

  /// Get URL suggestions for autocomplete
  Future<List<String>> getUrlSuggestions(String query, {int limit = 10}) async {
    try {
      final searchQuery = '%${query.toLowerCase()}%';
      final results = await _databaseHelper.query(
        DatabaseConfig.historyTable,
        columns: ['url'],
        where: 'is_hidden = 0 AND LOWER(url) LIKE ?',
        whereArgs: [0, searchQuery],
        orderBy: 'visit_count DESC, last_visited DESC',
        limit: limit,
      );

      return results.map((map) => map['url'] as String).toList();
    } catch (e) {
      throw HistoryRepositoryException('Failed to get URL suggestions: $e');
    }
  }

  /// Update history entry
  Future<HistoryEntry> update(HistoryEntry entry) async {
    try {
      await _databaseHelper.update(
        DatabaseConfig.historyTable,
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );

      return entry;
    } catch (e) {
      throw HistoryRepositoryException('Failed to update history entry: $e');
    }
  }

  /// Hide history entry
  Future<void> hide(int id) async {
    try {
      await _databaseHelper.update(
        DatabaseConfig.historyTable,
        {'is_hidden': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw HistoryRepositoryException('Failed to hide history entry: $e');
    }
  }

  /// Show history entry
  Future<void> show(int id) async {
    try {
      await _databaseHelper.update(
        DatabaseConfig.historyTable,
        {'is_hidden': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw HistoryRepositoryException('Failed to show history entry: $e');
    }
  }

  /// Delete history entry
  Future<void> delete(int id) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.historyTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw HistoryRepositoryException('Failed to delete history entry: $e');
    }
  }

  /// Delete history entries by URL
  Future<void> deleteByUrl(String url) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.historyTable,
        where: 'url = ?',
        whereArgs: [url],
      );
    } catch (e) {
      throw HistoryRepositoryException('Failed to delete history by URL: $e');
    }
  }

  /// Delete history entries by domain
  Future<void> deleteByDomain(String domain) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.historyTable,
        where: 'url LIKE ?',
        whereArgs: ['%$domain%'],
      );
    } catch (e) {
      throw HistoryRepositoryException('Failed to delete history by domain: $e');
    }
  }

  /// Delete history entries in date range
  Future<void> deleteByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.historyTable,
        where: 'last_visited >= ? AND last_visited <= ?',
        whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      );
    } catch (e) {
      throw HistoryRepositoryException('Failed to delete history by date range: $e');
    }
  }

  /// Clear all history
  Future<void> clear() async {
    try {
      await _databaseHelper.delete(DatabaseConfig.historyTable);
    } catch (e) {
      throw HistoryRepositoryException('Failed to clear history: $e');
    }
  }

  /// Clean up old history entries
  Future<int> cleanupOldEntries({int retentionDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      
      final deletedCount = await _databaseHelper.delete(
        DatabaseConfig.historyTable,
        where: 'last_visited < ?',
        whereArgs: [cutoffDate.millisecondsSinceEpoch],
      );

      return deletedCount;
    } catch (e) {
      throw HistoryRepositoryException('Failed to cleanup old history: $e');
    }
  }

  /// Get history count
  Future<int> getCount({bool includeHidden = false}) async {
    try {
      final results = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConfig.historyTable}' +
        (includeHidden ? '' : ' WHERE is_hidden = 0'),
        includeHidden ? null : [0],
      );

      return results.first['count'] as int;
    } catch (e) {
      throw HistoryRepositoryException('Failed to get history count: $e');
    }
  }

  /// Get unique domains
  Future<List<String>> getUniqueDomains() async {
    try {
      final results = await _databaseHelper.rawQuery('''
        SELECT DISTINCT 
               CASE 
                 WHEN url LIKE 'http://%' THEN substr(url, 8)
                 WHEN url LIKE 'https://%' THEN substr(url, 9)
                 ELSE url
               END as domain
        FROM ${DatabaseConfig.historyTable}
        WHERE is_hidden = 0
        ORDER BY domain
      ''', [0]);

      return results.map((map) {
        final domain = map['domain'] as String;
        final slashIndex = domain.indexOf('/');
        return slashIndex > 0 ? domain.substring(0, slashIndex) : domain;
      }).where((domain) => domain.isNotEmpty).toSet().toList();
    } catch (e) {
      throw HistoryRepositoryException('Failed to get unique domains: $e');
    }
  }

  /// Export history to JSON
  Future<String> exportToJson({DateTime? startDate, DateTime? endDate}) async {
    try {
      final entries = await getByDateRange(
        startDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        endDate ?? DateTime.now(),
      );
      
      final jsonData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'history': entries.map((entry) => entry.toJson()).toList(),
      };
      
      return jsonEncode(jsonData);
    } catch (e) {
      throw HistoryRepositoryException('Failed to export history: $e');
    }
  }

  /// Export history to CSV
  Future<String> exportToCsv({DateTime? startDate, DateTime? endDate}) async {
    try {
      final entries = await getByDateRange(
        startDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        endDate ?? DateTime.now(),
      );
      
      final csvLines = <String>[];
      csvLines.add(HistoryEntry.csvHeaders.join(','));
      
      for (final entry in entries) {
        csvLines.add(entry.toCsvRow().map((field) => '"$field"').join(','));
      }
      
      return csvLines.join('\n');
    } catch (e) {
      throw HistoryRepositoryException('Failed to export history to CSV: $e');
    }
  }

  /// Import history from JSON
  Future<List<HistoryEntry>> importFromJson(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final historyData = jsonData['history'] as List<dynamic>;
      
      final importedEntries = <HistoryEntry>[];
      
      await _databaseHelper.transaction((txn) async {
        for (final entryData in historyData) {
          final entry = HistoryEntry.fromJson(entryData as Map<String, dynamic>);
          
          final id = await txn.insert(
            DatabaseConfig.historyTable,
            entry.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          importedEntries.add(entry.copyWith(id: id));
        }
      });
      
      return importedEntries;
    } catch (e) {
      throw HistoryRepositoryException('Failed to import history: $e');
    }
  }

  /// Backup history to file
  Future<File> backupToFile(String filePath, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final jsonData = await exportToJson(startDate: startDate, endDate: endDate);
      final file = File(filePath);
      await file.writeAsString(jsonData);
      return file;
    } catch (e) {
      throw HistoryRepositoryException('Failed to backup history: $e');
    }
  }

  /// Restore history from file
  Future<List<HistoryEntry>> restoreFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importFromJson(jsonString);
    } catch (e) {
      throw HistoryRepositoryException('Failed to restore history: $e');
    }
  }

  /// Get history statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final totalCount = await getCount();
      final todayCount = (await getToday()).length;
      final mostVisited = await getMostVisited(limit: 1);
      final uniqueDomains = await getUniqueDomains();
      
      final results = await _databaseHelper.rawQuery('''
        SELECT 
          AVG(visit_count) as avg_visits,
          MAX(visit_count) as max_visits,
          MIN(first_visited) as oldest_entry,
          MAX(last_visited) as newest_entry
        FROM ${DatabaseConfig.historyTable}
        WHERE is_hidden = 0
      ''', [0]);
      
      final stats = results.first;
      
      return {
        'total_entries': totalCount,
        'today_entries': todayCount,
        'unique_domains': uniqueDomains.length,
        'average_visits': (stats['avg_visits'] as num?)?.toDouble() ?? 0.0,
        'max_visits': stats['max_visits'] as int? ?? 0,
        'most_visited_url': mostVisited.isNotEmpty ? mostVisited.first.url : null,
        'oldest_entry': stats['oldest_entry'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(stats['oldest_entry'] as int)
            : null,
        'newest_entry': stats['newest_entry'] != null
            ? DateTime.fromMillisecondsSinceEpoch(stats['newest_entry'] as int)
            : null,
      };
    } catch (e) {
      throw HistoryRepositoryException('Failed to get history statistics: $e');
    }
  }

  /// Batch delete history entries
  Future<void> deleteBatch(List<int> ids) async {
    try {
      final operations = ids.map((id) => 
        BatchOperation.delete(
          DatabaseConfig.historyTable,
          where: 'id = ?',
          whereArgs: [id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw HistoryRepositoryException('Failed to delete history entries in batch: $e');
    }
  }
}

/// Exception thrown by history repository operations
class HistoryRepositoryException implements Exception {
  final String message;
  
  const HistoryRepositoryException(this.message);
  
  @override
  String toString() => 'HistoryRepositoryException: $message';
}
