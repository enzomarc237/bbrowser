import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../base/base_bloc.dart';
import '../communication/bloc_event_bus.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

/// BLoC for managing WebView navigation
class NavigationBloc extends BaseBloc<NavigationEvent, NavigationState> 
    with BlocCommunicationMixin<NavigationEvent, NavigationState> {
  
  // Navigation history per tab
  final Map<String, List<String>> _navigationHistory = {};
  final Map<String, int> _currentHistoryIndex = {};
  
  NavigationBloc() : super(const NavigationInitial()) {
    on<NavigationStarted>(_onNavigationStarted);
    on<NavigationCompleted>(_onNavigationCompleted);
    on<NavigationFailed>(_onNavigationFailed);
    on<NavigationBackRequested>(_onNavigationBackRequested);
    on<NavigationForwardRequested>(_onNavigationForwardRequested);
    on<NavigationReloadRequested>(_onNavigationReloadRequested);
    on<NavigationUrlChanged>(_onNavigationUrlChanged);
    on<NavigationTitleChanged>(_onNavigationTitleChanged);
    on<NavigationProgressChanged>(_onNavigationProgressChanged);
    on<NavigationHistoryCleared>(_onNavigationHistoryCleared);
    on<NavigationTabClosed>(_onNavigationTabClosed);
  }

  @override
  String get blocName => 'NavigationBloc';

  @override
  NavigationState buildErrorState({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    String? message,
  }) {
    final currentState = state;
    String tabId = '';
    String url = '';
    
    if (currentState is NavigationLoaded) {
      tabId = currentState.tabId;
      url = currentState.currentUrl;
    } else if (currentState is NavigationLoading) {
      tabId = currentState.tabId;
      url = currentState.url;
    }
    
    return NavigationError(
      message: message ?? getErrorMessage(error, context: context),
      url: url,
      tabId: tabId,
      error: error,
      stackTrace: stackTrace,
      context: context,
      isRecoverable: isRecoverableError(error),
    );
  }

  @override
  NavigationState buildLoadingState({
    String? operation,
    double? progress,
    String? message,
  }) {
    final currentState = state;
    
    if (currentState is NavigationLoaded) {
      return NavigationOperationInProgress(
        operation: operation ?? 'Loading',
        tabId: currentState.tabId,
        progress: progress,
        message: message,
      );
    }
    
    return NavigationOperationInProgress(
      operation: operation ?? 'Loading',
      tabId: '',
      progress: progress,
      message: message,
    );
  }

  /// Handles navigation start events
  Future<void> _onNavigationStarted(NavigationStarted event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        emit(NavigationLoading(
          url: event.url,
          tabId: event.tabId,
          progress: 0.0,
        ));
        
        // Publish global event for cross-BLoC communication
        publishGlobalEvent(NavigationStartedGlobalEvent(event.tabId, event.url));
      },
      emit: emit,
      context: 'starting navigation to ${event.url}',
    );
  }

  /// Handles navigation completion events
  Future<void> _onNavigationCompleted(NavigationCompleted event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        // Update navigation history
        _updateNavigationHistory(event.tabId, event.url);
        
        final canGoBack = _canGoBack(event.tabId);
        final canGoForward = _canGoForward(event.tabId);
        
        emit(NavigationLoaded(
          currentUrl: event.url,
          tabId: event.tabId,
          title: event.title,
          canGoBack: canGoBack,
          canGoForward: canGoForward,
          isSecure: event.url.startsWith('https://'),
          favicon: event.favicon,
        ));
        
        // Publish global event
        publishGlobalEvent(NavigationCompletedGlobalEvent(
          event.tabId, 
          event.url, 
          event.title,
        ));
      },
      emit: emit,
      context: 'completing navigation to ${event.url}',
    );
  }

  /// Handles navigation failure events
  Future<void> _onNavigationFailed(NavigationFailed event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        emit(NavigationError(
          message: event.error,
          url: event.url,
          tabId: event.tabId,
          isRecoverable: true,
        ));
        
        // Publish global event
        publishGlobalEvent(NavigationFailedGlobalEvent(
          event.tabId, 
          event.url, 
          event.error,
        ));
      },
      emit: emit,
      context: 'handling navigation failure for ${event.url}',
    );
  }

  /// Handles back navigation requests
  Future<void> _onNavigationBackRequested(NavigationBackRequested event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        if (_canGoBack(event.tabId)) {
          final previousUrl = _goBackInHistory(event.tabId);
          if (previousUrl != null) {
            emit(NavigationLoading(
              url: previousUrl,
              tabId: event.tabId,
              progress: 0.0,
            ));
            
            // Publish global event to trigger actual navigation
            publishGlobalEvent(NavigationBackRequestedGlobalEvent(event.tabId, previousUrl));
          }
        }
      },
      emit: emit,
      context: 'handling back navigation for tab ${event.tabId}',
    );
  }

  /// Handles forward navigation requests
  Future<void> _onNavigationForwardRequested(NavigationForwardRequested event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        if (_canGoForward(event.tabId)) {
          final nextUrl = _goForwardInHistory(event.tabId);
          if (nextUrl != null) {
            emit(NavigationLoading(
              url: nextUrl,
              tabId: event.tabId,
              progress: 0.0,
            ));
            
            // Publish global event to trigger actual navigation
            publishGlobalEvent(NavigationForwardRequestedGlobalEvent(event.tabId, nextUrl));
          }
        }
      },
      emit: emit,
      context: 'handling forward navigation for tab ${event.tabId}',
    );
  }

  /// Handles reload requests
  Future<void> _onNavigationReloadRequested(NavigationReloadRequested event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        final currentState = state;
        if (currentState is NavigationLoaded) {
          emit(NavigationLoading(
            url: currentState.currentUrl,
            tabId: event.tabId,
            progress: 0.0,
          ));
          
          // Publish global event to trigger actual reload
          publishGlobalEvent(NavigationReloadRequestedGlobalEvent(
            event.tabId, 
            currentState.currentUrl,
          ));
        }
      },
      emit: emit,
      context: 'handling reload for tab ${event.tabId}',
    );
  }

  /// Handles URL change events
  Future<void> _onNavigationUrlChanged(NavigationUrlChanged event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        final currentState = state;
        if (currentState is NavigationLoaded && currentState.tabId == event.tabId) {
          emit(currentState.copyWith(
            currentUrl: event.url,
            isSecure: event.url.startsWith('https://'),
          ));
        }
      },
      emit: emit,
      context: 'handling URL change for tab ${event.tabId}',
    );
  }

  /// Handles title change events
  Future<void> _onNavigationTitleChanged(NavigationTitleChanged event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        final currentState = state;
        if (currentState is NavigationLoaded && currentState.tabId == event.tabId) {
          emit(currentState.copyWith(title: event.title));
        }
      },
      emit: emit,
      context: 'handling title change for tab ${event.tabId}',
    );
  }

  /// Handles progress change events
  Future<void> _onNavigationProgressChanged(NavigationProgressChanged event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        final currentState = state;
        if (currentState is NavigationLoading && currentState.tabId == event.tabId) {
          emit(NavigationLoading(
            url: currentState.url,
            tabId: event.tabId,
            progress: event.progress,
          ));
        }
      },
      emit: emit,
      context: 'handling progress change for tab ${event.tabId}',
    );
  }

  /// Handles navigation history clearing
  Future<void> _onNavigationHistoryCleared(NavigationHistoryCleared event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        _navigationHistory[event.tabId]?.clear();
        _currentHistoryIndex[event.tabId] = -1;
        
        final currentState = state;
        if (currentState is NavigationLoaded && currentState.tabId == event.tabId) {
          emit(currentState.copyWith(
            canGoBack: false,
            canGoForward: false,
          ));
        }
      },
      emit: emit,
      context: 'clearing navigation history for tab ${event.tabId}',
    );
  }

  /// Handles tab closure
  Future<void> _onNavigationTabClosed(NavigationTabClosed event, Emitter<NavigationState> emit) async {
    await handleErrors(
      action: () async {
        // Clean up navigation history for the closed tab
        _navigationHistory.remove(event.tabId);
        _currentHistoryIndex.remove(event.tabId);
        
        // If this was the active tab, reset to initial state
        final currentState = state;
        if (currentState is NavigationLoaded && currentState.tabId == event.tabId) {
          emit(const NavigationInitial());
        }
      },
      emit: emit,
      context: 'handling tab closure for ${event.tabId}',
    );
  }

  /// Updates navigation history for a tab
  void _updateNavigationHistory(String tabId, String url) {
    _navigationHistory.putIfAbsent(tabId, () => []);
    _currentHistoryIndex.putIfAbsent(tabId, () => -1);
    
    final history = _navigationHistory[tabId]!;
    final currentIndex = _currentHistoryIndex[tabId]!;
    
    // Remove any forward history if we're navigating to a new URL
    if (currentIndex < history.length - 1) {
      history.removeRange(currentIndex + 1, history.length);
    }
    
    // Add new URL to history
    history.add(url);
    _currentHistoryIndex[tabId] = history.length - 1;
  }

  /// Checks if the tab can go back
  bool _canGoBack(String tabId) {
    final currentIndex = _currentHistoryIndex[tabId] ?? -1;
    return currentIndex > 0;
  }

  /// Checks if the tab can go forward
  bool _canGoForward(String tabId) {
    final history = _navigationHistory[tabId] ?? [];
    final currentIndex = _currentHistoryIndex[tabId] ?? -1;
    return currentIndex < history.length - 1;
  }

  /// Goes back in navigation history
  String? _goBackInHistory(String tabId) {
    if (_canGoBack(tabId)) {
      _currentHistoryIndex[tabId] = _currentHistoryIndex[tabId]! - 1;
      final history = _navigationHistory[tabId]!;
      return history[_currentHistoryIndex[tabId]!];
    }
    return null;
  }

  /// Goes forward in navigation history
  String? _goForwardInHistory(String tabId) {
    if (_canGoForward(tabId)) {
      _currentHistoryIndex[tabId] = _currentHistoryIndex[tabId]! + 1;
      final history = _navigationHistory[tabId]!;
      return history[_currentHistoryIndex[tabId]!];
    }
    return null;
  }

  /// Gets navigation history for a tab
  List<String> getNavigationHistory(String tabId) {
    return List<String>.from(_navigationHistory[tabId] ?? []);
  }

  /// Gets current history index for a tab
  int getCurrentHistoryIndex(String tabId) {
    return _currentHistoryIndex[tabId] ?? -1;
  }

  /// Checks if a tab can go back
  bool canGoBack(String tabId) => _canGoBack(tabId);

  /// Checks if a tab can go forward
  bool canGoForward(String tabId) => _canGoForward(tabId);

  @override
  Future<void> close() async {
    await disposeGlobalSubscriptions();
    return super.close();
  }
}

