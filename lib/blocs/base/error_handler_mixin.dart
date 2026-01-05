import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_event.dart';
import 'base_state.dart';

/// Mixin that provides consistent error handling across all BLoCs
/// 
/// This mixin standardizes error handling patterns and provides
/// utilities for converting exceptions to user-friendly messages.
/// 
/// Example:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with ErrorHandlerMixin {
///   MyBloc() : super(MyInitialState()) {
///     on<MyEvent>((event, emit) async {
///       await handleErrors(
///         action: () => _performOperation(event),
///         emit: emit,
///         context: 'performing operation',
///       );
///     });
///   }
/// }
/// ```
mixin ErrorHandlerMixin<Event, State> on BlocBase<State> {
  /// Handle errors consistently across all BLoC operations
  /// 
  /// This method wraps async operations and converts exceptions
  /// to appropriate error states with user-friendly messages.
  Future<void> handleErrors({
    required Future<void> Function() action,
    required Emitter<State> emit,
    String? context,
    State Function(Object error, StackTrace? stackTrace, String? context)? errorStateBuilder,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      final errorState = errorStateBuilder?.call(error, stackTrace, context) ??
          _buildDefaultErrorState(error, stackTrace, context);
      
      if (errorState is State) {
        emit(errorState);
      }
      
      // Log error for debugging
      _logError(error, stackTrace, context);
    }
  }

  /// Handle errors with loading state management
  /// 
  /// This method manages loading states and error states together,
  /// ensuring proper UI feedback during async operations.
  Future<void> handleErrorsWithLoading({
    required Future<void> Function() action,
    required Emitter<State> emit,
    required State loadingState,
    String? context,
    State Function(Object error, StackTrace? stackTrace, String? context)? errorStateBuilder,
  }) async {
    emit(loadingState);
    
    try {
      await action();
    } catch (error, stackTrace) {
      final errorState = errorStateBuilder?.call(error, stackTrace, context) ??
          _buildDefaultErrorState(error, stackTrace, context);
      
      if (errorState is State) {
        emit(errorState);
      }
      
      // Log error for debugging
      _logError(error, stackTrace, context);
    }
  }

  /// Convert an exception to a user-friendly error message
  String getErrorMessage(Object error, {String? context}) {
    if (error is TimeoutException) {
      return 'Operation timed out. Please check your connection and try again.';
    } else if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (error is HttpException) {
      return 'Server error occurred. Please try again later.';
    } else if (error is FormatException) {
      return 'Invalid data format received. Please try again.';
    } else if (error is StateError) {
      return 'Application state error. Please restart the app.';
    } else if (error is ArgumentError) {
      return 'Invalid input provided. Please check your data and try again.';
    } else if (error is UnimplementedError) {
      return 'This feature is not yet available. Please try again later.';
    } else if (error is UnsupportedError) {
      return 'This operation is not supported on your device.';
    } else {
      // Generic error message
      final contextStr = context != null ? ' while $context' : '';
      return 'An unexpected error occurred$contextStr. Please try again.';
    }
  }

  /// Check if an error is recoverable (user can retry)
  bool isRecoverableError(Object error) {
    return error is TimeoutException ||
        error is SocketException ||
        error is HttpException ||
        error is FormatException;
  }

  /// Get retry action description for an error
  String? getRetryAction(Object error) {
    if (error is TimeoutException || error is SocketException) {
      return 'Check your connection and try again';
    } else if (error is HttpException) {
      return 'Try again in a few moments';
    } else if (error is FormatException) {
      return 'Refresh and try again';
    } else if (isRecoverableError(error)) {
      return 'Try again';
    }
    return null;
  }

  /// Build a default error state
  /// 
  /// This method should be overridden by concrete BLoCs to provide
  /// domain-specific error states.
  State _buildDefaultErrorState(Object error, StackTrace? stackTrace, String? context) {
    // This is a fallback - concrete BLoCs should override this
    throw UnimplementedError(
      'BLoC must implement error state building or provide errorStateBuilder parameter'
    );
  }

  /// Log error for debugging purposes
  void _logError(Object error, StackTrace? stackTrace, String? context) {
    final contextStr = context != null ? ' [$context]' : '';
    print('BLoC Error$contextStr: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}

/// Mixin that provides retry functionality for failed operations
/// 
/// This mixin allows BLoCs to implement retry logic for failed operations
/// with configurable retry policies.
/// 
/// Example:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with RetryMixin {
///   MyBloc() : super(MyInitialState()) {
///     on<MyEvent>((event, emit) async {
///       await retryOperation(
///         operation: () => _performOperation(event),
///         maxRetries: 3,
///         delay: Duration(seconds: 1),
///         shouldRetry: (error) => error is SocketException,
///       );
///     });
///   }
/// }
/// ```
mixin RetryMixin<Event, State> on BlocBase<State> {
  /// Retry an operation with configurable retry policy
  Future<T> retryOperation<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    
    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        // Check if we should retry this error
        final shouldRetryError = shouldRetry?.call(error) ?? _defaultShouldRetry(error);
        
        if (attempt > maxRetries || !shouldRetryError) {
          rethrow;
        }
        
        // Call retry callback
        onRetry?.call(attempt, error);
        
        // Wait before retrying
        if (delay.inMilliseconds > 0) {
          await Future.delayed(delay);
        }
      }
    }
    
    throw StateError('Retry operation completed without success or failure');
  }

  /// Default retry policy - retry on network and timeout errors
  bool _defaultShouldRetry(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException;
  }

  /// Exponential backoff delay calculation
  Duration exponentialBackoff(int attempt, {Duration baseDelay = const Duration(seconds: 1)}) {
    final multiplier = math.pow(2, attempt - 1).toInt();
    return Duration(milliseconds: baseDelay.inMilliseconds * multiplier);
  }
}

