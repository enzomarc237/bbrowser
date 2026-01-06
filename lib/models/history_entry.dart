import 'package:equatable/equatable.dart';
import 'dart:convert';

/// Represents a browsing history entry
class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.id,
    required this.url,
    required this.title,
    this.favicon,
    required this.visitedAt,
    this.visitDuration,
    this.visitCount = 1,
    required this.lastVisitAt,
    this.referrerUrl,
    this.isIncognito = false,
    this.pageTransition,
    this.scrollPosition,
    this.formData,
    this.searchTerms,
    required this.domain,
    this.path,
    this.queryParams,
    this.fragment,
    this.isBookmarked = false,
    this.isFavorite = false,
    this.rating = 0,
    this.notes,
    this.metadata,
  });

  /// Unique identifier for the history entry
  final String id;

  /// URL that was visited
  final String url;

  /// Title of the page
  final String title;

  /// Favicon URL for the page
  final String? favicon;

  /// When the page was first visited
  final DateTime visitedAt;

  /// How long the user spent on the page (in seconds)
  final int? visitDuration;

  /// Number of times this URL has been visited
  final int visitCount;

  /// When the page was last visited
  final DateTime lastVisitAt;

  /// URL of the referring page
  final String? referrerUrl;

  /// Whether this was visited in incognito mode
  final bool isIncognito;

  /// Type of page transition (link, typed, reload, etc.)
  final String? pageTransition;

  /// Scroll position when leaving the page
  final double? scrollPosition;

  /// Form data that was submitted (encrypted)
  final String? formData;

  /// Search terms used to find this page
  final String? searchTerms;

  /// Domain of the URL
  final String domain;

  /// Path component of the URL
  final String? path;

  /// Query parameters of the URL
  final String? queryParams;

  /// Fragment/anchor of the URL
  final String? fragment;

  /// Whether this page is bookmarked
  final bool isBookmarked;

  /// Whether this page is marked as favorite
  final bool isFavorite;

  /// User rating for this page (0-5)
  final int rating;

  /// User notes about this page
  final String? notes;

  /// Additional metadata as JSON string
  final String? metadata;

  /// Creates a copy of this history entry with updated values
  HistoryEntry copyWith({
    String? id,
    String? url,
    String? title,
    String? favicon,
    DateTime? visitedAt,
    int? visitDuration,
    int? visitCount,
    DateTime? lastVisitAt,
    String? referrerUrl,
    bool? isIncognito,
    String? pageTransition,
    double? scrollPosition,
    String? formData,
    String? searchTerms,
    String? domain,
    String? path,
    String? queryParams,
    String? fragment,
    bool? isBookmarked,
    bool? isFavorite,
    int? rating,
    String? notes,
    String? metadata,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      favicon: favicon ?? this.favicon,
      visitedAt: visitedAt ?? this.visitedAt,
      visitDuration: visitDuration ?? this.visitDuration,
      visitCount: visitCount ?? this.visitCount,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
      referrerUrl: referrerUrl ?? this.referrerUrl,
      isIncognito: isIncognito ?? this.isIncognito,
      pageTransition: pageTransition ?? this.pageTransition,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      formData: formData ?? this.formData,
      searchTerms: searchTerms ?? this.searchTerms,
      domain: domain ?? this.domain,
      path: path ?? this.path,
      queryParams: queryParams ?? this.queryParams,
      fragment: fragment ?? this.fragment,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a new history entry
  factory HistoryEntry.create({
    String? id,
    required String url,
    required String title,
    String? favicon,
    String? referrerUrl,
    bool isIncognito = false,
    String? pageTransition,
    String? searchTerms,
  }) {
    final now = DateTime.now();
    final uri = Uri.parse(url);
    
    return HistoryEntry(
      id: id ?? 'history_${now.millisecondsSinceEpoch}',
      url: url,
      title: title,
      favicon: favicon,
      visitedAt: now,
      lastVisitAt: now,
      referrerUrl: referrerUrl,
      isIncognito: isIncognito,
      pageTransition: pageTransition,
      searchTerms: searchTerms,
      domain: uri.host,
      path: uri.path.isEmpty ? null : uri.path,
      queryParams: uri.query.isEmpty ? null : uri.query,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
    );
  }

  /// Creates a history entry from JSON data
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      favicon: json['favicon'] as String?,
      visitedAt: DateTime.fromMillisecondsSinceEpoch(json['visited_at'] as int),
      visitDuration: json['visit_duration'] as int?,
      visitCount: json['visit_count'] as int? ?? 1,
      lastVisitAt: DateTime.fromMillisecondsSinceEpoch(json['last_visit_at'] as int),
      referrerUrl: json['referrer_url'] as String?,
      isIncognito: (json['is_incognito'] as int? ?? 0) == 1,
      pageTransition: json['page_transition'] as String?,
      scrollPosition: (json['scroll_position'] as num?)?.toDouble(),
      formData: json['form_data'] as String?,
      searchTerms: json['search_terms'] as String?,
      domain: json['domain'] as String,
      path: json['path'] as String?,
      queryParams: json['query_params'] as String?,
      fragment: json['fragment'] as String?,
      isBookmarked: (json['is_bookmarked'] as int? ?? 0) == 1,
      isFavorite: (json['is_favorite'] as int? ?? 0) == 1,
      rating: json['rating'] as int? ?? 0,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as String?,
    );
  }

  /// Creates a history entry from database row
  factory HistoryEntry.fromDatabase(Map<String, dynamic> row) {
    return HistoryEntry.fromJson(row);
  }

  /// Converts the history entry to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon': favicon,
      'visited_at': visitedAt.millisecondsSinceEpoch,
      'visit_duration': visitDuration,
      'visit_count': visitCount,
      'last_visit_at': lastVisitAt.millisecondsSinceEpoch,
      'referrer_url': referrerUrl,
      'is_incognito': isIncognito ? 1 : 0,
      'page_transition': pageTransition,
      'scroll_position': scrollPosition,
      'form_data': formData,
      'search_terms': searchTerms,
      'domain': domain,
      'path': path,
      'query_params': queryParams,
      'fragment': fragment,
      'is_bookmarked': isBookmarked ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'rating': rating,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Converts the history entry to database format
  Map<String, dynamic> toDatabase() {
    return toJson();
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
  HistoryEntry withMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(metadata: jsonEncode(newMetadata));
  }

  /// Get search terms as a list
  List<String> get searchTermsList {
    if (searchTerms == null || searchTerms!.isEmpty) return [];
    return searchTerms!.split(',').map((term) => term.trim()).where((term) => term.isNotEmpty).toList();
  }

  /// Set search terms from a list
  HistoryEntry withSearchTerms(List<String> terms) {
    return copyWith(searchTerms: terms.join(','));
  }

  /// Check if history entry matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
           url.toLowerCase().contains(lowerQuery) ||
           domain.toLowerCase().contains(lowerQuery) ||
           (notes?.toLowerCase().contains(lowerQuery) ?? false) ||
           searchTermsList.any((term) => term.toLowerCase().contains(lowerQuery));
  }

  /// Get full URL with query params and fragment
  String get fullUrl {
    var fullUrl = url;
    if (queryParams != null && queryParams!.isNotEmpty) {
      fullUrl += '?$queryParams';
    }
    if (fragment != null && fragment!.isNotEmpty) {
      fullUrl += '#$fragment';
    }
    return fullUrl;
  }

  /// Check if this is a search result page
  bool get isSearchResult {
    return searchTerms != null && searchTerms!.isNotEmpty;
  }

  /// Get time spent on page in a human-readable format
  String get visitDurationFormatted {
    if (visitDuration == null) return 'Unknown';
    
    final duration = Duration(seconds: visitDuration!);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Check if this entry is recent (within last 24 hours)
  bool get isRecent {
    return DateTime.now().difference(lastVisitAt).inHours < 24;
  }

  /// Check if this entry is from today
  bool get isToday {
    final now = DateTime.now();
    final visitDate = lastVisitAt;
    return now.year == visitDate.year &&
           now.month == visitDate.month &&
           now.day == visitDate.day;
  }

  /// Check if this entry is from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return lastVisitAt.isAfter(weekStart);
  }

  /// Record a new visit to this URL
  HistoryEntry recordVisit({
    int? duration,
    double? scrollPos,
    String? transition,
  }) {
    final now = DateTime.now();
    return copyWith(
      visitCount: visitCount + 1,
      lastVisitAt: now,
      visitDuration: duration,
      scrollPosition: scrollPos,
      pageTransition: transition,
    );
  }

  /// Mark as bookmarked
  HistoryEntry markAsBookmarked() {
    return copyWith(isBookmarked: true);
  }

  /// Mark as unbookmarked
  HistoryEntry markAsUnbookmarked() {
    return copyWith(isBookmarked: false);
  }

  /// Toggle favorite status
  HistoryEntry toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// Update rating
  HistoryEntry updateRating(int newRating) {
    if (newRating < 0 || newRating > 5) {
      throw ArgumentError('Rating must be between 0 and 5');
    }
    return copyWith(rating: newRating);
  }

  /// Add or update notes
  HistoryEntry updateNotes(String newNotes) {
    return copyWith(notes: newNotes.isEmpty ? null : newNotes);
  }

  /// Check if entry is valid
  bool get isValid {
    return id.isNotEmpty && 
           url.isNotEmpty && 
           title.isNotEmpty && 
           domain.isNotEmpty;
  }

  /// Get visit frequency (visits per day since first visit)
  double get visitFrequency {
    final daysSinceFirst = DateTime.now().difference(visitedAt).inDays;
    if (daysSinceFirst == 0) return visitCount.toDouble();
    return visitCount / daysSinceFirst;
  }

  /// Check if this is a frequently visited page
  bool get isFrequentlyVisited {
    return visitCount >= 5 || visitFrequency >= 0.5;
  }

  /// Get page category based on domain and path
  String get category {
    final lowerDomain = domain.toLowerCase();
    
    if (lowerDomain.contains('google') || lowerDomain.contains('bing') || 
        lowerDomain.contains('duckduckgo') || lowerDomain.contains('yahoo')) {
      return 'Search';
    }
    
    if (lowerDomain.contains('youtube') || lowerDomain.contains('vimeo') || 
        lowerDomain.contains('netflix') || lowerDomain.contains('twitch')) {
      return 'Video';
    }
    
    if (lowerDomain.contains('github') || lowerDomain.contains('stackoverflow') || 
        lowerDomain.contains('developer') || path?.contains('docs') == true) {
      return 'Development';
    }
    
    if (lowerDomain.contains('news') || lowerDomain.contains('bbc') || 
        lowerDomain.contains('cnn') || lowerDomain.contains('reddit')) {
      return 'News';
    }
    
    if (lowerDomain.contains('shop') || lowerDomain.contains('amazon') || 
        lowerDomain.contains('ebay') || lowerDomain.contains('store')) {
      return 'Shopping';
    }
    
    return 'General';
  }

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        favicon,
        visitedAt,
        visitDuration,
        visitCount,
        lastVisitAt,
        referrerUrl,
        isIncognito,
        pageTransition,
        scrollPosition,
        formData,
        searchTerms,
        domain,
        path,
        queryParams,
        fragment,
        isBookmarked,
        isFavorite,
        rating,
        notes,
        metadata,
      ];

  @override
  String toString() {
    return 'HistoryEntry(id: $id, url: $url, title: $title, visitCount: $visitCount, lastVisit: $lastVisitAt)';
  }
}

