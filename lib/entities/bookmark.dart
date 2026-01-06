import 'package:equatable/equatable.dart';

/// Bookmark entity representing a saved website bookmark
class Bookmark extends Equatable {
  /// Unique identifier for the bookmark
  final String id;
  
  /// Display title of the bookmark
  final String title;
  
  /// URL of the bookmarked website
  final String url;
  
  /// URL of the website's favicon
  final String? faviconUrl;
  
  /// Optional description of the bookmark
  final String? description;
  
  /// ID of the parent folder (null for root level)
  final String? folderId;
  
  /// Position within the folder for ordering
  final int position;
  
  /// Whether this bookmark is marked as favorite
  final bool isFavorite;
  
  /// Tags associated with the bookmark
  final List<String> tags;
  
  /// When the bookmark was created
  final DateTime createdAt;
  
  /// When the bookmark was last updated
  final DateTime updatedAt;
  
  /// When the bookmark was last accessed
  final DateTime? lastAccessedAt;
  
  /// Number of times the bookmark has been accessed
  final int accessCount;
  
  /// Whether the bookmark is pinned to the bookmarks bar
  final bool isPinned;

  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.faviconUrl,
    this.description,
    this.folderId,
    this.position = 0,
    this.isFavorite = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.accessCount = 0,
    this.isPinned = false,
  });

  /// Create a bookmark from a database map
  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      faviconUrl: map['favicon_url'] as String?,
      description: map['description'] as String?,
      folderId: map['folder_id'] as String?,
      position: map['position'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      tags: _parseTags(map['tags'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      lastAccessedAt: map['last_accessed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_accessed_at'] as int)
          : null,
      accessCount: map['access_count'] as int? ?? 0,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
    );
  }

  /// Convert bookmark to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon_url': faviconUrl,
      'description': description,
      'folder_id': folderId,
      'position': position,
      'is_favorite': isFavorite ? 1 : 0,
      'tags': _serializeTags(tags),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_accessed_at': lastAccessedAt?.millisecondsSinceEpoch,
      'access_count': accessCount,
      'is_pinned': isPinned ? 1 : 0,
    };
  }

  /// Create a copy of the bookmark with updated fields
  Bookmark copyWith({
    String? id,
    String? title,
    String? url,
    String? faviconUrl,
    String? description,
    String? folderId,
    int? position,
    bool? isFavorite,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    bool? isPinned,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      description: description ?? this.description,
      folderId: folderId ?? this.folderId,
      position: position ?? this.position,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Create a new bookmark with current timestamp
  factory Bookmark.create({
    required String id,
    required String title,
    required String url,
    String? faviconUrl,
    String? description,
    String? folderId,
    int position = 0,
    bool isFavorite = false,
    List<String> tags = const [],
    bool isPinned = false,
  }) {
    final now = DateTime.now();
    return Bookmark(
      id: id,
      title: title,
      url: url,
      faviconUrl: faviconUrl,
      description: description,
      folderId: folderId,
      position: position,
      isFavorite: isFavorite,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
    );
  }

  /// Update the bookmark with new access information
  Bookmark markAsAccessed() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: accessCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Validate bookmark data
  bool get isValid {
    return title.trim().isNotEmpty && 
           url.trim().isNotEmpty && 
           Uri.tryParse(url) != null;
  }

  /// Get domain from URL
  String? get domain {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Check if bookmark matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
           url.toLowerCase().contains(lowerQuery) ||
           (description?.toLowerCase().contains(lowerQuery) ?? false) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'faviconUrl': faviconUrl,
      'description': description,
      'folderId': folderId,
      'position': position,
      'isFavorite': isFavorite,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'accessCount': accessCount,
      'isPinned': isPinned,
    };
  }

  /// Create from JSON for import
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      faviconUrl: json['faviconUrl'] as String?,
      description: json['description'] as String?,
      folderId: json['folderId'] as String?,
      position: json['position'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      accessCount: json['accessCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  /// Parse tags from comma-separated string
  static List<String> _parseTags(String? tagsString) {
    if (tagsString == null || tagsString.isEmpty) {
      return [];
    }
    return tagsString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  /// Serialize tags to comma-separated string
  static String? _serializeTags(List<String> tags) {
    if (tags.isEmpty) return null;
    return tags.join(',');
  }

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        faviconUrl,
        description,
        folderId,
        position,
        isFavorite,
        tags,
        createdAt,
        updatedAt,
        lastAccessedAt,
        accessCount,
        isPinned,
      ];

  @override
  String toString() {
    return 'Bookmark(id: $id, title: $title, url: $url, folderId: $folderId)';
  }
}
