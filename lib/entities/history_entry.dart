import 'package:equatable/equatable.dart';

/// History entry entity representing a visited website
class HistoryEntry extends Equatable {
  /// Unique identifier for the history entry
  final int id;
  
  /// URL of the visited website
  final String url;
  
  /// Title of the visited page
  final String? title;
  
  /// URL of the website's favicon
  final String? faviconUrl;
  
  /// Number of times this URL has been visited
  final int visitCount;
  
  /// When the URL was last visited
  final DateTime lastVisited;
  
  /// When the URL was first visited
  final DateTime firstVisited;
  
  /// Number of times the URL was typed directly
  final int typedCount;
  
  /// Whether this entry is hidden from history view
  final bool isHidden;

  const HistoryEntry({
    required this.id,
    required this.url,
    this.title,
    this.faviconUrl,
    this.visitCount = 1,
    required this.lastVisited,
    required this.firstVisited,
    this.typedCount = 0,
    this.isHidden = false,
  });

  /// Create a history entry from a database map
  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int,
      url: map['url'] as String,
      title: map['title'] as String?,
      faviconUrl: map['favicon_url'] as String?,
      visitCount: map['visit_count'] as int? ?? 1,
      lastVisited: DateTime.fromMillisecondsSinceEpoch(map['last_visited'] as int),
      firstVisited: DateTime.fromMillisecondsSinceEpoch(map['first_visited'] as int),
      typedCount: map['typed_count'] as int? ?? 0,
      isHidden: (map['is_hidden'] as int? ?? 0) == 1,
    );
  }

  /// Convert history entry to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon_url': faviconUrl,
      'visit_count': visitCount,
      'last_visited': lastVisited.millisecondsSinceEpoch,
      'first_visited': firstVisited.millisecondsSinceEpoch,
      'typed_count': typedCount,
      'is_hidden': isHidden ? 1 : 0,
    };
  }

  /// Create a copy of the history entry with updated fields
  HistoryEntry copyWith({
    int? id,
    String? url,
    String? title,
    String? faviconUrl,
    int? visitCount,
    DateTime? lastVisited,
    DateTime? firstVisited,
    int? typedCount,
    bool? isHidden,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      visitCount: visitCount ?? this.visitCount,
      lastVisited: lastVisited ?? this.lastVisited,
      firstVisited: firstVisited ?? this.firstVisited,
      typedCount: typedCount ?? this.typedCount,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  /// Create a new history entry for a visit
  factory HistoryEntry.create({
    required String url,
    String? title,
    String? faviconUrl,
    bool wasTyped = false,
  }) {
    final now = DateTime.now();
    return HistoryEntry(
      id: 0, // Will be set by database
      url: url,
      title: title,
      faviconUrl: faviconUrl,
      visitCount: 1,
      lastVisited: now,
      firstVisited: now,
      typedCount: wasTyped ? 1 : 0,
    );
  }

  /// Record a new visit to this URL
  HistoryEntry recordVisit({bool wasTyped = false}) {
    return copyWith(
      visitCount: visitCount + 1,
      lastVisited: DateTime.now(),
      typedCount: wasTyped ? typedCount + 1 : typedCount,
    );
  }

  /// Update the title and favicon
  HistoryEntry updateMetadata({String? title, String? faviconUrl}) {
    return copyWith(
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
  }

  /// Hide this entry from history view
  HistoryEntry hide() {
    return copyWith(isHidden: true);
  }

  /// Show this entry in history view
  HistoryEntry show() {
    return copyWith(isHidden: false);
  }

  /// Validate history entry data
  bool get isValid {
    return url.trim().isNotEmpty && Uri.tryParse(url) != null;
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

  /// Get the display title (title or URL if no title)
  String get displayTitle {
    return title?.isNotEmpty == true ? title! : url;
  }

  /// Check if this is a frequently visited site
  bool get isFrequentlyVisited {
    return visitCount >= 10;
  }

  /// Check if this was visited recently (within last 24 hours)
  bool get isRecentlyVisited {
    final now = DateTime.now();
    final difference = now.difference(lastVisited);
    return difference.inHours < 24;
  }

  /// Check if this was visited today
  bool get isVisitedToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDate = DateTime(lastVisited.year, lastVisited.month, lastVisited.day);
    return visitDate.isAtSameMomentAs(today);
  }

  /// Check if history entry matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return url.toLowerCase().contains(lowerQuery) ||
           (title?.toLowerCase().contains(lowerQuery) ?? false) ||
           (domain?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Get visit frequency score (visits per day since first visit)
  double get visitFrequency {
    final daysSinceFirst = DateTime.now().difference(firstVisited).inDays;
    if (daysSinceFirst == 0) return visitCount.toDouble();
    return visitCount / daysSinceFirst;
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'faviconUrl': faviconUrl,
      'visitCount': visitCount,
      'lastVisited': lastVisited.toIso8601String(),
      'firstVisited': firstVisited.toIso8601String(),
      'typedCount': typedCount,
      'isHidden': isHidden,
    };
  }

  /// Create from JSON for import
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as int,
      url: json['url'] as String,
      title: json['title'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      visitCount: json['visitCount'] as int? ?? 1,
      lastVisited: DateTime.parse(json['lastVisited'] as String),
      firstVisited: DateTime.parse(json['firstVisited'] as String),
      typedCount: json['typedCount'] as int? ?? 0,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  /// Convert to CSV row for export
  List<String> toCsvRow() {
    return [
      url,
      title ?? '',
      visitCount.toString(),
      lastVisited.toIso8601String(),
      firstVisited.toIso8601String(),
      typedCount.toString(),
      isHidden.toString(),
    ];
  }

  /// CSV headers for export
  static List<String> get csvHeaders => [
        'URL',
        'Title',
        'Visit Count',
        'Last Visited',
        'First Visited',
        'Typed Count',
        'Is Hidden',
      ];

  /// Create from CSV row for import
  factory HistoryEntry.fromCsvRow(List<String> row, {int? id}) {
    return HistoryEntry(
      id: id ?? 0,
      url: row[0],
      title: row[1].isEmpty ? null : row[1],
      visitCount: int.tryParse(row[2]) ?? 1,
      lastVisited: DateTime.parse(row[3]),
      firstVisited: DateTime.parse(row[4]),
      typedCount: int.tryParse(row[5]) ?? 0,
      isHidden: row[6].toLowerCase() == 'true',
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        faviconUrl,
        visitCount,
        lastVisited,
        firstVisited,
        typedCount,
        isHidden,
      ];

  @override
  String toString() {
    return 'HistoryEntry(id: $id, url: $url, title: $title, visitCount: $visitCount)';
  }
}