// Global events for cross-BLoC communication
class NavigationStartedGlobalEvent extends GlobalEvent {
  final String tabId;
  final String url;
  
  const NavigationStartedGlobalEvent(this.tabId, this.url);
  
  @override
  List<Object?> get props => [tabId, url];
}

class NavigationCompletedGlobalEvent extends GlobalEvent {
  final String tabId;
  final String url;
  final String? title;
  
  const NavigationCompletedGlobalEvent(this.tabId, this.url, this.title);
  
  @override
  List<Object?> get props => [tabId, url, title];
}

class NavigationFailedGlobalEvent extends GlobalEvent {
  final String tabId;
  final String url;
  final String error;
  
  const NavigationFailedGlobalEvent(this.tabId, this.url, this.error);
  
  @override
  List<Object?> get props => [tabId, url, error];
}

class NavigationBackRequestedGlobalEvent extends GlobalEvent {
  final String tabId;
  final String url;
  
  const NavigationBackRequestedGlobalEvent(this.tabId, this.url);
  
  @override
  List<Object?> get props => [tabId, url];
}

class NavigationForwardRequestedGlobalEvent extends GlobalEvent {
  final String tabId;
  final String url;
  
  const NavigationForwardRequestedGlobalEvent(this.tabId, this.url);
  
  @override
  List<Object?> get props => [tabId, url];
}

class NavigationReloadRequestedGlobalEvent extends GlobalEvent {
  final String tabId;
  final String url;
  
  const NavigationReloadRequestedGlobalEvent(this.tabId, this.url);
  
  @override
  List<Object?> get props => [tabId, url];
}