/// History statistics for a domain or time period
class HistoryStats extends Equatable {
  const HistoryStats({
    required this.totalVisits,
    required this.uniquePages,
    required this.totalTimeSpent,
    required this.averageTimePerPage,
    required this.mostVisitedPage,
    required this.topDomains,
    required this.visitsByDay,
    required this.searchQueries,
  });

  /// Total number of visits
  final int totalVisits;

  /// Number of unique pages visited
  final int uniquePages;

  /// Total time spent browsing (in seconds)
  final int totalTimeSpent;

  /// Average time spent per page (in seconds)
  final double averageTimePerPage;

  /// Most frequently visited page
  final HistoryEntry? mostVisitedPage;

  /// Top domains by visit count
  final Map<String, int> topDomains;

  /// Visits grouped by day
  final Map<DateTime, int> visitsByDay;

  /// Most common search queries
  final Map<String, int> searchQueries;

  /// Get total time spent in a human-readable format
  String get totalTimeSpentFormatted {
    final duration = Duration(seconds: totalTimeSpent);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get average time per page in a human-readable format
  String get averageTimePerPageFormatted {
    final duration = Duration(seconds: averageTimePerPage.round());
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  List<Object?> get props => [
        totalVisits,
        uniquePages,
        totalTimeSpent,
        averageTimePerPage,
        mostVisitedPage,
        topDomains,
        visitsByDay,
        searchQueries,
      ];
}
