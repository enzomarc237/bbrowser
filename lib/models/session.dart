import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'tab.dart';

/// Represents a browser session with tabs and state
class Session extends Equatable {
  const Session({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.isActive = false,
    this.isPinned = false,
    this.isArchived = false,
    this.windowId,
    this.activeTabId,
    this.tabs = const [],
    this.metadata,
  });

  /// Unique identifier for the session
  final String id;

  /// Name of the session
  final String name;

  /// Optional description
  final String? description;

  /// When the session was created
  final DateTime createdAt;

  /// When the session was last updated
  final DateTime updatedAt;

  /// When the session was last accessed
  final DateTime? lastAccessedAt;

  /// Whether this is the currently active session
  final bool isActive;

  /// Whether the session is pinned
  final bool isPinned;

  /// Whether the session is archived
  final bool isArchived;

  /// Associated window ID
  final String? windowId;

  /// ID of the currently active tab
  final String? activeTabId;

  /// List of tabs in this session
  final List<Tab> tabs;

  /// Additional metadata as JSON string
  final String? metadata;

  /// Creates a copy of this session with updated values
  Session copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    bool? isActive,
    bool? isPinned,
    bool? isArchived,
    String? windowId,
    String? activeTabId,
    List<Tab>? tabs,
    String? metadata,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      windowId: windowId ?? this.windowId,
      activeTabId: activeTabId ?? this.activeTabId,
      tabs: tabs ?? this.tabs,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a new session
  factory Session.create({
    String? id,
    required String name,
    String? description,
    String? windowId,
    List<Tab>? tabs,
  }) {
    final now = DateTime.now();
    return Session(
      id: id ?? 'session_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      lastAccessedAt: now,
      windowId: windowId,
      tabs: tabs ?? [],
    );
  }

