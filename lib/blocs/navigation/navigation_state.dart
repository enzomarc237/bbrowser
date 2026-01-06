import '../base/base_state.dart';

/// Sentinel object for copyWith methods to distinguish between null and not provided
const Object _sentinel = Object();

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
  /// 
  /// Use the sentinel pattern to distinguish between null and not provided:
  /// - `copyWith(title: null)` sets title to null
  /// - `copyWith()` preserves the current title
  NavigationLoaded copyWith({
    Object? currentUrl = _sentinel,
    Object? tabId = _sentinel,
    Object? title = _sentinel,
    Object? canGoBack = _sentinel,
    Object? canGoForward = _sentinel,
    Object? isSecure = _sentinel,
    Object? favicon = _sentinel,
  }) {
    return NavigationLoaded(
      currentUrl: currentUrl == _sentinel ? this.currentUrl : currentUrl as String?,
      tabId: tabId == _sentinel ? this.tabId : tabId as String?,
      title: title == _sentinel ? this.title : title as String?,
      canGoBack: canGoBack == _sentinel ? this.canGoBack : canGoBack as bool?,
      canGoForward: canGoForward == _sentinel ? this.canGoForward : canGoForward as bool?,
      isSecure: isSecure == _sentinel ? this.isSecure : isSecure as bool?,
      favicon: favicon == _sentinel ? this.favicon : favicon as String?,
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
