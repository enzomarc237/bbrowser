import '../base/base_state.dart';

/// Base class for all navigation states
abstract class NavigationState extends BaseState {
  const NavigationState();
}

/// Initial navigation state
class NavigationInitial extends NavigationState {
  const NavigationInitial();

  @override
  bool get isInitial => true;
}

/// Navigation loading state
class NavigationLoading extends NavigationState {
  const NavigationLoading({
    required this.url,
    required this.tabId,
    this.progress,
  });

  final String url;
  final String tabId;
  final double? progress;

  @override
  bool get isLoading => true;

  @override
  List<Object?> get props => [url, tabId, progress];
}

/// Navigation loaded state
class NavigationLoaded extends NavigationState {
  const NavigationLoaded({
    required this.currentUrl,
    required this.tabId,
    this.title,
    this.canGoBack = false,
    this.canGoForward = false,
    this.isSecure = false,
    this.favicon,
  });

  final String currentUrl;
  final String tabId;
  final String? title;
  final bool canGoBack;
  final bool canGoForward;
  final bool isSecure;
  final String? favicon;

  @override
  bool get isSuccess => true;

  /// Create a copy with updated values
  NavigationLoaded copyWith({
    String? currentUrl,
    String? tabId,
    String? title,
    bool? canGoBack,
    bool? canGoForward,
    bool? isSecure,
    String? favicon,
  }) {
    return NavigationLoaded(
      currentUrl: currentUrl ?? this.currentUrl,
      tabId: tabId ?? this.tabId,
      title: title ?? this.title,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isSecure: isSecure ?? this.isSecure,
      favicon: favicon ?? this.favicon,
    );
  }

  @override
  List<Object?> get props => [
        currentUrl,
        tabId,
        title,
        canGoBack,
        canGoForward,
        isSecure,
        favicon,
      ];

  @override
  String toString() {
    return 'NavigationLoaded(url: $currentUrl, tabId: $tabId, title: $title, canGoBack: $canGoBack, canGoForward: $canGoForward)';
  }
}

/// Navigation error state
class NavigationError extends NavigationState {
  const NavigationError({
    required this.message,
    required this.url,
    required this.tabId,
    this.error,
    this.stackTrace,
    this.context,
    this.isRecoverable = true,
  });

  final String message;
  final String url;
  final String tabId;
  final Object? error;
  final StackTrace? stackTrace;
  final String? context;
  final bool isRecoverable;

  @override
  bool get hasError => true;

  @override
  List<Object?> get props => [
        message,
        url,
        tabId,
        error,
        stackTrace,
        context,
        isRecoverable,
      ];

  @override
  String toString() {
    return 'NavigationError(message: $message, url: $url, tabId: $tabId, recoverable: $isRecoverable)';
  }
}

/// Navigation operation in progress state
class NavigationOperationInProgress extends NavigationState {
  const NavigationOperationInProgress({
    required this.operation,
    required this.tabId,
    this.progress,
    this.message,
    this.canCancel = false,
  });

  final String operation;
  final String tabId;
  final double? progress;
  final String? message;
  final bool canCancel;

  @override
  bool get isLoading => true;

  @override
  List<Object?> get props => [operation, tabId, progress, message, canCancel];

  @override
  String toString() {
    return 'NavigationOperationInProgress(operation: $operation, tabId: $tabId, progress: $progress, canCancel: $canCancel)';
  }
}
