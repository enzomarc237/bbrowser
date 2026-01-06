import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_event.dart';
import 'base_state.dart';
import 'bloc_lifecycle_mixin.dart';
import 'error_handler_mixin.dart';

/// Abstract base class for all BLoCs in the application
/// 
/// This class provides common functionality and ensures consistent
/// patterns across all BLoCs. It includes error handling, lifecycle
/// management, and performance optimization features.
/// 
/// Example:
/// ```dart
/// class MyBloc extends BaseBloc<MyEvent, MyState> {
///   MyBloc() : super(MyInitialState()) {
///     on<MyEvent>(_onMyEvent);
///   }
///   
///   Future<void> _onMyEvent(MyEvent event, Emitter<MyState> emit) async {
///     await handleErrors(
///       action: () => _performOperation(event),
///       emit: emit,
///       context: 'handling MyEvent',
///       errorStateBuilder: (error, stackTrace, context) => MyErrorState(
///         error: error,
///         message: getErrorMessage(error, context: context),
///         context: context,
///       ),
///     );
///   }
/// }
/// ```
abstract class BaseBloc<Event extends BaseEvent, State extends BaseState>
    extends Bloc<Event, State>
    with BlocLifecycleMixin<Event, State>, ErrorHandlerMixin<Event, State> {
  
  BaseBloc(State initialState) : super(initialState) {
    // Set up common event transformers and error handling
    _setupCommonBehavior();
  }

  /// The name of this BLoC for logging and debugging
  String get blocName => runtimeType.toString();

  /// Whether this BLoC supports undo/redo functionality
  bool get supportsUndo => false;

  /// Whether this BLoC supports persistence
  bool get supportsPersistence => false;

  /// Set up common behavior for all BLoCs
  void _setupCommonBehavior() {
    // Add global error handling
    stream.listen(
      (state) => _onStateChanged(state),
      onError: (error, stackTrace) => _onGlobalError(error, stackTrace),
    );
  }

  /// Called whenever the state changes
  /// 
  /// Override this method to implement custom state change handling,
  /// such as logging, analytics, or persistence.
  void _onStateChanged(State state) {
    // Log state changes in debug mode
    if (_isDebugMode) {
      print('[$blocName] State changed to: ${state.runtimeType}');
    }
    
    // Call custom state change handler
    onStateChanged(state);
  }

  /// Called when a global error occurs
  /// 
  /// This handles errors that aren't caught by individual event handlers.
  void _onGlobalError(Object error, StackTrace stackTrace) {
    print('[$blocName] Global error: $error');
    print('Stack trace: $stackTrace');
    
    // Call custom error handler
    onGlobalError(error, stackTrace);
  }

  /// Override this method to handle state changes
  /// 
  /// This is called after every state change and can be used for
  /// logging, analytics, persistence, or other side effects.
  void onStateChanged(State state) {
    // Default implementation does nothing
    // Override in concrete BLoCs as needed
  }

  /// Override this method to handle global errors
  /// 
  /// This is called when an error occurs outside of event handlers.
  void onGlobalError(Object error, StackTrace stackTrace) {
    // Default implementation does nothing
    // Override in concrete BLoCs as needed
  }

  /// Build an error state for this BLoC
  /// 
  /// This method must be implemented by concrete BLoCs to provide
  /// domain-specific error states.
  State buildErrorState({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    String? message,
  });

  /// Build a loading state for this BLoC
  /// 
  /// This method should be implemented by concrete BLoCs to provide
  /// domain-specific loading states.
  State buildLoadingState({
    String? operation,
    double? progress,
    String? message,
  });

  /// Override the default error state builder
  @override
  State _buildDefaultErrorState(Object error, StackTrace? stackTrace, String? context) {
    return buildErrorState(
      error: error,
      stackTrace: stackTrace,
      context: context,
      message: getErrorMessage(error, context: context),
    );
  }

  /// Handle an event with automatic error handling and loading states
  /// 
  /// This is a convenience method that combines error handling with
  /// loading state management for common async operations.
  Future<void> handleEventWithLoading<T extends Event>({
    required T event,
    required Emitter<State> emit,
    required Future<void> Function(T event, Emitter<State> emit) handler,
    String? operation,
    String? context,
  }) async {
    final loadingState = buildLoadingState(
      operation: operation ?? 'Processing ${event.runtimeType}',
    );

    await handleErrorsWithLoading(
      action: () => handler(event, emit),
      emit: emit,
      loadingState: loadingState,
      context: context ?? 'handling ${event.runtimeType}',
      errorStateBuilder: (error, stackTrace, context) => buildErrorState(
        error: error,
        stackTrace: stackTrace,
        context: context,
        message: getErrorMessage(error, context: context),
      ),
    );
  }

  /// Emit a state with automatic logging and validation
  /// 
  /// This method provides additional safety and debugging capabilities
  /// when emitting states.
  void safeEmit(Emitter<State> emit, State state) {
    try {
      // Validate state before emitting
      if (_validateState(state)) {
        emit(state);
      } else {
        print('[$blocName] Invalid state rejected: $state');
      }
    } catch (error, stackTrace) {
      print('[$blocName] Error emitting state: $error');
      print('Stack trace: $stackTrace');
      
      // Emit error state instead
      final errorState = buildErrorState(
        error: error,
        stackTrace: stackTrace,
        context: 'emitting state',
      );
      emit(errorState);
    }
  }

  /// Validate a state before emitting
  /// 
  /// Override this method to implement custom state validation logic.
  bool _validateState(State state) {
    // Basic validation - ensure state is not null
    if (state == null) return false;
    
    // Call custom validation
    return validateState(state);
  }

  /// Override this method to implement custom state validation
  /// 
  /// Return true if the state is valid, false otherwise.
  bool validateState(State state) {
    return true; // Default implementation accepts all states
  }

  /// Get debug information about this BLoC
  Map<String, dynamic> getDebugInfo() {
    return {
      'blocName': blocName,
      'currentState': state.runtimeType.toString(),
      'isClosed': isClosed,
      'supportsUndo': supportsUndo,
      'supportsPersistence': supportsPersistence,
      'activeSubscriptions': activeSubscriptionsCount,
      'activeTimers': activeTimersCount,
      'disposables': disposablesCount,
      'hasActiveResources': hasActiveResources,
    };
  }

  /// Check if we're in debug mode
  bool get _isDebugMode {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }

  @override
  String toString() {
    return '$blocName(state: ${state.runtimeType})';
  }
}

