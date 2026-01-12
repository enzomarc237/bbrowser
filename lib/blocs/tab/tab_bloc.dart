import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/tab.dart';
import '../base/base_bloc.dart';
import '../communication/bloc_event_bus.dart';
import 'tab_event.dart';
import 'tab_state.dart';

abstract class NavigationCommand {
  const NavigationCommand(this.tabId);
  final String tabId;
}

class NavigateBackCommand extends NavigationCommand {
  const NavigateBackCommand(String tabId) : super(tabId);
}

class NavigateForwardCommand extends NavigationCommand {
  const NavigateForwardCommand(String tabId) : super(tabId);
}

class ReloadCommand extends NavigationCommand {
  const ReloadCommand(String tabId) : super(tabId);
}

class LoadUrlCommand extends NavigationCommand {
  const LoadUrlCommand(String tabId, this.url) : super(tabId);
  final String url;
}

/// BLoC for managing browser tabs
class TabBloc extends BaseBloc<TabEvent, TabState> 
    with BlocCommunicationMixin<TabEvent, TabState> {
  String? _previousActiveTabId;

  final _navigationCommandController = StreamController<NavigationCommand>.broadcast();
  Stream<NavigationCommand> get navigationCommands => _navigationCommandController.stream;

  TabBloc() : super(const TabInitial()) {
    on<TabCreated>(_onTabCreated);
    on<TabSelected>(_onTabSelected);
    on<TabClosed>(_onTabClosed);
    on<TabUpdated>(_onTabUpdated);
    on<TabsReordered>(_onTabsReordered);
    on<TabNavigateToUrl>(_onTabNavigateToUrl);
    on<TabNavigateBack>(_onTabNavigateBack);
    on<TabNavigateForward>(_onTabNavigateForward);
    on<TabReload>(_onTabReload);
    on<TabsRestored>(_onTabsRestored);
    on<TabSessionSaved>(_onTabSessionSaved);
    on<TabsCleared>(_onTabsCleared);
    on<TabDuplicated>(_onTabDuplicated);
    on<TabUrlUpdated>(_onTabUrlUpdated);
    on<TabTitleUpdated>(_onTabTitleUpdated);
  }

  @override
  String get blocName => 'TabBloc';

  @override
  TabState buildErrorState({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    String? message,
  }) {
    final currentState = state;
    return TabError(
      message: message ?? getErrorMessage(error, context: context),
      tabs: currentState is TabLoaded ? currentState.tabs : [],
      activeTabId: currentState is TabLoaded ? currentState.activeTabId : null,
      error: error,
      stackTrace: stackTrace,
      context: context,
      isRecoverable: isRecoverableError(error),
    );
  }

  @override
  TabState buildLoadingState({
    String? operation,
    double? progress,
    String? message,
  }) {
    final currentState = state;
    if (currentState is TabLoaded) {
      return TabOperationInProgress(
        operation: operation ?? 'Processing',
        tabs: currentState.tabs,
        activeTabId: currentState.activeTabId,
        progress: progress,
        message: message,
      );
    }
    return const TabLoading();
  }

  @override
  void onStateChanged(TabState state) {
    super.onStateChanged(state);
    
    // Publish global events for cross-BLoC communication only when active tab changes
    if (state is TabLoaded) {
      final currentActiveTabId = state.activeTabId;
      if (currentActiveTabId != _previousActiveTabId) {
        _previousActiveTabId = currentActiveTabId;
        if (currentActiveTabId != null) {
          publishGlobalEvent(TabSelectedGlobalEvent(currentActiveTabId));
        }
      }
    }
  }

  @override
  Future<void> close() async {
    _navigationCommandController.close();
    await disposeGlobalSubscriptions();
    return super.close();
  }

  /// Handles creating a new tab
  Future<void> _onTabCreated(TabCreated event, Emitter<TabState> emit) async {
    await handleErrors(
      action: () async {
        final currentState = state;
        
        // Create new tab
        final newTab = Tab.newTab(
          url: event.url,
          title: event.title,
        );

        if (currentState is TabLoaded) {
          // Add to existing tabs
          emit(currentState.withAddedTab(newTab, makeActive: event.makeActive));
        } else {
          // First tab
          emit(TabLoaded(
            tabs: [newTab],
            activeTabId: event.makeActive ? newTab.id : null,
          ));
        }
      },
      emit: emit,
      context: 'creating new tab',
    );
  }

  /// Handles selecting a tab
  Future<void> _onTabSelected(TabSelected event, Emitter<TabState> emit) async {
    try {
      final currentState = state;
      
      if (currentState is TabLoaded) {
        if (currentState.hasTab(event.tabId)) {
          // Update last accessed time
          final tab = currentState.getTab(event.tabId);
          if (tab != null) {
            final updatedTab = tab.copyWith(lastAccessedAt: DateTime.now());
            final updatedState = currentState
                .withUpdatedTab(event.tabId, updatedTab)
                .withActiveTab(event.tabId);
            emit(updatedState);
          } else {
            emit(currentState.withActiveTab(event.tabId));
          }
        } else {
          emit(TabError(
            message: 'Tab not found: ${event.tabId}',
            tabs: currentState.tabs,
            activeTabId: currentState.activeTabId,
          ));
        }
      } else {
        emit(const TabError(message: 'No tabs available to select'));
      }
    } catch (e) {
      emit(TabError(
        message: 'Failed to select tab: ${e.toString()}',
        tabs: state is TabLoaded ? (state as TabLoaded).tabs : [],
        activeTabId: state is TabLoaded ? (state as TabLoaded).activeTabId : null,
      ));
    }
  }

  /// Handles closing a tab
  Future<void> _onTabClosed(TabClosed event, Emitter<TabState> emit) async {
    await handleErrors(
      action: () async {
        final currentState = state;
        
        if (currentState is TabLoaded) {
          if (currentState.hasTab(event.tabId)) {
            // Publish global event before closing
            publishGlobalEvent(TabClosedGlobalEvent(event.tabId));
            
            final newState = currentState.withRemovedTab(event.tabId);
            
            // If no tabs left, go to initial state
            if (newState.tabs.isEmpty) {
              emit(const TabInitial());
            } else {
              emit(newState);
            }
          } else {
            throw StateError('Tab not found: ${event.tabId}');
          }
        } else {
          throw StateError('No tabs available to close');
        }
      },
      emit: emit,
      context: 'closing tab ${event.tabId}',
    );
  }

  /// Handles updating tab information
  Future<void> _onTabUpdated(TabUpdated event, Emitter<TabState> emit) async {
    try {
      final currentState = state;
      
      if (currentState is TabLoaded) {
        final tab = currentState.getTab(event.tabId);
        if (tab != null) {
          final updatedTab = tab.copyWith(
            title: event.title,
            url: event.url,
            favicon: event.favicon,
            isLoading: event.isLoading,
            canGoBack: event.canGoBack,
            canGoForward: event.canGoForward,
            loadingProgress: event.loadingProgress,
            isSecure: event.isSecure,
            hasError: event.hasError,
            errorMessage: event.errorMessage,
            lastAccessedAt: DateTime.now(),
          );
          
          emit(currentState.withUpdatedTab(event.tabId, updatedTab));
        } else {
          emit(TabError(
            message: 'Tab not found: ${event.tabId}',
            tabs: currentState.tabs,
            activeTabId: currentState.activeTabId,
          ));
        }
      } else {
        emit(const TabError(message: 'No tabs available to update'));
      }
    } catch (e) {
      emit(TabError(
        message: 'Failed to update tab: ${e.toString()}',
        tabs: state is TabLoaded ? (state as TabLoaded).tabs : [],
        activeTabId: state is TabLoaded ? (state as TabLoaded).activeTabId : null,
      ));
    }
  }

  /// Handles reordering tabs
  Future<void> _onTabsReordered(TabsReordered event, Emitter<TabState> emit) async {
    try {
      final currentState = state;
      
      if (currentState is TabLoaded) {
        if (event.oldIndex >= 0 && 
            event.oldIndex < currentState.tabs.length &&
            event.newIndex >= 0 && 
            event.newIndex < currentState.tabs.length) {
          emit(currentState.withReorderedTabs(event.oldIndex, event.newIndex));
        } else {
          emit(TabError(
            message: 'Invalid tab indices for reordering',
            tabs: currentState.tabs,
            activeTabId: currentState.activeTabId,
          ));
        }
      } else {
        emit(const TabError(message: 'No tabs available to reorder'));
      }
    } catch (e) {
      emit(TabError(
        message: 'Failed to reorder tabs: ${e.toString()}',
        tabs: state is TabLoaded ? (state as TabLoaded).tabs : [],
        activeTabId: state is TabLoaded ? (state as TabLoaded).activeTabId : null,
      ));
    }
  }

  /// Handles navigation to URL in active tab
  Future<void> _onTabNavigateToUrl(TabNavigateToUrl event, Emitter<TabState> emit) async {
    final currentState = state;
    if (currentState is TabLoaded && currentState.activeTabId != null) {
      _navigationCommandController.add(LoadUrlCommand(currentState.activeTabId!, event.url));
    }
  }

  /// Handles navigation back in active tab
  Future<void> _onTabNavigateBack(TabNavigateBack event, Emitter<TabState> emit) async {
    final currentState = state;
    if (currentState is TabLoaded && currentState.activeTab != null) {
      if (currentState.activeTab!.canGoBack) {
        _navigationCommandController.add(NavigateBackCommand(currentState.activeTabId!));
      }
    }
  }

  /// Handles navigation forward in active tab
  Future<void> _onTabNavigateForward(TabNavigateForward event, Emitter<TabState> emit) async {
    final currentState = state;
    if (currentState is TabLoaded && currentState.activeTab != null) {
      if (currentState.activeTab!.canGoForward) {
        _navigationCommandController.add(NavigateForwardCommand(currentState.activeTabId!));
      }
    }
  }

  /// Handles reloading the active tab
  Future<void> _onTabReload(TabReload event, Emitter<TabState> emit) async {
    final currentState = state;
    if (currentState is TabLoaded && currentState.activeTabId != null) {
      _navigationCommandController.add(ReloadCommand(currentState.activeTabId!));
    }
  }

  /// Handles restoring tabs from saved session
  Future<void> _onTabsRestored(TabsRestored event, Emitter<TabState> emit) async {
    try {
      if (event.tabs.isNotEmpty) {
        emit(TabLoaded(
          tabs: event.tabs,
          activeTabId: event.tabs.first.id,
          isSessionRestored: true,
        ));
      } else {
        emit(const TabInitial());
      }
    } catch (e) {
      emit(TabError(message: 'Failed to restore tabs: ${e.toString()}'));
    }
  }

  /// Handles saving current tab session
  Future<void> _onTabSessionSaved(TabSessionSaved event, Emitter<TabState> emit) async {
    try {
      // This would typically save to persistent storage
      // For now, we just emit the current state
      // Implementation would involve calling a repository or service
      throw UnimplementedError('Session saving not yet implemented');
    } catch (e) {
      emit(TabError(
        message: 'Failed to save session: ${e.toString()}',
        tabs: state is TabLoaded ? (state as TabLoaded).tabs : [],
        activeTabId: state is TabLoaded ? (state as TabLoaded).activeTabId : null,
      ));
    }
  }

  /// Handles clearing all tabs
  Future<void> _onTabsCleared(TabsCleared event, Emitter<TabState> emit) async {
    try {
      emit(const TabInitial());
    } catch (e) {
      emit(TabError(message: 'Failed to clear tabs: ${e.toString()}'));
    }
  }

  /// Handles duplicating a tab
  Future<void> _onTabDuplicated(TabDuplicated event, Emitter<TabState> emit) async {
    try {
      final currentState = state;
      
      if (currentState is TabLoaded) {
        final originalTab = currentState.getTab(event.tabId);
        if (originalTab != null) {
          final duplicatedTab = Tab.newTab(
            url: originalTab.url,
            title: originalTab.title,
          );
          
          emit(currentState.withAddedTab(duplicatedTab, makeActive: true));
        } else {
          emit(TabError(
            message: 'Tab not found: ${event.tabId}',
            tabs: currentState.tabs,
            activeTabId: currentState.activeTabId,
          ));
        }
      } else {
        emit(const TabError(message: 'No tabs available to duplicate'));
      }
    } catch (e) {
      emit(TabError(
        message: 'Failed to duplicate tab: ${e.toString()}',
        tabs: state is TabLoaded ? (state as TabLoaded).tabs : [],
        activeTabId: state is TabLoaded ? (state as TabLoaded).activeTabId : null,
      ));
    }
  }

  /// Handles updating tab URL
  Future<void> _onTabUrlUpdated(TabUrlUpdated event, Emitter<TabState> emit) async {
    final currentState = state;
    if (currentState is TabLoaded) {
      final tab = currentState.getTab(event.tabId);
      if (tab != null && tab.url != event.url) {
        final updatedTab = tab.copyWith(url: event.url);
        emit(currentState.withUpdatedTab(event.tabId, updatedTab));
      }
    }
  }

  /// Handles updating tab title
  Future<void> _onTabTitleUpdated(TabTitleUpdated event, Emitter<TabState> emit) async {
    final currentState = state;
    if (currentState is TabLoaded) {
      final tab = currentState.getTab(event.tabId);
      if (tab != null && tab.title != event.title) {
        final updatedTab = tab.copyWith(title: event.title);
        emit(currentState.withUpdatedTab(event.tabId, updatedTab));
      }
    }
  }
}
