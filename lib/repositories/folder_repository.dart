import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_config.dart';
import '../entities/folder.dart';

/// Repository for managing folder data operations
class FolderRepository {
  final DatabaseHelper _databaseHelper;

  FolderRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Create a new folder
  Future<Folder> create(Folder folder) async {
    try {
      final id = await _databaseHelper.insert(
        DatabaseConfig.foldersTable,
        folder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return folder.copyWith(id: id.toString());
    } catch (e) {
      throw FolderRepositoryException('Failed to create folder: $e');
    }
  }

  /// Get folder by ID
  Future<Folder?> getById(String id) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.foldersTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Folder.fromMap(results.first);
    } catch (e) {
      throw FolderRepositoryException('Failed to get folder by ID: $e');
    }
  }

  /// Get all folders
  Future<List<Folder>> getAll() async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.foldersTable,
        orderBy: 'parent_id ASC, position ASC',
      );

      return results.map((map) => Folder.fromMap(map)).toList();
    } catch (e) {
      throw FolderRepositoryException('Failed to get folders: $e');
    }
  }

  /// Get root folders (folders with no parent)
  Future<List<Folder>> getRootFolders() async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.foldersTable,
        where: 'parent_id IS NULL',
        orderBy: 'position ASC',
      );

      return results.map((map) => Folder.fromMap(map)).toList();
    } catch (e) {
      throw FolderRepositoryException('Failed to get root folders: $e');
    }
  }

  /// Get child folders of a parent folder
  Future<List<Folder>> getChildren(String parentId) async {
    try {
      final results = await _databaseHelper.query(
        DatabaseConfig.foldersTable,
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'position ASC',
      );

      return results.map((map) => Folder.fromMap(map)).toList();
    } catch (e) {
      throw FolderRepositoryException('Failed to get child folders: $e');
    }
  }

  /// Get folder tree structure
  Future<FolderTree> getFolderTree() async {
    try {
      final allFolders = await getAll();
      return FolderTree(allFolders);
    } catch (e) {
      throw FolderRepositoryException('Failed to get folder tree: $e');
    }
  }

  /// Search folders by name
  Future<List<Folder>> search(String query) async {
    try {
      final searchQuery = '%${query.toLowerCase()}%';
      final results = await _databaseHelper.query(
        DatabaseConfig.foldersTable,
        where: 'LOWER(name) LIKE ?',
        whereArgs: [searchQuery],
        orderBy: 'name ASC',
      );

      return results.map((map) => Folder.fromMap(map)).toList();
    } catch (e) {
      throw FolderRepositoryException('Failed to search folders: $e');
    }
  }

  /// Update folder
  Future<Folder> update(Folder folder) async {
    try {
      final updatedFolder = folder.copyWith(updatedAt: DateTime.now());
      
      await _databaseHelper.update(
        DatabaseConfig.foldersTable,
        updatedFolder.toMap(),
        where: 'id = ?',
        whereArgs: [folder.id],
      );

      return updatedFolder;
    } catch (e) {
      throw FolderRepositoryException('Failed to update folder: $e');
    }
  }

  /// Delete folder
  Future<void> delete(String id) async {
    try {
      // Check if folder has children
      final children = await getChildren(id);
      if (children.isNotEmpty) {
        throw FolderRepositoryException('Cannot delete folder with children');
      }

      await _databaseHelper.delete(
        DatabaseConfig.foldersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw FolderRepositoryException('Failed to delete folder: $e');
    }
  }

  /// Delete folder and all its children recursively
  Future<void> deleteRecursively(String id) async {
    try {
      await _databaseHelper.transaction((txn) async {
        // Get all descendant folders
        final allFolders = await getAll();
        final folderTree = FolderTree(allFolders);
        final folder = folderTree.getFolder(id);
        
        if (folder != null) {
          final descendants = folder.getDescendantIds(allFolders);
          
          // Delete all descendants first (bottom-up)
          for (final descendantId in descendants.reversed) {
            await txn.delete(
              DatabaseConfig.foldersTable,
              where: 'id = ?',
              whereArgs: [descendantId],
            );
          }
          
          // Delete the folder itself
          await txn.delete(
            DatabaseConfig.foldersTable,
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });
    } catch (e) {
      throw FolderRepositoryException('Failed to delete folder recursively: $e');
    }
  }

  /// Move folder to a new parent
  Future<Folder> moveToParent(String folderId, String? newParentId, int newPosition) async {
    try {
      final folder = await getById(folderId);
      if (folder == null) {
        throw FolderRepositoryException('Folder not found');
      }

      // Validate the move
      if (newParentId != null) {
        final allFolders = await getAll();
        if (!folder.canMoveTo(newParentId, allFolders)) {
          throw FolderRepositoryException('Invalid move: would create circular reference');
        }
      }

      final updatedFolder = folder.moveTo(newParentId, newPosition);
      return await update(updatedFolder);
    } catch (e) {
      throw FolderRepositoryException('Failed to move folder: $e');
    }
  }

  /// Rename folder
  Future<Folder> rename(String id, String newName) async {
    try {
      final folder = await getById(id);
      if (folder == null) {
        throw FolderRepositoryException('Folder not found');
      }

      final renamedFolder = folder.rename(newName);
      return await update(renamedFolder);
    } catch (e) {
      throw FolderRepositoryException('Failed to rename folder: $e');
    }
  }

  /// Reorder folders within a parent
  Future<void> reorderInParent(String? parentId, List<String> folderIds) async {
    try {
      await _databaseHelper.transaction((txn) async {
        for (int i = 0; i < folderIds.length; i++) {
          await txn.update(
            DatabaseConfig.foldersTable,
            {
              'position': i,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ? AND parent_id ${parentId != null ? '= ?' : 'IS NULL'}',
            whereArgs: parentId != null ? [folderIds[i], parentId] : [folderIds[i]],
          );
        }
      });
    } catch (e) {
      throw FolderRepositoryException('Failed to reorder folders: $e');
    }
  }

  /// Toggle folder expanded state
  Future<Folder> toggleExpanded(String id) async {
    try {
      final folder = await getById(id);
      if (folder == null) {
        throw FolderRepositoryException('Folder not found');
      }

      final toggledFolder = folder.toggleExpanded();
      return await update(toggledFolder);
    } catch (e) {
      throw FolderRepositoryException('Failed to toggle folder expanded state: $e');
    }
  }

  /// Get folder count
  Future<int> getCount({String? parentId}) async {
    try {
      final results = await _databaseHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConfig.foldersTable}' +
        (parentId != null ? ' WHERE parent_id = ?' : ''),
        parentId != null ? [parentId] : null,
      );

      return results.first['count'] as int;
    } catch (e) {
      throw FolderRepositoryException('Failed to get folder count: $e');
    }
  }

  /// Get folder depth
  Future<int> getFolderDepth(String id) async {
    try {
      final allFolders = await getAll();
      final folder = allFolders.firstWhere((f) => f.id == id);
      return folder.getDepth(allFolders);
    } catch (e) {
      throw FolderRepositoryException('Failed to get folder depth: $e');
    }
  }

  /// Get folder path
  Future<List<String>> getFolderPath(String id) async {
    try {
      final allFolders = await getAll();
      final folder = allFolders.firstWhere((f) => f.id == id);
      return folder.getPath(allFolders);
    } catch (e) {
      throw FolderRepositoryException('Failed to get folder path: $e');
    }
  }

  /// Validate folder tree integrity
  Future<bool> validateTreeIntegrity() async {
    try {
      final folderTree = await getFolderTree();
      return folderTree.isValid;
    } catch (e) {
      throw FolderRepositoryException('Failed to validate tree integrity: $e');
    }
  }

  /// Create system folders if they don't exist
  Future<void> createSystemFolders() async {
    try {
      await _databaseHelper.transaction((txn) async {
        // Create Bookmarks Bar folder
        final bookmarksBarExists = await getById(SystemFolders.bookmarksBar);
        if (bookmarksBarExists == null) {
          final bookmarksBar = Folder.create(
            id: SystemFolders.bookmarksBar,
            name: 'Bookmarks Bar',
            position: 0,
          );
          await txn.insert(DatabaseConfig.foldersTable, bookmarksBar.toMap());
        }

        // Create Other Bookmarks folder
        final otherBookmarksExists = await getById(SystemFolders.otherBookmarks);
        if (otherBookmarksExists == null) {
          final otherBookmarks = Folder.create(
            id: SystemFolders.otherBookmarks,
            name: 'Other Bookmarks',
            position: 1,
          );
          await txn.insert(DatabaseConfig.foldersTable, otherBookmarks.toMap());
        }

        // Create Mobile Bookmarks folder
        final mobileBookmarksExists = await getById(SystemFolders.mobileBookmarks);
        if (mobileBookmarksExists == null) {
          final mobileBookmarks = Folder.create(
            id: SystemFolders.mobileBookmarks,
            name: 'Mobile Bookmarks',
            position: 2,
          );
          await txn.insert(DatabaseConfig.foldersTable, mobileBookmarks.toMap());
        }
      });
    } catch (e) {
      throw FolderRepositoryException('Failed to create system folders: $e');
    }
  }

  /// Export folders to JSON
  Future<String> exportToJson() async {
    try {
      final folders = await getAll();
      final jsonData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'folders': folders.map((folder) => folder.toJson()).toList(),
      };
      
      return jsonEncode(jsonData);
    } catch (e) {
      throw FolderRepositoryException('Failed to export folders: $e');
    }
  }

  /// Import folders from JSON
  Future<List<Folder>> importFromJson(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final foldersData = jsonData['folders'] as List<dynamic>;
      
      final importedFolders = <Folder>[];
      
      await _databaseHelper.transaction((txn) async {
        for (final folderData in foldersData) {
          final folder = Folder.fromJson(folderData as Map<String, dynamic>);
          
          final id = await txn.insert(
            DatabaseConfig.foldersTable,
            folder.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          
          importedFolders.add(folder.copyWith(id: id.toString()));
        }
      });
      
      return importedFolders;
    } catch (e) {
      throw FolderRepositoryException('Failed to import folders: $e');
    }
  }

  /// Backup folders to file
  Future<File> backupToFile(String filePath) async {
    try {
      final jsonData = await exportToJson();
      final file = File(filePath);
      await file.writeAsString(jsonData);
      return file;
    } catch (e) {
      throw FolderRepositoryException('Failed to backup folders: $e');
    }
  }

  /// Restore folders from file
  Future<List<Folder>> restoreFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importFromJson(jsonString);
    } catch (e) {
      throw FolderRepositoryException('Failed to restore folders: $e');
    }
  }

  /// Clear all folders
  Future<void> clear() async {
    try {
      await _databaseHelper.delete(DatabaseConfig.foldersTable);
    } catch (e) {
      throw FolderRepositoryException('Failed to clear folders: $e');
    }
  }

  /// Batch create folders
  Future<List<Folder>> createBatch(List<Folder> folders) async {
    try {
      final operations = folders.map((folder) => 
        BatchOperation.insert(DatabaseConfig.foldersTable, folder.toMap())
      ).toList();
      
      final results = await _databaseHelper.batch(operations);
      
      return folders.asMap().entries.map((entry) {
        final index = entry.key;
        final folder = entry.value;
        final id = results[index] as int;
        return folder.copyWith(id: id.toString());
      }).toList();
    } catch (e) {
      throw FolderRepositoryException('Failed to create folders in batch: $e');
    }
  }

  /// Update multiple folders
  Future<void> updateBatch(List<Folder> folders) async {
    try {
      final operations = folders.map((folder) => 
        BatchOperation.update(
          DatabaseConfig.foldersTable,
          folder.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [folder.id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw FolderRepositoryException('Failed to update folders in batch: $e');
    }
  }

  /// Delete multiple folders
  Future<void> deleteBatch(List<String> ids) async {
    try {
      final operations = ids.map((id) => 
        BatchOperation.delete(
          DatabaseConfig.foldersTable,
          where: 'id = ?',
          whereArgs: [id],
        )
      ).toList();
      
      await _databaseHelper.batch(operations);
    } catch (e) {
      throw FolderRepositoryException('Failed to delete folders in batch: $e');
    }
  }
}

/// Exception thrown by folder repository operations
class FolderRepositoryException implements Exception {
  final String message;
  
  const FolderRepositoryException(this.message);
  
  @override
  String toString() => 'FolderRepositoryException: $message';
}
