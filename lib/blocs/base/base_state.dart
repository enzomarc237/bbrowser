import 'package:equatable/equatable.dart';

/// Sentinel object for copyWith methods to distinguish between null and not provided
const Object _sentinel = Object();

/// Base class for all BLoC states in the application
/// 
/// This abstract class provides common functionality and ensures
/// consistent state structure across all BLoCs. All states should
/// extend this class to maintain architectural consistency.
/// 
/// Example:
/// ```dart
/// class MyState extends BaseState {
///   const MyState();
///   
///   @override
///   List<Object?> get props => [];
/// }
/// ```
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];

  /// Optional timestamp for state tracking and debugging
  DateTime get timestamp => DateTime.now();

  /// Optional state type identifier for logging and debugging
  String get stateType => runtimeType.toString();

  /// Whether this state represents a loading condition
  bool get isLoading => false;

  /// Whether this state represents an error condition
  bool get hasError => false;

  /// Whether this state represents a successful condition
  bool get isSuccess => false;

  /// Whether this state represents an initial/empty condition
  bool get isInitial => false;

  @override
  String toString() {
    return '$stateType(${props.join(', ')})';
  }
}

/// Base class for initial states
abstract class BaseInitialState extends BaseState {
  const BaseInitialState();

  @override
  bool get isInitial => true;
}

/// Base class for loading states
abstract class BaseLoadingState extends BaseState {
  const BaseLoadingState({
    this.operation,
    this.progress,
    this.message,
  });

  /// Optional description of the operation being performed
  final String? operation;

  /// Optional progress indicator (0.0 to 1.0)
  final double? progress;

  /// Optional loading message to display to user
  final String? message;

  @override
  bool get isLoading => true;

  @override
  List<Object?> get props => [operation, progress, message];

  @override
  String toString() {
    return '$stateType(operation: $operation, progress: $progress, message: $message)';
  }
}

/// Base class for success/loaded states
abstract class BaseLoadedState extends BaseState {
  const BaseLoadedState();

  @override
  bool get isSuccess => true;
}

/// Base class for error states
abstract class BaseErrorState extends BaseState {
  const BaseErrorState({
    required this.error,
    this.message,
    this.stackTrace,
    this.context,
    this.isRecoverable = true,
    this.retryAction,
  });

  /// The error that occurred
  final Object error;

  /// User-friendly error message
  final String? message;

  /// Optional stack trace for debugging
  final StackTrace? stackTrace;

  /// Optional context information about where the error occurred
  final String? context;

  /// Whether the error is recoverable (user can retry)
  final bool isRecoverable;

  /// Optional retry action description
  final String? retryAction;

  @override
  bool get hasError => true;

  /// Get user-friendly error message
  String get userMessage {
    if (message != null) return message!;
    
    // Provide default user-friendly messages for common errors
    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    } else if (error is TimeoutException) {
      return 'Operation timed out. Please try again.';
    } else if (error is StateError) {
      return 'Application state error. Please restart the app.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  List<Object?> get props => [
        error,
        message,
        stackTrace,
        context,
        isRecoverable,
        retryAction,
      ];

  @override
  String toString() {
    return '$stateType(error: $error, message: $message, context: $context, recoverable: $isRecoverable)';
  }
}

/// Base class for operation in progress states
abstract class BaseOperationInProgressState extends BaseState {
  const BaseOperationInProgressState({
    required this.operation,
    this.progress,
    this.message,
    this.canCancel = false,
  });

  /// Description of the operation being performed
  final String operation;

  /// Optional progress indicator (0.0 to 1.0)
  final double? progress;

  /// Optional message to display to user
  final String? message;

  /// Whether the operation can be cancelled
  final bool canCancel;

  @override
  bool get isLoading => true;

  @override
  List<Object?> get props => [operation, progress, message, canCancel];

  @override
  String toString() {
    return '$stateType(operation: $operation, progress: $progress, message: $message, canCancel: $canCancel)';
  }
}

/// Mixin for states that support copyWith functionality
mixin CopyWithMixin<T extends BaseState> on BaseState {
  /// Creates a copy of this state with updated values
  /// 
  /// This method should be implemented by concrete state classes
  /// to provide type-safe copying functionality.
  T copyWith();
}

/// Mixin for states that support data payload
mixin DataStateMixin<T> on BaseState {
  /// The data payload for this state
  T? get data;

  /// Whether this state has data
  bool get hasData => data != null;
}

/// Mixin for states that support pagination
mixin PaginationStateMixin on BaseState {
  /// Current page number (0-based)
  int get currentPage;

  /// Total number of pages
  int? get totalPages;

  /// Whether there are more pages available
  bool get hasNextPage;

  /// Whether there are previous pages available
  bool get hasPreviousPage => currentPage > 0;

  /// Whether this is the first page
  bool get isFirstPage => currentPage == 0;

  /// Whether this is the last page
  bool get isLastPage => totalPages != null && currentPage >= totalPages! - 1;
}