  /// Creates a session from JSON data
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_accessed_at'] as int)
          : null,
      isActive: json['is_active'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      windowId: json['window_id'] as String?,
      activeTabId: json['active_tab_id'] as String?,
      tabs: json['tabs'] != null
          ? (json['tabs'] as List).map((tab) => Tab.fromJson(tab as Map<String, dynamic>)).toList()
          : [],
      metadata: json['metadata'] as String?,
    );
  }

  /// Converts the session to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_accessed_at': lastAccessedAt?.millisecondsSinceEpoch,
      'is_active': isActive,
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'window_id': windowId,
      'active_tab_id': activeTabId,
      'tabs': tabs.map((tab) => tab.toJson()).toList(),
      'metadata': metadata,
    };
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
  Session withMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(metadata: jsonEncode(newMetadata));
  }

  /// Get the currently active tab
  Tab? get activeTab {
    if (activeTabId == null) return null;
    try {
      return tabs.firstWhere((tab) => tab.id == activeTabId);
    } catch (e) {
      return null;
    }
  }

  /// Get number of tabs
  int get tabCount => tabs.length;

  /// Get number of pinned tabs
  int get pinnedTabCount => tabs.where((tab) => tab.isPinned).length;

  /// Get number of loading tabs
  int get loadingTabCount => tabs.where((tab) => tab.isLoading).length;

  /// Check if session has any tabs
  bool get hasTabs => tabs.isNotEmpty;

  /// Check if session is valid
  bool get isValid {
    return id.isNotEmpty && name.isNotEmpty;
  }

  /// Check if session matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           (description?.toLowerCase().contains(lowerQuery) ?? false) ||
           tabs.any((tab) => tab.title.toLowerCase().contains(lowerQuery) ||
                            tab.url.toLowerCase().contains(lowerQuery));
  }

  /// Add a tab to the session
  Session addTab(Tab tab) {
    final updatedTabs = List<Tab>.from(tabs)..add(tab);
    return copyWith(
      tabs: updatedTabs,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a tab from the session
  Session removeTab(String tabId) {
    final updatedTabs = tabs.where((tab) => tab.id != tabId).toList();
    String? newActiveTabId = activeTabId;
    
    // If we're removing the active tab, set a new active tab
    if (activeTabId == tabId && updatedTabs.isNotEmpty) {
      newActiveTabId = updatedTabs.first.id;
    } else if (updatedTabs.isEmpty) {
      newActiveTabId = null;
    }
    
    return copyWith(
      tabs: updatedTabs,
      activeTabId: newActiveTabId,
      updatedAt: DateTime.now(),
    );
  }

  /// Update a tab in the session
  Session updateTab(Tab updatedTab) {
    final updatedTabs = tabs.map((tab) {
      return tab.id == updatedTab.id ? updatedTab : tab;
    }).toList();
    
    return copyWith(
      tabs: updatedTabs,
      updatedAt: DateTime.now(),
    );
  }

  /// Set active tab
  Session setActiveTab(String tabId) {
    // Verify the tab exists
    if (!tabs.any((tab) => tab.id == tabId)) {
      return this;
    }
    
    return copyWith(
      activeTabId: tabId,
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Move tab to new position
  Session moveTab(String tabId, int newPosition) {
    final tabIndex = tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex == -1 || newPosition < 0 || newPosition >= tabs.length) {
      return this;
    }
    
    final updatedTabs = List<Tab>.from(tabs);
    final tab = updatedTabs.removeAt(tabIndex);
    updatedTabs.insert(newPosition, tab);
    
    // Update positions
    for (int i = 0; i < updatedTabs.length; i++) {
      updatedTabs[i] = updatedTabs[i].copyWith(position: i);
    }
    
    return copyWith(
      tabs: updatedTabs,
      updatedAt: DateTime.now(),
    );
  }

  /// Close all tabs
  Session closeAllTabs() {
    return copyWith(
      tabs: [],
      activeTabId: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Close tabs except pinned ones
  Session closeUnpinnedTabs() {
    final pinnedTabs = tabs.where((tab) => tab.isPinned).toList();
    String? newActiveTabId = activeTabId;
    
    // If active tab is not pinned, set new active tab
    if (activeTabId != null && !pinnedTabs.any((tab) => tab.id == activeTabId)) {
      newActiveTabId = pinnedTabs.isNotEmpty ? pinnedTabs.first.id : null;
    }
    
    return copyWith(
      tabs: pinnedTabs,
      activeTabId: newActiveTabId,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark session as accessed
  Session markAsAccessed() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle pinned status
  Session togglePinned() {
    return copyWith(
      isPinned: !isPinned,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle archived status
  Session toggleArchived() {
    return copyWith(
      isArchived: !isArchived,
      updatedAt: DateTime.now(),
    );
  }

  /// Activate session
  Session activate() {
    return copyWith(
      isActive: true,
      lastAccessedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Deactivate session
  Session deactivate() {
    return copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Update session name and description
  Session updateInfo({String? newName, String? newDescription}) {
    return copyWith(
      name: newName ?? name,
      description: newDescription ?? description,
      updatedAt: DateTime.now(),
    );
  }

  /// Get session statistics
  SessionStats get stats {
    return SessionStats(
      totalTabs: tabs.length,
      pinnedTabs: tabs.where((tab) => tab.isPinned).length,
      loadingTabs: tabs.where((tab) => tab.isLoading).length,
      secureTabs: tabs.where((tab) => tab.isSecure).length,
      errorTabs: tabs.where((tab) => tab.hasError).length,
      uniqueDomains: tabs.map((tab) {
        try {
          return Uri.parse(tab.url).host;
        } catch (e) {
          return 'unknown';
        }
      }).toSet().length,
      totalMemoryUsage: tabs.length * 50, // Estimated MB per tab
      createdAt: createdAt,
      lastAccessed: lastAccessedAt ?? createdAt,
    );
  }

  /// Get all unique domains in session
  Set<String> get domains {
    return tabs.map((tab) {
      try {
        return Uri.parse(tab.url).host;
      } catch (e) {
        return 'unknown';
      }
    }).toSet();
  }

  /// Get tabs by domain
  List<Tab> getTabsByDomain(String domain) {
    return tabs.where((tab) {
      try {
        return Uri.parse(tab.url).host == domain;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Duplicate session with new ID
  Session duplicate({String? newName}) {
    final now = DateTime.now();
    final duplicatedTabs = tabs.map((tab) => tab.copyWith(
      id: 'tab_${now.millisecondsSinceEpoch}_${tabs.indexOf(tab)}',
    )).toList();
    
    return Session(
      id: 'session_${now.millisecondsSinceEpoch}',
      name: newName ?? '$name (Copy)',
      description: description,
      createdAt: now,
      updatedAt: now,
      tabs: duplicatedTabs,
      activeTabId: duplicatedTabs.isNotEmpty ? duplicatedTabs.first.id : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdAt,
        updatedAt,
        lastAccessedAt,
        isActive,
        isPinned,
        isArchived,
        windowId,
        activeTabId,
        tabs,
        metadata,
      ];

  @override
  String toString() {
    return 'Session(id: $id, name: $name, tabs: ${tabs.length}, active: $isActive)';
  }
}

/// Session statistics
class SessionStats extends Equatable {
  const SessionStats({
    required this.totalTabs,
    required this.pinnedTabs,
    required this.loadingTabs,
    required this.secureTabs,
    required this.errorTabs,
    required this.uniqueDomains,
    required this.totalMemoryUsage,
    required this.createdAt,
    required this.lastAccessed,
  });

  /// Total number of tabs
  final int totalTabs;

  /// Number of pinned tabs
  final int pinnedTabs;

  /// Number of loading tabs
  final int loadingTabs;

  /// Number of secure (HTTPS) tabs
  final int secureTabs;

  /// Number of tabs with errors
  final int errorTabs;

  /// Number of unique domains
  final int uniqueDomains;

  /// Estimated memory usage in MB
  final int totalMemoryUsage;

  /// When session was created
  final DateTime createdAt;

  /// When session was last accessed
  final DateTime lastAccessed;

  /// Get session age
  Duration get age => DateTime.now().difference(createdAt);

  /// Get time since last access
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessed);

  /// Get formatted memory usage
  String get formattedMemoryUsage {
    if (totalMemoryUsage < 1024) {
      return '${totalMemoryUsage}MB';
    } else {
      return '${(totalMemoryUsage / 1024).toStringAsFixed(1)}GB';
    }
  }

  /// Get security score (0-100)
  int get securityScore {
    if (totalTabs == 0) return 100;
    return ((secureTabs / totalTabs) * 100).round();
  }

  /// Get reliability score (0-100)
  int get reliabilityScore {
    if (totalTabs == 0) return 100;
    return (((totalTabs - errorTabs) / totalTabs) * 100).round();
  }

  @override
  List<Object?> get props => [
        totalTabs,
        pinnedTabs,
        loadingTabs,
        secureTabs,
        errorTabs,
        uniqueDomains,
        totalMemoryUsage,
        createdAt,
        lastAccessed,
      ];
}

/// Session template for creating new sessions
class SessionTemplate extends Equatable {
  const SessionTemplate({
    required this.name,
    required this.description,
    required this.urls,
    this.category = 'General',
    this.icon,
    this.isDefault = false,
  });

  /// Template name
  final String name;

  /// Template description
  final String description;

  /// List of URLs to open
  final List<String> urls;

  /// Template category
  final String category;

  /// Optional icon
  final String? icon;

  /// Whether this is a default template
  final bool isDefault;

  /// Create session from template
  Session createSession({String? sessionName, String? windowId}) {
    final now = DateTime.now();
    final tabs = urls.asMap().entries.map((entry) {
      return Tab.newTab(
        id: 'tab_${now.millisecondsSinceEpoch}_${entry.key}',
        url: entry.value,
        title: 'Loading...',
      ).copyWith(position: entry.key);
    }).toList();

    return Session.create(
      name: sessionName ?? name,
      description: description,
      windowId: windowId,
      tabs: tabs,
    );
  }

  @override
  List<Object?> get props => [name, description, urls, category, icon, isDefault];
}

/// Predefined session templates
class SessionTemplates {
  static const List<SessionTemplate> defaults = [
    SessionTemplate(
      name: 'Development',
      description: 'Common development tools and resources',
      urls: [
        'https://github.com',
        'https://stackoverflow.com',
        'https://developer.mozilla.org',
        'https://pub.dev',
      ],
      category: 'Development',
      icon: '💻',
    ),
    SessionTemplate(
      name: 'Social Media',
      description: 'Popular social media platforms',
      urls: [
        'https://twitter.com',
        'https://facebook.com',
        'https://instagram.com',
        'https://linkedin.com',
      ],
      category: 'Social',
      icon: '📱',
    ),
    SessionTemplate(
      name: 'News & Information',
      description: 'Stay updated with latest news',
      urls: [
        'https://news.ycombinator.com',
        'https://reddit.com',
        'https://bbc.com/news',
        'https://techcrunch.com',
      ],
      category: 'News',
      icon: '📰',
    ),
    SessionTemplate(
      name: 'Productivity',
      description: 'Tools for getting work done',
      urls: [
        'https://gmail.com',
        'https://calendar.google.com',
        'https://drive.google.com',
        'https://notion.so',
      ],
      category: 'Productivity',
      icon: '⚡',
    ),
  ];

  /// Get template by name
  static SessionTemplate? getTemplate(String name) {
    try {
      return defaults.firstWhere((template) => template.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get templates by category
  static List<SessionTemplate> getTemplatesByCategory(String category) {
    return defaults.where((template) => template.category == category).toList();
  }

  /// Get all categories
  static Set<String> get categories {
    return defaults.map((template) => template.category).toSet();
  }
}
