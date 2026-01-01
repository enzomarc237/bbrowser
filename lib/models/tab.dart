import 'package:equatable/equatable.dart';

/// Sentinel object for copyWith methods to distinguish between null and not provided
const Object _sentinel = Object();

/// Represents a browser tab with its state and metadata
class Tab extends Equatable {
  const Tab({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    this.isLoading = false,
    this.canGoBack = false,
    this.canGoForward = false,
    this.loadingProgress = 0.0,
    this.isSecure = false,
    this.hasError = false,
    this.errorMessage,
    this.createdAt,
    this.lastAccessedAt,
  });

  /// Unique identifier for the tab
  final String id;

  /// Title of the current page
  final String title;

  /// Current URL of the tab
  final String url;

  /// Favicon URL for the current page
  final String? favicon;

  /// Whether the page is currently loading
  final bool isLoading;

  /// Whether the tab can navigate back
  final bool canGoBack;

  /// Whether the tab can navigate forward
  final bool canGoForward;

  /// Loading progress from 0.0 to 1.0
  final double loadingProgress;

  /// Whether the current page is served over HTTPS
  final bool isSecure;

  /// Whether there's an error with the current page
  final bool hasError;

  /// Error message if there's an error
  final String? errorMessage;

  /// When the tab was created
  final DateTime? createdAt;

  /// When the tab was last accessed
  final DateTime? lastAccessedAt;

  /// Creates a copy of this tab with updated values
  Tab copyWith({
    String? id,
    String? title,
    String? url,
    Object? favicon = _sentinel,
    bool? isLoading,
    bool? canGoBack,
    bool? canGoForward,
    double? loadingProgress,
    bool? isSecure,
    bool? hasError,
    Object? errorMessage = _sentinel,
    Object? createdAt = _sentinel,
    Object? lastAccessedAt = _sentinel,
  }) {
    return Tab(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      favicon: favicon == _sentinel ? this.favicon : favicon as String?,
      isLoading: isLoading ?? this.isLoading,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      isSecure: isSecure ?? this.isSecure,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      createdAt: createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      lastAccessedAt: lastAccessedAt == _sentinel ? this.lastAccessedAt : lastAccessedAt as DateTime?,
    );
  }

  /// Creates a new tab with default values
  factory Tab.newTab({
    String? id,
    String url = 'about:blank',
    String title = 'New Tab',
  }) {
    final now = DateTime.now();
    return Tab(
      id: id ?? 'tab_${now.millisecondsSinceEpoch}',
      title: title,
      url: url,
      createdAt: now,
      lastAccessedAt: now,
    );
  }

  /// Creates a tab from JSON data
  factory Tab.fromJson(Map<String, dynamic> json) {
    return Tab(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      favicon: json['favicon'] as String?,
      isLoading: json['isLoading'] as bool? ?? false,
      canGoBack: json['canGoBack'] as bool? ?? false,
      canGoForward: json['canGoForward'] as bool? ?? false,
      loadingProgress: (json['loadingProgress'] as num?)?.toDouble() ?? 0.0,
      isSecure: json['isSecure'] as bool? ?? false,
      hasError: json['hasError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.tryParse(json['lastAccessedAt'] as String)
          : null,
    );
  }

  /// Converts the tab to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'isLoading': isLoading,
      'canGoBack': canGoBack,
      'canGoForward': canGoForward,
      'loadingProgress': loadingProgress,
      'isSecure': isSecure,
      'hasError': hasError,
      'errorMessage': errorMessage,
      'createdAt': createdAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        favicon,
        isLoading,
        canGoBack,
        canGoForward,
        loadingProgress,
        isSecure,
        hasError,
        errorMessage,
        createdAt,
        lastAccessedAt,
      ];

  @override
  String toString() {
    return 'Tab(id: $id, title: $title, url: $url, isLoading: $isLoading)';
  }
}
