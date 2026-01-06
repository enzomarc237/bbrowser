import 'package:equatable/equatable.dart';
import 'dart:convert';

/// Represents a bookmark with hierarchical structure support
class Bookmark extends Equatable {
  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    this.parentId,
    this.position = 0,
    this.isFolder = false,
    this.description,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.accessCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.metadata,
  });

  /// Unique identifier for the bookmark
  final String id;

  /// Title of the bookmark
  final String title;

  /// URL of the bookmark (empty for folders)
  final String url;

  /// Favicon URL for the bookmark
  final String? favicon;

  /// Parent folder ID (null for root level)
  final String? parentId;

  /// Position within the parent folder
  final int position;

  /// Whether this is a folder
  final bool isFolder;

  /// Optional description
  final String? description;

  /// Comma-separated tags
  final String? tags;

  /// When the bookmark was created
  final DateTime createdAt;

  /// When the bookmark was last updated
  final DateTime updatedAt;

  /// When the bookmark was last accessed
  final DateTime? lastAccessedAt;

  /// Number of times accessed
  final int accessCount;

  /// Whether the bookmark is pinned
  final bool isPinned;

  /// Whether the bookmark is archived
  final bool isArchived;

  /// Additional metadata as JSON string
  final String? metadata;

  /// Creates a copy of this bookmark with updated values
  Bookmark copyWith({
    String? id,
    String? title,
    String? url,
    String? favicon,
    String? parentId,
    int? position,
    bool? isFolder,
    String? description,
    String? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    bool? isPinned,
    bool? isArchived,
    String? metadata,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      favicon: favicon ?? this.favicon,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      isFolder: isFolder ?? this.isFolder,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a new bookmark folder
  factory Bookmark.folder({
    String? id,
    required String title,
    String? parentId,
    int position = 0,
    String? description,
  }) {
    final now = DateTime.now();
    return Bookmark(
      id: id ?? 'folder_${now.millisecondsSinceEpoch}',
      title: title,
      url: '',
      parentId: parentId,
      position: position,
      isFolder: true,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a new bookmark
  factory Bookmark.bookmark({
    String? id,
    required String title,
    required String url,
    String? favicon,
    String? parentId,
    int position = 0,
    String? description,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return Bookmark(
      id: id ?? 'bookmark_${now.millisecondsSinceEpoch}',
      title: title,
      url: url,
      favicon: favicon,
      parentId: parentId,
      position: position,
      isFolder: false,
      description: description,
      tags: tags?.join(','),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a bookmark from JSON data
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      favicon: json['favicon'] as String?,
      parentId: json['parent_id'] as String?,
      position: json['position'] as int? ?? 0,
      isFolder: (json['is_folder'] as int? ?? 0) == 1,
      description: json['description'] as String?,
      tags: json['tags'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_accessed_at'] as int)
          : null,
      accessCount: json['access_count'] as int? ?? 0,
      isPinned: (json['is_pinned'] as int? ?? 0) == 1,
      isArchived: (json['is_archived'] as int? ?? 0) == 1,
      metadata: json['metadata'] as String?,
    );
  }

  /// Creates a bookmark from database row
  factory Bookmark.fromDatabase(Map<String, dynamic> row) {
    return Bookmark.fromJson(row);
  }

  /// Converts the bookmark to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'parent_id': parentId,
      'position': position,
      'is_folder': isFolder ? 1 : 0,
      'description': description,
      'tags': tags,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_accessed_at': lastAccessedAt?.millisecondsSinceEpoch,
      'access_count': accessCount,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'metadata': metadata,
    };
  }

  /// Converts the bookmark to database format
  Map<String, dynamic> toDatabase() {
    return toJson();
  }

  /// Get tags as a list
  List<String> get tagsList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  /// Set tags from a list
  Bookmark withTags(List<String> newTags) {
    return copyWith(tags: newTags.join(','));
  }

  /// Get metadata as a map
  Map<String, dynamic>? get metadataMap {
    if (metadata == null || metadata!.isEmpty) return null;
    try {
      return jsonDecode(metadata!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Set metadata from a map
  Bookmark withMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(metadata: jsonEncode(newMetadata));
  }

  /// Check if bookmark matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
           url.toLowerCase().contains(lowerQuery) ||
           (description?.toLowerCase().contains(lowerQuery) ?? false) ||
           tagsList.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  /// Check if bookmark has a specific tag
  bool hasTag(String tag) {
    return tagsList.contains(tag);
  }

  /// Get domain from URL
  String? get domain {
    if (url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Check if bookmark is valid
  bool get isValid {
    if (id.isEmpty || title.isEmpty) return false;
    if (!isFolder && url.isEmpty) return false;
    return true;
  }

  /// Mark as accessed
  Bookmark markAsAccessed() {
    final now = DateTime.now();
    return copyWith(
      lastAccessedAt: now,
      accessCount: accessCount + 1,
      updatedAt: now,
    );
  }

  /// Toggle pinned status
  Bookmark togglePinned() {
    return copyWith(
      isPinned: !isPinned,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle archived status
  Bookmark toggleArchived() {
    return copyWith(
      isArchived: !isArchived,
      updatedAt: DateTime.now(),
    );
  }

  /// Move to new position
  Bookmark moveTo({String? newParentId, int? newPosition}) {
    return copyWith(
      parentId: newParentId ?? parentId,
      position: newPosition ?? position,
      updatedAt: DateTime.now(),
    );
  }

  /// Update title and URL
  Bookmark updateContent({
    String? newTitle,
    String? newUrl,
    String? newDescription,
    List<String>? newTags,
  }) {
    return copyWith(
      title: newTitle ?? title,
      url: newUrl ?? url,
      description: newDescription ?? description,
      tags: newTags?.join(',') ?? tags,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        favicon,
        parentId,
        position,
        isFolder,
        description,
        tags,
        createdAt,
        updatedAt,
        lastAccessedAt,
        accessCount,
        isPinned,
        isArchived,
        metadata,
      ];

  @override
  String toString() {
    return 'Bookmark(id: $id, title: $title, url: $url, isFolder: $isFolder, position: $position)';
  }
}

/// Bookmark folder with children
class BookmarkFolder extends Bookmark {
  const BookmarkFolder({
    required super.id,
    required super.title,
    super.parentId,
    super.position = 0,
    super.description,
    super.tags,
    required super.createdAt,
    required super.updatedAt,
    super.lastAccessedAt,
    super.accessCount = 0,
    super.isPinned = false,
    super.isArchived = false,
    super.metadata,
    this.children = const [],
  }) : super(
          url: '',
          isFolder: true,
        );

  /// Child bookmarks and folders
  final List<Bookmark> children;

  /// Create folder with children
  BookmarkFolder copyWithChildren(List<Bookmark> newChildren) {
    return BookmarkFolder(
      id: id,
      title: title,
      parentId: parentId,
      position: position,
      description: description,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastAccessedAt: lastAccessedAt,
      accessCount: accessCount,
      isPinned: isPinned,
      isArchived: isArchived,
      metadata: metadata,
      children: newChildren,
    );
  }

  /// Get total number of bookmarks (recursive)
  int get totalBookmarkCount {
    int count = 0;
    for (final child in children) {
      if (child.isFolder && child is BookmarkFolder) {
        count += child.totalBookmarkCount;
      } else if (!child.isFolder) {
        count++;
      }
    }
    return count;
  }

  /// Get total number of folders (recursive)
  int get totalFolderCount {
    int count = 0;
    for (final child in children) {
      if (child.isFolder) {
        count++;
        if (child is BookmarkFolder) {
          count += child.totalFolderCount;
        }
      }
    }
    return count;
  }

  /// Find bookmark by ID (recursive)
  Bookmark? findBookmarkById(String bookmarkId) {
    for (final child in children) {
      if (child.id == bookmarkId) {
        return child;
      }
      if (child.isFolder && child is BookmarkFolder) {
        final found = child.findBookmarkById(bookmarkId);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Search bookmarks (recursive)
  List<Bookmark> searchBookmarks(String query) {
    final results = <Bookmark>[];
    for (final child in children) {
      if (child.matchesSearch(query)) {
        results.add(child);
      }
      if (child.isFolder && child is BookmarkFolder) {
        results.addAll(child.searchBookmarks(query));
      }
    }
    return results;
  }

  /// Get all bookmarks (recursive, excluding folders)
  List<Bookmark> get allBookmarks {
    final bookmarks = <Bookmark>[];
    for (final child in children) {
      if (!child.isFolder) {
        bookmarks.add(child);
      } else if (child is BookmarkFolder) {
        bookmarks.addAll(child.allBookmarks);
      }
    }
    return bookmarks;
  }

  /// Get all folders (recursive)
  List<BookmarkFolder> get allFolders {
    final folders = <BookmarkFolder>[];
    for (final child in children) {
      if (child.isFolder && child is BookmarkFolder) {
        folders.add(child);
        folders.addAll(child.allFolders);
      }
    }
    return folders;
  }

  @override
  List<Object?> get props => [...super.props, children];
}
