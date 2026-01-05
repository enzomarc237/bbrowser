import 'package:equatable/equatable.dart';

/// Base class for all BLoC events in the application
/// 
/// This abstract class provides common functionality and ensures
/// consistent event structure across all BLoCs. All events should
/// extend this class to maintain architectural consistency.
/// 
/// Example:
/// ```dart
/// class MyEvent extends BaseEvent {
///   const MyEvent();
///   
///   @override
///   List<Object?> get props => [];
/// }
/// ```
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object?> get props => [];

  /// Optional timestamp for event tracking and debugging
  DateTime get timestamp => DateTime.now();

  /// Optional event type identifier for logging and debugging
  String get eventType => runtimeType.toString();

  @override
  String toString() {
    return '$eventType(${props.join(', ')})';
  }
}

/// Base class for error events that can be handled consistently
/// across all BLoCs
abstract class BaseErrorEvent extends BaseEvent {
  const BaseErrorEvent({
    required this.error,
    this.stackTrace,
    this.context,
  });

  /// The error that occurred
  final Object error;

  /// Optional stack trace for debugging
  final StackTrace? stackTrace;

  /// Optional context information about where the error occurred
  final String? context;

  @override
  List<Object?> get props => [error, stackTrace, context];

  @override
  String toString() {
    return '$eventType(error: $error, context: $context)';
  }
}

/// Base class for loading events that indicate async operations
abstract class BaseLoadingEvent extends BaseEvent {
  const BaseLoadingEvent({
    this.operation,
    this.progress,
  });

  /// Optional description of the operation being performed
  final String? operation;

  /// Optional progress indicator (0.0 to 1.0)
  final double? progress;

  @override
  List<Object?> get props => [operation, progress];
}

/// Base class for success events that indicate successful operations
abstract class BaseSuccessEvent extends BaseEvent {
  const BaseSuccessEvent({
    this.message,
    this.data,
  });

  /// Optional success message
  final String? message;

  /// Optional data associated with the success
  final Object? data;

  @override
  List<Object?> get props => [message, data];
}
