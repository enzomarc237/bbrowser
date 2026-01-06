import 'package:equatable/equatable.dart';

/// Tab entity representing a browser tab with session data
class Tab extends Equatable {
  /// Unique identifier for the tab
  final String id;
  
  /// Session ID this tab belongs to
  final String sessionId;
  
  /// Current URL of the tab
  final String url;
  
  /// Title of the current page
  final String? title;
  
  /// URL of the page's favicon
  final String? faviconUrl;
  
  /// Position of the tab in the tab bar
  final int position;
  
  /// Whether this tab is currently active
  final bool isActive;
  
  /// Whether this tab is pinned
  final bool isPinned;
  
  /// Scroll position of the page (0.0 to 1.0)
  final double scrollPosition;
  
  /// Zoom level of the page (1.0 = 100%)
  final double zoomLevel;
  
  /// User agent string for this tab
  final String? userAgent;
  
  /// When the tab was created
  final DateTime createdAt;
  
  /// When the tab was last updated
  final DateTime updatedAt;
  
  /// When the tab was last accessed
  final DateTime lastAccessed;

  const Tab({
    required this.id,
    required this.sessionId,
    required this.url,
    this.title,
    this.faviconUrl,
    this.position = 0,
    this.isActive = false,
    this.isPinned = false,
    this.scrollPosition = 0.0,
    this.zoomLevel = 1.0,
    this.userAgent,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessed,
  });

  /// Create a tab from a database map
  factory Tab.fromMap(Map<String, dynamic> map) {
    return Tab(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      url: map['url'] as String,
      title: map['title'] as String?,
      faviconUrl: map['favicon_url'] as String?,
      position: map['position'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      scrollPosition: (map['scroll_position'] as num?)?.toDouble() ?? 0.0,
      zoomLevel: (map['zoom_level'] as num?)?.toDouble() ?? 1.0,
      userAgent: map['user_agent'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(map['last_accessed'] as int),
    );
  }

  /// Convert tab to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'url': url,
      'title': title,
      'favicon_url': faviconUrl,
      'position': position,
      'is_active': isActive ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'scroll_position': scrollPosition,
      'zoom_level': zoomLevel,
      'user_agent': userAgent,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_accessed': lastAccessed.millisecondsSinceEpoch,
    };
  }

