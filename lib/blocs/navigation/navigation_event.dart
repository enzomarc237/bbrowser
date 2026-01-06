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
  });

  final String url;
  final String tabId;
  final String? title;

  @override
  List<Object?> get props => [url, tabId, title];
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
