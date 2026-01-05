import '../../models/tab.dart';
import '../base/base_event.dart';

/// Base class for all tab events
abstract class TabEvent extends BaseEvent {
  const TabEvent();
}

/// Event to create a new tab
class TabCreated extends TabEvent {
  const TabCreated({
    this.url = 'about:blank',
    this.title = 'New Tab',
    this.makeActive = true,
  });

  final String url;
  final String title;
  final bool makeActive;

  @override
  List<Object?> get props => [url, title, makeActive];
}

/// Event to select/activate a tab
class TabSelected extends TabEvent {
  const TabSelected(this.tabId);

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event to close a tab
class TabClosed extends TabEvent {
  const TabClosed(this.tabId);

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

/// Event to update tab information
class TabUpdated extends TabEvent {
  const TabUpdated({
    required this.tabId,
    this.title,
    this.url,
    this.favicon,
    this.isLoading,
    this.canGoBack,
    this.canGoForward,
    this.loadingProgress,
    this.isSecure,
    this.hasError,
    this.errorMessage,
  });

  final String tabId;
  final String? title;
  final String? url;
  final String? favicon;
  final bool? isLoading;
  final bool? canGoBack;
  final bool? canGoForward;
  final double? loadingProgress;
  final bool? isSecure;
  final bool? hasError;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        tabId,
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
      ];
}

/// Event to reorder tabs
class TabsReordered extends TabEvent {
  const TabsReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Event to navigate to a URL in the active tab
class TabNavigateToUrl extends TabEvent {
  const TabNavigateToUrl(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}

/// Event to navigate back in the active tab
class TabNavigateBack extends TabEvent {
  const TabNavigateBack();
}

/// Event to navigate forward in the active tab
class TabNavigateForward extends TabEvent {
  const TabNavigateForward();
}

/// Event to reload the active tab
class TabReload extends TabEvent {
  const TabReload();
}

/// Event to restore tabs from saved session
class TabsRestored extends TabEvent {
  const TabsRestored(this.tabs);

  final List<Tab> tabs;

  @override
  List<Object?> get props => [tabs];
}

/// Event to save current tab session
class TabSessionSaved extends TabEvent {
  const TabSessionSaved();
}

/// Event to clear all tabs
class TabsCleared extends TabEvent {
  const TabsCleared();
}

/// Event to duplicate a tab
class TabDuplicated extends TabEvent {
  const TabDuplicated(this.tabId);

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}