  /// Create a copy of the tab with updated fields
  Tab copyWith({
    String? id,
    String? sessionId,
    String? url,
    String? title,
    String? faviconUrl,
    int? position,
    bool? isActive,
    bool? isPinned,
    double? scrollPosition,
    double? zoomLevel,
    String? userAgent,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessed,
  }) {
    return Tab(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      url: url ?? this.url,
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  /// Create a new tab with current timestamp
  factory Tab.create({
    required String id,
    required String sessionId,
    required String url,
    String? title,
    String? faviconUrl,
    int position = 0,
    bool isActive = false,
    bool isPinned = false,
    String? userAgent,
  }) {
    final now = DateTime.now();
    return Tab(
      id: id,
      sessionId: sessionId,
      url: url,
      title: title,
      faviconUrl: faviconUrl,
      position: position,
      isActive: isActive,
      isPinned: isPinned,
      userAgent: userAgent,
      createdAt: now,
      updatedAt: now,
      lastAccessed: now,
    );
  }

  /// Navigate to a new URL
  Tab navigateTo(String newUrl, {String? newTitle, String? newFaviconUrl}) {
    return copyWith(
      url: newUrl,
      title: newTitle,
      faviconUrl: newFaviconUrl,
      scrollPosition: 0.0, // Reset scroll position on navigation
      updatedAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
  }

  /// Update page metadata
  Tab updateMetadata({String? title, String? faviconUrl}) {
    return copyWith(
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      updatedAt: DateTime.now(),
    );
  }

  /// Update scroll position
  Tab updateScrollPosition(double newPosition) {
    return copyWith(
      scrollPosition: newPosition.clamp(0.0, 1.0),
      updatedAt: DateTime.now(),
    );
  }

  /// Update zoom level
  Tab updateZoomLevel(double newZoomLevel) {
    return copyWith(
      zoomLevel: newZoomLevel.clamp(0.25, 5.0), // Reasonable zoom limits
      updatedAt: DateTime.now(),
    );
  }

  /// Activate this tab
  Tab activate() {
    return copyWith(
      isActive: true,
      lastAccessed: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Deactivate this tab
  Tab deactivate() {
    return copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Pin this tab
  Tab pin() {
    return copyWith(
      isPinned: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Unpin this tab
  Tab unpin() {
    return copyWith(
      isPinned: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Move tab to new position
  Tab moveTo(int newPosition) {
    return copyWith(
      position: newPosition,
      updatedAt: DateTime.now(),
    );
  }

  /// Update user agent
  Tab updateUserAgent(String? newUserAgent) {
    return copyWith(
      userAgent: newUserAgent,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark tab as accessed
  Tab markAsAccessed() {
    return copyWith(
      lastAccessed: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get display title (title or URL if no title)
  String get displayTitle {
    if (title?.isNotEmpty == true) return title!;
    if (url.isEmpty) return 'New Tab';
    
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (e) {
      return url;
    }
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

  /// Check if this is a new tab (about:blank or empty)
  bool get isNewTab {
    return url.isEmpty || url == 'about:blank' || url == 'chrome://newtab/';
  }

  /// Check if this is a secure connection (HTTPS)
  bool get isSecure {
    return url.startsWith('https://');
  }

  /// Check if this tab was accessed recently (within last hour)
  bool get isRecentlyAccessed {
    final now = DateTime.now();
    final difference = now.difference(lastAccessed);
    return difference.inHours < 1;
  }

  /// Validate tab data
  bool get isValid {
    return id.isNotEmpty && sessionId.isNotEmpty;
  }

  /// Check if tab matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return url.toLowerCase().contains(lowerQuery) ||
           (title?.toLowerCase().contains(lowerQuery) ?? false) ||
           (domain?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Get tab age in hours
  int get ageInHours {
    return DateTime.now().difference(createdAt).inHours;
  }

  /// Get time since last access in minutes
  int get minutesSinceLastAccess {
    return DateTime.now().difference(lastAccessed).inMinutes;
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'url': url,
      'title': title,
      'faviconUrl': faviconUrl,
      'position': position,
      'isActive': isActive,
      'isPinned': isPinned,
      'scrollPosition': scrollPosition,
      'zoomLevel': zoomLevel,
      'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  /// Create from JSON for import
  factory Tab.fromJson(Map<String, dynamic> json) {
    return Tab(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      url: json['url'] as String,
      title: json['title'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      position: json['position'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        url,
        title,
        faviconUrl,
        position,
        isActive,
        isPinned,
        scrollPosition,
        zoomLevel,
        userAgent,
        createdAt,
        updatedAt,
        lastAccessed,
      ];

  @override
  String toString() {
    return 'Tab(id: $id, url: $url, title: $title, isActive: $isActive)';
  }
}

/// Tab session for grouping related tabs
class TabSession extends Equatable {
  /// Unique identifier for the session
  final String id;
  
  /// Name of the session
  final String name;
  
  /// Whether this is the current active session
  final bool isActive;
  
  /// When the session was created
  final DateTime createdAt;
  
  /// When the session was last updated
  final DateTime updatedAt;
  
  /// List of tabs in this session
  final List<Tab> tabs;

  const TabSession({
    required this.id,
    required this.name,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.tabs = const [],
  });

  /// Create a copy with updated fields
  TabSession copyWith({
    String? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Tab>? tabs,
  }) {
    return TabSession(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tabs: tabs ?? this.tabs,
    );
  }

  /// Create a new session
  factory TabSession.create({
    required String id,
    required String name,
    bool isActive = false,
  }) {
    final now = DateTime.now();
    return TabSession(
      id: id,
      name: name,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get active tab in this session
  Tab? get activeTab {
    try {
      return tabs.firstWhere((tab) => tab.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Get pinned tabs
  List<Tab> get pinnedTabs {
    return tabs.where((tab) => tab.isPinned).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Get unpinned tabs
  List<Tab> get unpinnedTabs {
    return tabs.where((tab) => !tab.isPinned).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Get all tabs sorted by position
  List<Tab> get sortedTabs {
    return [...tabs]..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tabs': tabs.map((tab) => tab.toJson()).toList(),
    };
  }

  /// Create from JSON for import
  factory TabSession.fromJson(Map<String, dynamic> json) {
    return TabSession(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tabs: (json['tabs'] as List<dynamic>?)
          ?.map((tabJson) => Tab.fromJson(tabJson as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isActive,
        createdAt,
        updatedAt,
        tabs,
      ];

  @override
  String toString() {
    return 'TabSession(id: $id, name: $name, tabCount: ${tabs.length})';
  }
}
