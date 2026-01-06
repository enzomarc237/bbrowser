import '../base/base_event.dart';

/// Base class for all navigation events
abstract class NavigationEvent extends BaseEvent {
  const NavigationEvent();
}

/// Event to navigate to a URL
class NavigateToUrl extends NavigationEvent {
  const NavigateToUrl({
    required this.url,
    this.tabId,
    this.newTab = false,
  });

  final String url;
  final String? tabId;
  final bool newTab;

  @override
  List<Object?> get props => [url, tabId, newTab];
}

/// Event to navigate back
class NavigateBack extends NavigationEvent {
  const NavigateBack({this.tabId});

  final String? tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event to navigate forward
class NavigateForward extends NavigationEvent {
  const NavigateForward({this.tabId});

  final String? tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event to reload current page
class ReloadPage extends NavigationEvent {
  const ReloadPage({this.tabId});

  final String? tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event to stop loading
class StopLoading extends NavigationEvent {
  const StopLoading({this.tabId});

  final String? tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event when navigation starts
class NavigationStarted extends NavigationEvent {
  const NavigationStarted({
    required this.url,
    required this.tabId,
  });

  final String url;
  final String tabId;

  @override
  List<Object?> get props => [url, tabId];
}

/// Event when navigation completes
class NavigationCompleted extends NavigationEvent {
  const NavigationCompleted({
    required this.url,
    required this.tabId,
    this.title,
    this.favicon,
  });

  final String url;
  final String tabId;
  final String? title;
  final String? favicon;

  @override
  List<Object?> get props => [url, tabId, title, favicon];
}

/// Event when navigation fails
class NavigationFailed extends NavigationEvent {
  const NavigationFailed({
    required this.url,
    required this.tabId,
    required this.error,
  });

  final String url;
  final String tabId;
  final String error;

  @override
  List<Object?> get props => [url, tabId, error];
}

/// Event to update navigation state
class NavigationStateUpdated extends NavigationEvent {
  const NavigationStateUpdated({
    required this.tabId,
    this.canGoBack,
    this.canGoForward,
    this.isLoading,
    this.progress,
  });

  final String tabId;
  final bool? canGoBack;
  final bool? canGoForward;
  final bool? isLoading;
  final double? progress;

  @override
  List<Object?> get props => [tabId, canGoBack, canGoForward, isLoading, progress];
}

/// Event triggered when back navigation is requested
class NavigationBackRequested extends NavigationEvent {
  const NavigationBackRequested({
    required this.tabId,
  });

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event triggered when forward navigation is requested
class NavigationForwardRequested extends NavigationEvent {
  const NavigationForwardRequested({
    required this.tabId,
  });

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event triggered when reload is requested
class NavigationReloadRequested extends NavigationEvent {
  const NavigationReloadRequested({
    required this.tabId,
  });

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event triggered when URL changes
class NavigationUrlChanged extends NavigationEvent {
  const NavigationUrlChanged({
    required this.tabId,
    required this.url,
  });

  final String tabId;
  final String url;

  @override
  List<Object?> get props => [tabId, url];
}

/// Event triggered when title changes
class NavigationTitleChanged extends NavigationEvent {
  const NavigationTitleChanged({
    required this.tabId,
    required this.title,
  });

  final String tabId;
  final String title;

  @override
  List<Object?> get props => [tabId, title];
}

/// Event triggered when progress changes
class NavigationProgressChanged extends NavigationEvent {
  const NavigationProgressChanged({
    required this.tabId,
    required this.progress,
  });

  final String tabId;
  final double progress;

  @override
  List<Object?> get props => [tabId, progress];
}

/// Event triggered when navigation history is cleared
class NavigationHistoryCleared extends NavigationEvent {
  const NavigationHistoryCleared({
    required this.tabId,
  });

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event triggered when a tab is closed
class NavigationTabClosed extends NavigationEvent {
  const NavigationTabClosed({
    required this.tabId,
  });

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}