/// Abstract base class for BLoCs that support undo/redo functionality
/// 
/// This class extends BaseBloc with undo/redo capabilities, maintaining
/// a history of states that can be navigated.
/// 
/// Example:
/// ```dart
/// class MyUndoableBloc extends UndoableBaseBloc<MyEvent, MyState> {
///   MyUndoableBloc() : super(MyInitialState(), maxHistorySize: 50);
///   
///   @override
///   bool shouldSaveToHistory(MyState state) {
///     // Only save non-loading states to history
///     return !state.isLoading;
///   }
/// }
/// ```
abstract class UndoableBaseBloc<Event extends BaseEvent, State extends BaseState>
    extends BaseBloc<Event, State> {
  
  final List<State> _stateHistory = [];
  final int maxHistorySize;
  int _currentHistoryIndex = -1;

  UndoableBaseBloc(State initialState, {this.maxHistorySize = 20}) 
      : super(initialState) {
    // Save initial state to history
    _saveToHistory(initialState);
  }

  @override
  bool get supportsUndo => true;

  /// Whether undo is available
  bool get canUndo => _currentHistoryIndex > 0;

  /// Whether redo is available
  bool get canRedo => _currentHistoryIndex < _stateHistory.length - 1;

  /// Get the number of states in history
  int get historySize => _stateHistory.length;

  /// Get the current position in history
  int get currentHistoryIndex => _currentHistoryIndex;

  /// Undo to the previous state
  void undo(Emitter<State> emit) {
    if (canUndo) {
      _currentHistoryIndex--;
      emit(_stateHistory[_currentHistoryIndex]);
    }
  }

  /// Redo to the next state
  void redo(Emitter<State> emit) {
    if (canRedo) {
      _currentHistoryIndex++;
      emit(_stateHistory[_currentHistoryIndex]);
    }
  }

  /// Clear the undo/redo history
  void clearHistory() {
    _stateHistory.clear();
    _currentHistoryIndex = -1;
  }

  /// Save a state to history if it should be saved
  void _saveToHistory(State state) {
    if (shouldSaveToHistory(state)) {
      // Remove any states after current index (for redo)
      if (_currentHistoryIndex < _stateHistory.length - 1) {
        _stateHistory.removeRange(_currentHistoryIndex + 1, _stateHistory.length);
      }

      // Add new state
      _stateHistory.add(state);
      _currentHistoryIndex = _stateHistory.length - 1;

      // Limit history size
      if (_stateHistory.length > maxHistorySize) {
        _stateHistory.removeAt(0);
        _currentHistoryIndex--;
      }
    }
  }

  /// Override this method to control which states are saved to history
  /// 
  /// Return true if the state should be saved to history, false otherwise.
  /// By default, all states except loading and error states are saved.
  bool shouldSaveToHistory(State state) {
    return !state.isLoading && !state.hasError;
  }

  @override
  void onStateChanged(State state) {
    super.onStateChanged(state);
    _saveToHistory(state);
  }

  @override
  Map<String, dynamic> getDebugInfo() {
    final info = super.getDebugInfo();
    info.addAll({
      'canUndo': canUndo,
      'canRedo': canRedo,
      'historySize': historySize,
      'currentHistoryIndex': currentHistoryIndex,
    });
    return info;
  }
}
