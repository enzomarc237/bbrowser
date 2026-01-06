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
/// 
/// // For events that need timestamp tracking:
/// class MyTimestampedEvent extends BaseEvent {
///   MyTimestampedEvent() : super.withTimestamp();
/// }
/// ```
abstract class BaseEvent extends Equatable {
  const BaseEvent({this.timestamp});

  /// Factory constructor that captures creation timestamp
  BaseEvent.withTimestamp() : timestamp = DateTime.now();

  @override
  List<Object?> get props => [timestamp];

  /// Optional timestamp for event tracking and debugging
  /// If null, timestamp tracking is disabled for this event
  final DateTime? timestamp;

  /// Optional event type identifier for logging and debugging
  String get eventType => runtimeType.toString();

  @override
  String toString() {
    final propsStr = props.where((prop) => prop != null).join(', ');
    final timestampStr = timestamp != null ? ', timestamp: $timestamp' : '';
    return '$eventType($propsStr$timestampStr)';
  }
}

/// Base class for error events that can be handled consistently
/// across all BLoCs
abstract class BaseErrorEvent extends BaseEvent {
  const BaseErrorEvent({
    required this.error,
    this.stackTrace,
    this.context,
    DateTime? timestamp,
  }) : super(timestamp: timestamp);

  /// The error that occurred
  final Object error;

  /// Optional stack trace for debugging
  final StackTrace? stackTrace;

  /// Optional context information about where the error occurred
  final String? context;

  @override
  List<Object?> get props => [error, stackTrace, context, timestamp];

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
    DateTime? timestamp,
  }) : super(timestamp: timestamp);

  /// Optional description of the operation being performed
  final String? operation;

  /// Optional progress indicator (0.0 to 1.0)
  final double? progress;

  @override
  List<Object?> get props => [operation, progress, timestamp];
}

/// Base class for success events that indicate successful operations
abstract class BaseSuccessEvent extends BaseEvent {
  const BaseSuccessEvent({
    this.message,
    this.data,
    DateTime? timestamp,
  }) : super(timestamp: timestamp);

  /// Optional success message
  final String? message;

  /// Optional data associated with the success
  final Object? data;

  @override
  List<Object?> get props => [message, data, timestamp];
}
