import 'package:equatable/equatable.dart';

/// Folder entity for organizing bookmarks in a hierarchical structure
class Folder extends Equatable {
  /// Unique identifier for the folder
  final String id;
  
  /// Display name of the folder
  final String name;
  
  /// ID of the parent folder (null for root level)
  final String? parentId;
  
  /// Position within the parent folder for ordering
  final int position;
  
  /// Whether the folder is expanded in the UI
  final bool isExpanded;
  
  /// Optional icon for the folder
  final String? icon;
  
  /// When the folder was created
  final DateTime createdAt;
  
  /// When the folder was last updated
  final DateTime updatedAt;

  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.position = 0,
    this.isExpanded = true,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a folder from a database map
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      position: map['position'] as int? ?? 0,
      isExpanded: (map['is_expanded'] as int? ?? 1) == 1,
      icon: map['icon'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert folder to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'position': position,
      'is_expanded': isExpanded ? 1 : 0,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy of the folder with updated fields
  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    int? position,
    bool? isExpanded,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      isExpanded: isExpanded ?? this.isExpanded,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a new folder with current timestamp
  factory Folder.create({
    required String id,
    required String name,
    String? parentId,
    int position = 0,
    bool isExpanded = true,
    String? icon,
  }) {
    final now = DateTime.now();
    return Folder(
      id: id,
      name: name,
      parentId: parentId,
      position: position,
      isExpanded: isExpanded,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update the folder with new information
  Folder update({
    String? name,
    String? parentId,
    int? position,
    bool? isExpanded,
    String? icon,
  }) {
    return copyWith(
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      isExpanded: isExpanded ?? this.isExpanded,
      icon: icon ?? this.icon,
      updatedAt: DateTime.now(),
    );
  }

  /// Move folder to a new parent
  Folder moveTo(String? newParentId, int newPosition) {
    return copyWith(
      parentId: newParentId,
      position: newPosition,
      updatedAt: DateTime.now(),
    );
  }

  /// Rename the folder
  Folder rename(String newName) {
    return copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle expanded state
  Folder toggleExpanded() {
    return copyWith(
      isExpanded: !isExpanded,
      updatedAt: DateTime.now(),
    );
  }

  /// Expand the folder
  Folder expand() {
    return copyWith(
      isExpanded: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Collapse the folder
  Folder collapse() {
    return copyWith(
      isExpanded: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if this is a root folder
  bool get isRoot => parentId == null;

  /// Check if this is a child of the specified folder
  bool isChildOf(String folderId) => parentId == folderId;

  /// Validate folder data
  bool get isValid {
    return name.trim().isNotEmpty;
  }

  /// Check if folder matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery);
  }

  /// Get folder depth in hierarchy (0 for root folders)
  int getDepth(List<Folder> allFolders) {
    if (isRoot) return 0;
    
    final parent = allFolders.firstWhere(
      (f) => f.id == parentId,
      orElse: () => throw StateError('Parent folder not found'),
    );
    
    return 1 + parent.getDepth(allFolders);
  }

  /// Get all ancestor folder IDs
  List<String> getAncestorIds(List<Folder> allFolders) {
    if (isRoot) return [];
    
    final ancestors = <String>[];
    String? currentParentId = parentId;
    
    while (currentParentId != null) {
      ancestors.add(currentParentId);
      final parent = allFolders.firstWhere(
        (f) => f.id == currentParentId,
        orElse: () => throw StateError('Parent folder not found'),
      );
      currentParentId = parent.parentId;
    }
    
    return ancestors;
  }

  /// Get all descendant folder IDs
  List<String> getDescendantIds(List<Folder> allFolders) {
    final descendants = <String>[];
    final children = allFolders.where((f) => f.parentId == id);
    
    for (final child in children) {
      descendants.add(child.id);
      descendants.addAll(child.getDescendantIds(allFolders));
    }
    
    return descendants;
  }

  /// Check if this folder can be moved to the target folder
  bool canMoveTo(String? targetParentId, List<Folder> allFolders) {
    // Can't move to itself
    if (targetParentId == id) return false;
    
    // Can't move to a descendant (would create a cycle)
    if (targetParentId != null) {
      final descendants = getDescendantIds(allFolders);
      if (descendants.contains(targetParentId)) return false;
    }
    
    return true;
  }

  /// Get folder path as a list of folder names
  List<String> getPath(List<Folder> allFolders) {
    if (isRoot) return [name];
    
    final parent = allFolders.firstWhere(
      (f) => f.id == parentId,
      orElse: () => throw StateError('Parent folder not found'),
    );
    
    return [...parent.getPath(allFolders), name];
  }

  /// Get folder path as a string
  String getPathString(List<Folder> allFolders, {String separator = ' > '}) {
    return getPath(allFolders).join(separator);
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'position': position,
      'isExpanded': isExpanded,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON for import
  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      position: json['position'] as int? ?? 0,
      isExpanded: json['isExpanded'] as bool? ?? true,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        parentId,
        position,
        isExpanded,
        icon,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, parentId: $parentId, position: $position)';
  }
}

/// Predefined folder IDs for system folders
class SystemFolders {
  static const String bookmarksBar = 'bookmarks_bar';
  static const String otherBookmarks = 'other_bookmarks';
  static const String mobileBookmarks = 'mobile_bookmarks';
}

/// Folder tree helper for working with hierarchical folder structures
class FolderTree {
  final List<Folder> folders;

  const FolderTree(this.folders);

  /// Get root folders (folders with no parent)
  List<Folder> get rootFolders {
    return folders.where((f) => f.isRoot).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Get children of a specific folder
  List<Folder> getChildren(String folderId) {
    return folders.where((f) => f.parentId == folderId).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Get folder by ID
  Folder? getFolder(String id) {
    try {
      return folders.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if folder exists
  bool hasFolder(String id) {
    return folders.any((f) => f.id == id);
  }

  /// Get all folders in a flat list, ordered by hierarchy
  List<Folder> getFlatList() {
    final result = <Folder>[];
    
    void addFolderAndChildren(Folder folder) {
      result.add(folder);
      final children = getChildren(folder.id);
      for (final child in children) {
        addFolderAndChildren(child);
      }
    }
    
    for (final root in rootFolders) {
      addFolderAndChildren(root);
    }
    
    return result;
  }

  /// Search folders by name
  List<Folder> search(String query) {
    return folders.where((f) => f.matchesSearch(query)).toList();
  }

  /// Validate folder tree integrity
  bool get isValid {
    // Check for orphaned folders (parent doesn't exist)
    for (final folder in folders) {
      if (folder.parentId != null && !hasFolder(folder.parentId!)) {
        return false;
      }
    }
    
    // Check for circular references
    for (final folder in folders) {
      try {
        folder.getDepth(folders);
      } catch (e) {
        return false;
      }
    }
    
    return true;
  }
}
