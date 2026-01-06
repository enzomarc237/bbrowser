import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_config.dart';
import '../entities/tab.dart';

/// Repository for managing tab data operations
class TabRepository {
  final DatabaseHelper _databaseHelper;

  TabRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Create a new tab
  Future<Tab> create(Tab tab) async {
    try {
      final id = await _databaseHelper.insert(
        DatabaseConfig.tabsTable,
        tab.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return tab.copyWith(id: id.toString());
    } catch (e) {
      throw TabRepositoryException('Failed to create tab: $e');
    }
  }

  /// Get tab by ID
  Future<Tab?> getById(String id) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.tabsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Tab.fromMap(results.first);
    } catch (e) {
      throw TabRepositoryException('Failed to get tab by ID: $e');
    }
  }

  /// Get all tabs
  Future<List<Tab>> getAll({String? sessionId}) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.tabsTable,
        where: sessionId != null ? 'session_id = ?' : null,
        whereArgs: sessionId != null ? [sessionId] : null,
        orderBy: 'position ASC',
      );

      return results.map((map) => Tab.fromMap(map)).toList();
    } catch (e) {
      throw TabRepositoryException('Failed to get tabs: $e');
    }
  }

  /// Get tabs by session ID
  Future<List<Tab>> getBySessionId(String sessionId) async {
    return getAll(sessionId: sessionId);
  }

  /// Get active tab in session
  Future<Tab?> getActiveTab(String sessionId) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.tabsTable,
        where: 'session_id = ? AND is_active = 1',
        whereArgs: [sessionId],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Tab.fromMap(results.first);
    } catch (e) {
      throw TabRepositoryException('Failed to get active tab: $e');
    }
  }

  /// Get pinned tabs in session
  Future<List<Tab>> getPinnedTabs(String sessionId) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.tabsTable,
        where: 'session_id = ? AND is_pinned = 1',
        whereArgs: [sessionId],
        orderBy: 'position ASC',
      );

      return results.map((map) => Tab.fromMap(map)).toList();
    } catch (e) {
      throw TabRepositoryException('Failed to get pinned tabs: $e');
    }
  }

  /// Get unpinned tabs in session
  Future<List<Tab>> getUnpinnedTabs(String sessionId) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.tabsTable,
        where: 'session_id = ? AND is_pinned = 0',
        whereArgs: [sessionId],
        orderBy: 'position ASC',
      );

      return results.map((map) => Tab.fromMap(map)).toList();
    } catch (e) {
      throw TabRepositoryException('Failed to get unpinned tabs: $e');
    }
  }

  /// Search tabs
  Future<List<Tab>> search(String query, {String? sessionId}) async {
    try {
      final searchQuery = '%${query.toLowerCase()}%';
      String where = '''
        LOWER(url) LIKE ? OR 
        LOWER(title) LIKE ?
      ''';
      List<Object?> whereArgs = [searchQuery, searchQuery];

      if (sessionId != null) {
        where = 'session_id = ? AND ($where)';
        whereArgs = [sessionId, ...whereArgs];
      }

      final results = await _databaseHelper.query(
        DatabaseConfig.tabsTable,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'last_accessed DESC',
      );

      return results.map((map) => Tab.fromMap(map)).toList();
    } catch (e) {
      throw TabRepositoryException('Failed to search tabs: $e');
    }
  }

  /// Get recently accessed tabs
  Future<List<Tab>> getRecentlyAccessed({String? sessionId, int limit = 10}) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.tabsTable,
        where: sessionId != null ? 'session_id = ?' : null,
        whereArgs: sessionId != null ? [sessionId] : null,
        orderBy: 'last_accessed DESC',
        limit: limit,
      );

      return results.map((map) => Tab.fromMap(map)).toList();
    } catch (e) {
      throw TabRepositoryException('Failed to get recently accessed tabs: $e');
    }
  }

  /// Update tab
  Future<Tab> update(Tab tab) async {
    try {
      final updatedTab = tab.copyWith(updatedAt: DateTime.now());
      
      await _databaseHelper.update(
        DatabaseConfig.tabsTable,
        updatedTab.toMap(),
        where: 'id = ?',
        whereArgs: [tab.id],
      );

      return updatedTab;
    } catch (e) {
      throw TabRepositoryException('Failed to update tab: $e');
    }
  }

  /// Delete tab
  Future<void> delete(String id) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.tabsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw TabRepositoryException('Failed to delete tab: $e');
    }
  }

  /// Delete tabs by session ID
  Future<void> deleteBySessionId(String sessionId) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.tabsTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      throw TabRepositoryException('Failed to delete tabs by session: $e');
    }
  }

  /// Activate tab (deactivates others in session)
  Future<Tab> activateTab(String tabId) async {
    try {
      final tab = await getById(tabId);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      await _databaseHelper.transaction((txn) async {
        // Deactivate all tabs in the session
        await txn.update(
          DatabaseConfig.tabsTable,
          {'is_active': 0},
          where: 'session_id = ?',
          whereArgs: [tab.sessionId],
        );

        // Activate the specified tab
        await txn.update(
          DatabaseConfig.tabsTable,
          {
            'is_active': 1,
            'last_accessed': DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [tabId],
        );
      });

      return tab.activate();
    } catch (e) {
      throw TabRepositoryException('Failed to activate tab: $e');
    }
  }

  /// Pin tab
  Future<Tab> pinTab(String id) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final pinnedTab = tab.pin();
      return await update(pinnedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to pin tab: $e');
    }
  }

  /// Unpin tab
  Future<Tab> unpinTab(String id) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final unpinnedTab = tab.unpin();
      return await update(unpinnedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to unpin tab: $e');
    }
  }

  /// Move tab to new position
  Future<Tab> moveTab(String id, int newPosition) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final movedTab = tab.moveTo(newPosition);
      return await update(movedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to move tab: $e');
    }
  }

  /// Reorder tabs in session
  Future<void> reorderTabs(String sessionId, List<String> tabIds) async {
    try {
      await _databaseHelper.transaction((txn) async {
        for (int i = 0; i < tabIds.length; i++) {
          await txn.update(
            DatabaseConfig.tabsTable,
            {
              'position': i,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ? AND session_id = ?',
            whereArgs: [tabIds[i], sessionId],
          );
        }
      });
    } catch (e) {
      throw TabRepositoryException('Failed to reorder tabs: $e');
    }
  }

  /// Navigate tab to URL
  Future<Tab> navigateTab(String id, String url, {String? title, String? faviconUrl}) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final navigatedTab = tab.navigateTo(url, newTitle: title, newFaviconUrl: faviconUrl);
      return await update(navigatedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to navigate tab: $e');
    }
  }

  /// Update tab metadata
  Future<Tab> updateTabMetadata(String id, {String? title, String? faviconUrl}) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final updatedTab = tab.updateMetadata(title: title, faviconUrl: faviconUrl);
      return await update(updatedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to update tab metadata: $e');
    }
  }

  /// Update tab scroll position
  Future<Tab> updateScrollPosition(String id, double scrollPosition) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final updatedTab = tab.updateScrollPosition(scrollPosition);
      return await update(updatedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to update scroll position: $e');
    }
  }

  /// Update tab zoom level
  Future<Tab> updateZoomLevel(String id, double zoomLevel) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final updatedTab = tab.updateZoomLevel(zoomLevel);
      return await update(updatedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to update zoom level: $e');
    }
  }

  /// Mark tab as accessed
  Future<Tab> markAsAccessed(String id) async {
    try {
      final tab = await getById(id);
      if (tab == null) {
        throw TabRepositoryException('Tab not found');
      }

      final accessedTab = tab.markAsAccessed();
      return await update(accessedTab);
    } catch (e) {
      throw TabRepositoryException('Failed to mark tab as accessed: $e');
    }
  }

  /// Get tab count
  Future<int> getCount({String? sessionId}) async {
    try {
      final results = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConfig.tabsTable}' +
        (sessionId != null ? ' WHERE session_id = ?' : ''),
        sessionId != null ? [sessionId] : null,
      );

      return results.first['count'] as int;
    } catch (e) {
      throw TabRepositoryException('Failed to get tab count: $e');
    }
  }

  /// Get unique session IDs
  Future<List<String>> getSessionIds() async {
    try {
      final results = await _databaseHelper.rawQuery(
        'SELECT DISTINCT session_id FROM ${DatabaseConfig.tabsTable} ORDER BY session_id',
      );

      return results.map((map) => map['session_id'] as String).toList();
    } catch (e) {
      throw TabRepositoryException('Failed to get session IDs: $e');
    }
  }

  /// Clean up old tabs
  Future<int> cleanupOldTabs({int retentionDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      
      final deletedCount = await _databaseHelper.delete(
        DatabaseConfig.tabsTable,
        where: 'last_accessed < ?',
        whereArgs: [cutoffDate.millisecondsSinceEpoch],
      );

      return deletedCount;
    } catch (e) {
      throw TabRepositoryException('Failed to cleanup old tabs: $e');
    }
  }

  /// Export tabs to JSON
  Future<String> exportToJson({String? sessionId}) async {
    try {
      final tabs = await getAll(sessionId: sessionId);
      final jsonData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'session_id': sessionId,
        'tabs': tabs.map((tab) => tab.toJson()).toList(),
      };
      
      return jsonEncode(jsonData);
    } catch (e) {
      throw TabRepositoryException('Failed to export tabs: $e');
    }
  }

  /// Import tabs from JSON
  Future<List<Tab>> importFromJson(String jsonString, {String? targetSessionId}) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final tabsData = jsonData['tabs'] as List<dynamic>;
      
      final importedTabs = <Tab>[];
      
      await _databaseHelper.transaction((txn) async {
        for (final tabData in tabsData) {
          final tab = Tab.fromJson(tabData as Map<String, dynamic>);
          
          // Override session ID if specified
          final tabToImport = targetSessionId != null
              ? tab.copyWith(sessionId: targetSessionId)
              : tab;
          
          final id = await txn.insert(
            DatabaseConfig.tabsTable,
            tabToImport.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          importedTabs.add(tabToImport.copyWith(id: id.toString()));
        }
      });
      
      return importedTabs;
    } catch (e) {
      throw TabRepositoryException('Failed to import tabs: $e');
    }
  }

  /// Backup tabs to file
  Future<File> backupToFile(String filePath, {String? sessionId}) async {
    try {
      final jsonData = await exportToJson(sessionId: sessionId);
      final file = File(filePath);
      await file.writeAsString(jsonData);
      return file;
    } catch (e) {
      throw TabRepositoryException('Failed to backup tabs: $e');
    }
  }

  /// Restore tabs from file
  Future<List<Tab>> restoreFromFile(String filePath, {String? targetSessionId}) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importFromJson(jsonString, targetSessionId: targetSessionId);
    } catch (e) {
      throw TabRepositoryException('Failed to restore tabs: $e');
    }
  }

  /// Clear all tabs
  Future<void> clear() async {
    try {
      await _databaseHelper.delete(DatabaseConfig.tabsTable);
    } catch (e) {
      throw TabRepositoryException('Failed to clear tabs: $e');
    }
  }

  /// Batch create tabs
  Future<List<Tab>> createBatch(List<Tab> tabs) async {
    try {
      final operations = tabs.map((tab) => 
        BatchOperation.insert(DatabaseConfig.tabsTable, tab.toMap())
      ).toList();
      
      final results = await _databaseHelper.batch(operations);
      
      return tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        final id = results[index] as int;
        return tab.copyWith(id: id.toString());
      }).toList();
    } catch (e) {
      throw TabRepositoryException('Failed to create tabs in batch: $e');
    }
  }

  /// Update multiple tabs
  Future<void> updateBatch(List<Tab> tabs) async {
    try {
      final operations = tabs.map((tab) => 
        BatchOperation.update(
          DatabaseConfig.tabsTable,
          tab.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [tab.id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw TabRepositoryException('Failed to update tabs in batch: $e');
    }
  }

  /// Delete multiple tabs
  Future<void> deleteBatch(List<String> ids) async {
    try {
      final operations = ids.map((id) => 
        BatchOperation.delete(
          DatabaseConfig.tabsTable,
          where: 'id = ?',
          whereArgs: [id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw TabRepositoryException('Failed to delete tabs in batch: $e');
    }
  }

  /// Get tab statistics
  Future<Map<String, dynamic>> getStatistics({String? sessionId}) async {
    try {
      final totalCount = await getCount(sessionId: sessionId);
      final pinnedCount = (await getPinnedTabs(sessionId ?? '')).length;
      
      final results = await _databaseHelper.rawQuery('''
        SELECT 
          COUNT(DISTINCT session_id) as session_count,
          AVG(CASE WHEN last_accessed > 0 THEN 
            (strftime('%s', 'now') * 1000 - last_accessed) / (24 * 60 * 60 * 1000) 
            ELSE 0 END) as avg_age_days,
          MIN(created_at) as oldest_tab,
          MAX(last_accessed) as newest_access
        FROM ${DatabaseConfig.tabsTable}
        ${sessionId != null ? 'WHERE session_id = ?' : ''}
      ''', sessionId != null ? [sessionId] : null);
      
      final stats = results.first;
      
      return {
        'total_tabs': totalCount,
        'pinned_tabs': pinnedCount,
        'session_count': stats['session_count'] as int? ?? 0,
        'average_age_days': (stats['avg_age_days'] as num?)?.toDouble() ?? 0.0,
        'oldest_tab': stats['oldest_tab'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(stats['oldest_tab'] as int)
            : null,
        'newest_access': stats['newest_access'] != null
            ? DateTime.fromMillisecondsSinceEpoch(stats['newest_access'] as int)
            : null,
      };
    } catch (e) {
      throw TabRepositoryException('Failed to get tab statistics: $e');
    }
  }
}

/// Exception thrown by tab repository operations
class TabRepositoryException implements Exception {
  final String message;
  
  const TabRepositoryException(this.message);
  
  @override
  String toString() => 'TabRepositoryException: $message';
}