/// Import for math.pow
import 'dart:math' as math;

/// Mixin that provides circuit breaker functionality
/// 
/// This mixin implements the circuit breaker pattern to prevent
/// cascading failures by temporarily disabling operations that
/// are likely to fail.
/// 
/// Example:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with CircuitBreakerMixin {
///   MyBloc() : super(MyInitialState()) {
///     on<MyEvent>((event, emit) async {
///       await executeWithCircuitBreaker(
///         key: 'api_call',
///         operation: () => _callApi(event),
///         failureThreshold: 5,
///         timeout: Duration(minutes: 1),
///       );
///     });
///   }
/// }
/// ```
mixin CircuitBreakerMixin<Event, State> on BlocBase<State> {
  final Map<String, _CircuitBreakerState> _circuitBreakers = {};

  /// Execute an operation with circuit breaker protection
  Future<T> executeWithCircuitBreaker<T>({
    required String key,
    required Future<T> Function() operation,
    int failureThreshold = 5,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    final circuitBreaker = _circuitBreakers.putIfAbsent(
      key,
      () => _CircuitBreakerState(failureThreshold, timeout),
    );

    if (circuitBreaker.isOpen) {
      if (circuitBreaker.shouldAttemptReset) {
        circuitBreaker.halfOpen();
      } else {
        throw CircuitBreakerOpenException('Circuit breaker is open for $key');
      }
    }

    try {
      final result = await operation();
      circuitBreaker.recordSuccess();
      return result;
    } catch (error) {
      circuitBreaker.recordFailure();
      rethrow;
    }
  }

  /// Get circuit breaker state for debugging
  Map<String, String> getCircuitBreakerStates() {
    return _circuitBreakers.map(
      (key, breaker) => MapEntry(key, breaker.state.toString()),
    );
  }

  /// Reset a specific circuit breaker
  void resetCircuitBreaker(String key) {
    _circuitBreakers[key]?.reset();
  }

  /// Reset all circuit breakers
  void resetAllCircuitBreakers() {
    for (final breaker in _circuitBreakers.values) {
      breaker.reset();
    }
  }
}

/// Internal circuit breaker state management
class _CircuitBreakerState {
  final int failureThreshold;
  final Duration timeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  _CircuitState _state = _CircuitState.closed;

  _CircuitBreakerState(this.failureThreshold, this.timeout);

  bool get isOpen => _state == _CircuitState.open;
  bool get isClosed => _state == _CircuitState.closed;
  bool get isHalfOpen => _state == _CircuitState.halfOpen;

  bool get shouldAttemptReset {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) >= timeout;
  }

  _CircuitState get state => _state;

  void recordSuccess() {
    _failureCount = 0;
    _state = _CircuitState.closed;
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = _CircuitState.open;
    }
  }

  void halfOpen() {
    _state = _CircuitState.halfOpen;
  }

  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = _CircuitState.closed;
  }
}

enum _CircuitState { closed, open, halfOpen }

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String message;
  const CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
