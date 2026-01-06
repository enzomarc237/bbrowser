import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_config.dart';
import '../entities/bookmark.dart';

/// Repository for managing bookmark data operations
class BookmarkRepository {
  final DatabaseHelper _databaseHelper;

  BookmarkRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Create a new bookmark
  Future<Bookmark> create(Bookmark bookmark) async {
    try {
      final id = await _databaseHelper.insert(
        DatabaseConfig.bookmarksTable,
        bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return bookmark.copyWith(id: id.toString());
    } catch (e) {
      throw BookmarkRepositoryException('Failed to create bookmark: $e');
    }
  }

  /// Get bookmark by ID
  Future<Bookmark?> getById(String id) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Bookmark.fromMap(results.first);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to get bookmark by ID: $e');
    }
  }

  /// Get all bookmarks
  Future<List<Bookmark>> getAll({
    String? folderId,
    bool? isFavorite,
    int? limit,
    int? offset,
  }) async {
    try {
      String? where;
      List<Object?> whereArgs = [];

      if (folderId != null) {
        where = 'folder_id = ?';
        whereArgs.add(folderId);
      }

      if (isFavorite != null) {
        final favoriteCondition = 'is_favorite = ?';
        if (where != null) {
          where = '$where AND $favoriteCondition';
        } else {
          where = favoriteCondition;
        }
        whereArgs.add(isFavorite ? 1 : 0);
      }

      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        where: where,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'position ASC, created_at DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => Bookmark.fromMap(map)).toList();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to get bookmarks: $e');
    }
  }

  /// Get bookmarks by folder ID
  Future<List<Bookmark>> getByFolderId(String folderId) async {
    return getAll(folderId: folderId);
  }

  /// Get favorite bookmarks
  Future<List<Bookmark>> getFavorites() async {
    return getAll(isFavorite: true);
  }

  /// Get recently added bookmarks
  Future<List<Bookmark>> getRecentlyAdded({int limit = 10}) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map((map) => Bookmark.fromMap(map)).toList();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to get recent bookmarks: $e');
    }
  }

  /// Get most accessed bookmarks
  Future<List<Bookmark>> getMostAccessed({int limit = 10}) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        orderBy: 'access_count DESC, last_accessed_at DESC',
        limit: limit,
      );

      return results.map((map) => Bookmark.fromMap(map)).toList();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to get most accessed bookmarks: $e');
    }
  }

  /// Search bookmarks
  Future<List<Bookmark>> search(String query, {int? limit}) async {
    try {
      final searchQuery = '%${query.toLowerCase()}%';
      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        where: '''
          LOWER(title) LIKE ? OR 
          LOWER(url) LIKE ? OR 
          LOWER(description) LIKE ? OR 
          LOWER(tags) LIKE ?
        ''',
        whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery],
        orderBy: 'access_count DESC, created_at DESC',
        limit: limit,
      );

      return results.map((map) => Bookmark.fromMap(map)).toList();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to search bookmarks: $e');
    }
  }

  /// Search bookmarks by tag
  Future<List<Bookmark>> searchByTag(String tag) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        where: 'tags LIKE ?',
        whereArgs: ['%$tag%'],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => Bookmark.fromMap(map)).toList();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to search bookmarks by tag: $e');
    }
  }

  /// Get bookmarks by URL
  Future<List<Bookmark>> getByUrl(String url) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        where: 'url = ?',
        whereArgs: [url],
      );

      return results.map((map) => Bookmark.fromMap(map)).toList();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to get bookmarks by URL: $e');
    }
  }

  /// Check if URL is bookmarked
  Future<bool> isBookmarked(String url) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.bookmarksTable,
        where: 'url = ?',
        whereArgs: [url],
        limit: 1,
      );

      return results.isNotEmpty;
    } catch (e) {
      throw BookmarkRepositoryException('Failed to check if URL is bookmarked: $e');
    }
  }

  /// Update bookmark
  Future<Bookmark> update(Bookmark bookmark) async {
    try {
      final updatedBookmark = bookmark.copyWith(updatedAt: DateTime.now());
      
      await _databaseHelper.update(
        DatabaseConfig.bookmarksTable,
        updatedBookmark.toMap(),
        where: 'id = ?',
        whereArgs: [bookmark.id],
      );

      return updatedBookmark;
    } catch (e) {
      throw BookmarkRepositoryException('Failed to update bookmark: $e');
    }
  }

  /// Delete bookmark
  Future<void> delete(String id) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.bookmarksTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw BookmarkRepositoryException('Failed to delete bookmark: $e');
    }
  }

  /// Delete bookmarks by folder ID
  Future<void> deleteByFolderId(String folderId) async {
    try {
      await _databaseHelper.delete(
        DatabaseConfig.bookmarksTable,
        where: 'folder_id = ?',
        whereArgs: [folderId],
      );
    } catch (e) {
      throw BookmarkRepositoryException('Failed to delete bookmarks by folder: $e');
    }
  }

  /// Move bookmark to folder
  Future<Bookmark> moveToFolder(String bookmarkId, String? folderId, int position) async {
    try {
      final bookmark = await getById(bookmarkId);
      if (bookmark == null) {
        throw BookmarkRepositoryException('Bookmark not found');
      }

      final updatedBookmark = bookmark.copyWith(
        folderId: folderId,
        position: position,
        updatedAt: DateTime.now(),
      );

      return await update(updatedBookmark);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to move bookmark: $e');
    }
  }

  /// Reorder bookmarks in folder
  Future<void> reorderInFolder(String? folderId, List<String> bookmarkIds) async {
    try {
      await _databaseHelper.transaction((txn) async {
        for (int i = 0; i < bookmarkIds.length; i++) {
          await txn.update(
            DatabaseConfig.bookmarksTable,
            {
              'position': i,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ? AND folder_id ${folderId != null ? '= ?' : 'IS NULL'}',
            whereArgs: folderId != null ? [bookmarkIds[i], folderId] : [bookmarkIds[i]],
          );
        }
      });
    } catch (e) {
      throw BookmarkRepositoryException('Failed to reorder bookmarks: $e');
    }
  }

  /// Mark bookmark as accessed
  Future<Bookmark> markAsAccessed(String id) async {
    try {
      final bookmark = await getById(id);
      if (bookmark == null) {
        throw BookmarkRepositoryException('Bookmark not found');
      }

      final updatedBookmark = bookmark.markAsAccessed();
      return await update(updatedBookmark);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to mark bookmark as accessed: $e');
    }
  }

  /// Get bookmark count
  Future<int> getCount({String? folderId, bool? isFavorite}) async {
    try {
      String? where;
      List<Object?> whereArgs = [];

      if (folderId != null) {
        where = 'folder_id = ?';
        whereArgs.add(folderId);
      }

      if (isFavorite != null) {
        final favoriteCondition = 'is_favorite = ?';
        if (where != null) {
          where = '$where AND $favoriteCondition';
        } else {
          where = favoriteCondition;
        }
        whereArgs.add(isFavorite ? 1 : 0);
      }

      final results = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConfig.bookmarksTable}' +
        (where != null ? ' WHERE $where' : ''),
        whereArgs.isNotEmpty ? whereArgs : null,
      );

      return results.first['count'] as int;
    } catch (e) {
      throw BookmarkRepositoryException('Failed to get bookmark count: $e');
    }
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    try {
      final results = await _databaseHelper.rawQuery(
        'SELECT DISTINCT tags FROM ${DatabaseConfig.bookmarksTable} WHERE tags IS NOT NULL AND tags != ""',
      );

      final allTags = <String>{};
      for (final row in results) {
        final tagsString = row['tags'] as String?;
        if (tagsString != null && tagsString.isNotEmpty) {
          final tags = tagsString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty);
          allTags.addAll(tags);
        }
      }

      return allTags.toList()..sort();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to get all tags: $e');
    }
  }

  /// Export bookmarks to JSON
  Future<String> exportToJson({String? folderId}) async {
    try {
      final bookmarks = await getAll(folderId: folderId);
      final jsonData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'bookmarks': bookmarks.map((bookmark) => bookmark.toJson()).toList(),
      };
      
      return jsonEncode(jsonData);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to export bookmarks: $e');
    }
  }

  /// Import bookmarks from JSON
  Future<List<Bookmark>> importFromJson(String jsonString, {String? targetFolderId}) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final bookmarksData = jsonData['bookmarks'] as List<dynamic>;
      
      final importedBookmarks = <Bookmark>[];
      
      await _databaseHelper.transaction((txn) async {
        for (final bookmarkData in bookmarksData) {
          final bookmark = Bookmark.fromJson(bookmarkData as Map<String, dynamic>);
          
          // Override folder ID if specified
          final bookmarkToImport = targetFolderId != null
              ? bookmark.copyWith(folderId: targetFolderId)
              : bookmark;
          
          final id = await txn.insert(
            DatabaseConfig.bookmarksTable,
            bookmarkToImport.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          importedBookmarks.add(bookmarkToImport.copyWith(id: id.toString()));
        }
      });
      
      return importedBookmarks;
    } catch (e) {
      throw BookmarkRepositoryException('Failed to import bookmarks: $e');
    }
  }

  /// Backup bookmarks to file
  Future<File> backupToFile(String filePath, {String? folderId}) async {
    try {
      final jsonData = await exportToJson(folderId: folderId);
      final file = File(filePath);
      await file.writeAsString(jsonData);
      return file;
    } catch (e) {
      throw BookmarkRepositoryException('Failed to backup bookmarks: $e');
    }
  }

  /// Restore bookmarks from file
  Future<List<Bookmark>> restoreFromFile(String filePath, {String? targetFolderId}) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importFromJson(jsonString, targetFolderId: targetFolderId);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to restore bookmarks: $e');
    }
  }

  /// Clear all bookmarks
  Future<void> clear() async {
    try {
      await _databaseHelper.delete(DatabaseConfig.bookmarksTable);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to clear bookmarks: $e');
    }
  }

  /// Batch create bookmarks
  Future<List<Bookmark>> createBatch(List<Bookmark> bookmarks) async {
    try {
      final operations = bookmarks.map((bookmark) => 
        BatchOperation.insert(DatabaseConfig.bookmarksTable, bookmark.toMap())
      ).toList();
      
      final results = await _databaseHelper.batch(operations);
      
      return bookmarks.asMap().entries.map((entry) {
        final index = entry.key;
        final bookmark = entry.value;
        final id = results[index] as int;
        return bookmark.copyWith(id: id.toString());
      }).toList();
    } catch (e) {
      throw BookmarkRepositoryException('Failed to create bookmarks in batch: $e');
    }
  }

  /// Update multiple bookmarks
  Future<void> updateBatch(List<Bookmark> bookmarks) async {
    try {
      final operations = bookmarks.map((bookmark) => 
        BatchOperation.update(
          DatabaseConfig.bookmarksTable,
          bookmark.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [bookmark.id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to update bookmarks in batch: $e');
    }
  }

  /// Delete multiple bookmarks
  Future<void> deleteBatch(List<String> ids) async {
    try {
      final operations = ids.map((id) => 
        BatchOperation.delete(
          DatabaseConfig.bookmarksTable,
          where: 'id = ?',
          whereArgs: [id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw BookmarkRepositoryException('Failed to delete bookmarks in batch: $e');
    }
  }
}

/// Exception thrown by bookmark repository operations
class BookmarkRepositoryException implements Exception {
  final String message;
  
  const BookmarkRepositoryException(this.message);
  
  @override
  String toString() => 'BookmarkRepositoryException: $message';
}
