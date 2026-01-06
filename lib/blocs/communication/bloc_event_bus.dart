import 'dart:async';
import '../base/base_event.dart';

/// Global event bus for cross-BLoC communication
/// 
/// This class provides a centralized event bus that allows BLoCs to
/// communicate with each other without creating direct dependencies.
/// It prevents circular dependencies while enabling loose coupling.
/// 
/// Example:
/// ```dart
/// // In TabBloc
/// BlocEventBus.instance.publish(TabSelectedGlobalEvent(tabId));
/// 
/// // In NavigationBloc
/// BlocEventBus.instance.subscribe<TabSelectedGlobalEvent>((event) {
///   // Handle tab selection in navigation context
/// });
/// ```
class BlocEventBus {
  static final BlocEventBus _instance = BlocEventBus._internal();
  static BlocEventBus get instance => _instance;

  BlocEventBus._internal();

  final StreamController<BaseEvent> _eventController = StreamController<BaseEvent>.broadcast();
  final Map<Type, List<StreamSubscription>> _subscriptions = {};
  final Map<String, StreamSubscription> _namedSubscriptions = {};

  /// Get the event stream
  Stream<BaseEvent> get eventStream => _eventController.stream;

  /// Publish an event to the bus
  /// 
  /// All subscribers to this event type will receive the event.
  void publish(BaseEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Subscribe to events of a specific type
  /// 
  /// Returns a StreamSubscription that can be used to cancel the subscription.
  StreamSubscription<T> subscribe<T extends BaseEvent>(
    void Function(T event) handler, {
    String? subscriptionId,
  }) {
    final subscription = eventStream
        .where((event) => event is T)
        .cast<T>()
        .listen(handler);

    // Track subscription for cleanup
    _subscriptions.putIfAbsent(T, () => []).add(subscription);

    // Track named subscription if provided
    if (subscriptionId != null) {
      _namedSubscriptions[subscriptionId] = subscription;
    }

    return subscription;
  }

  /// Subscribe to multiple event types
  /// 
  /// Returns a list of StreamSubscriptions.
  List<StreamSubscription> subscribeToMultiple(
    Map<Type, void Function(BaseEvent event)> handlers,
  ) {
    final subscriptions = <StreamSubscription>[];

    for (final entry in handlers.entries) {
      final subscription = eventStream
          .where((event) => _isEventOfType(event, entry.key))
          .listen(entry.value);

      subscriptions.add(subscription);
      _subscriptions.putIfAbsent(entry.key, () => []).add(subscription);
    }

    return subscriptions;
  }

  /// Helper method to check if an event is of a specific type
  /// Uses the same logic as the generic subscribe method
  bool _isEventOfType(BaseEvent event, Type type) {
    // This mimics the behavior of `event is T` but with runtime Type
    return event.runtimeType == type || 
           _isSubtypeOf(event.runtimeType, type);
  }

  /// Check if sourceType is a subtype of targetType
  bool _isSubtypeOf(Type sourceType, Type targetType) {
    // For basic type checking, we'll use string comparison
    // This is a simplified approach - in a production system,
    // you might want to use reflection or maintain a type hierarchy
    final sourceString = sourceType.toString();
    final targetString = targetType.toString();
    
    // If they're the same, it's a match
    if (sourceString == targetString) return true;
    
    // For now, we'll be conservative and only match exact types
    // This maintains backward compatibility while being consistent
    return false;
  }

  /// Unsubscribe from events of a specific type
  /// 
  /// Cancels all subscriptions for the given event type.
  Future<void> unsubscribe<T extends BaseEvent>() async {
    final subscriptions = _subscriptions[T];
    if (subscriptions != null) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.remove(T);
    }
  }

  /// Unsubscribe a named subscription
  Future<void> unsubscribeNamed(String subscriptionId) async {
    final subscription = _namedSubscriptions[subscriptionId];
    if (subscription != null) {
      await subscription.cancel();
      _namedSubscriptions.remove(subscriptionId);
      
      // Remove from type-based tracking
      for (final subscriptions in _subscriptions.values) {
        subscriptions.remove(subscription);
      }
    }
  }

  /// Unsubscribe all subscriptions
  Future<void> unsubscribeAll() async {
    // Cancel all subscriptions
    for (final subscriptions in _subscriptions.values) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    _subscriptions.clear();

    // Cancel named subscriptions
    for (final subscription in _namedSubscriptions.values) {
      await subscription.cancel();
    }
    _namedSubscriptions.clear();
  }

  /// Get the number of active subscriptions
  int get activeSubscriptionsCount {
    return _subscriptions.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Get the number of active subscriptions for a specific event type
  int getSubscriptionCount<T extends BaseEvent>() {
    return _subscriptions[T]?.length ?? 0;
  }

  /// Get debug information about the event bus
  Map<String, dynamic> getDebugInfo() {
    return {
      'totalSubscriptions': activeSubscriptionsCount,
      'namedSubscriptions': _namedSubscriptions.length,
      'eventTypes': _subscriptions.keys.map((type) => type.toString()).toList(),
      'subscriptionsByType': _subscriptions.map(
        (type, subscriptions) => MapEntry(type.toString(), subscriptions.length),
      ),
    };
  }

  /// Dispose the event bus
  /// 
  /// This should be called when the app is shutting down.
  Future<void> dispose() async {
    await unsubscribeAll();
    await _eventController.close();
  }
}

/// Base class for global events that are published on the event bus
/// 
/// These events are used for cross-BLoC communication and should be
/// designed to be self-contained with all necessary information.
abstract class GlobalEvent extends BaseEvent {
  const GlobalEvent();

  /// The source BLoC that published this event
  String? get sourceBlocName => null;

  /// Priority of this event (higher numbers = higher priority)
  int get priority => 0;

  /// Whether this event should be logged
  bool get shouldLog => true;
}

/// Mixin for BLoCs that participate in cross-BLoC communication
/// 
/// This mixin provides convenient methods for publishing and subscribing
/// to global events through the event bus.
mixin BlocCommunicationMixin<Event, State> {
  final List<StreamSubscription> _globalSubscriptions = [];

  /// Publish a global event to the event bus
  void publishGlobalEvent(GlobalEvent event) {
    BlocEventBus.instance.publish(event);
  }

  /// Subscribe to global events of a specific type
  void subscribeToGlobalEvent<T extends GlobalEvent>(
    void Function(T event) handler, {
    String? subscriptionId,
  }) {
    final subscription = BlocEventBus.instance.subscribe<T>(
      handler,
      subscriptionId: subscriptionId,
    );
    _globalSubscriptions.add(subscription);
  }

  /// Subscribe to multiple global event types
  void subscribeToMultipleGlobalEvents(
    Map<Type, void Function(BaseEvent event)> handlers,
  ) {
    final subscriptions = BlocEventBus.instance.subscribeToMultiple(handlers);
    _globalSubscriptions.addAll(subscriptions);
  }

  /// Dispose all global subscriptions
  /// 
  /// This should be called in the BLoC's close method.
  Future<void> disposeGlobalSubscriptions() async {
    for (final subscription in _globalSubscriptions) {
      await subscription.cancel();
    }
    _globalSubscriptions.clear();
  }

  /// Get the number of active global subscriptions
  int get globalSubscriptionsCount => _globalSubscriptions.length;
}

/// Common global events for cross-BLoC communication

/// Event published when a tab is selected
class TabSelectedGlobalEvent extends GlobalEvent {
  const TabSelectedGlobalEvent(this.tabId);

  final String tabId;

  @override
  String get sourceBlocName => 'TabBloc';

  @override
  List<Object?> get props => [tabId];
}

/// Event published when a tab is closed
class TabClosedGlobalEvent extends GlobalEvent {
  const TabClosedGlobalEvent(this.tabId);

  final String tabId;

  @override
  String get sourceBlocName => 'TabBloc';

  @override
  List<Object?> get props => [tabId];
}

/// Event published when navigation occurs
class NavigationGlobalEvent extends GlobalEvent {
  const NavigationGlobalEvent({
    required this.url,
    required this.tabId,
    this.title,
  });

  final String url;
  final String tabId;
  final String? title;

  @override
  String get sourceBlocName => 'NavigationBloc';

  @override
  List<Object?> get props => [url, tabId, title];
}

/// Event published when settings change
class SettingsChangedGlobalEvent extends GlobalEvent {
  const SettingsChangedGlobalEvent({
    required this.settingKey,
    required this.newValue,
    this.oldValue,
  });

  final String settingKey;
  final dynamic newValue;
  final dynamic oldValue;

  @override
  String get sourceBlocName => 'SettingsBloc';

  @override
  List<Object?> get props => [settingKey, newValue, oldValue];
}

/// Event published when a bookmark is added
class BookmarkAddedGlobalEvent extends GlobalEvent {
  const BookmarkAddedGlobalEvent({
    required this.url,
    required this.title,
    this.tabId,
  });

  final String url;
  final String title;
  final String? tabId;

  @override
  String get sourceBlocName => 'BookmarkBloc';

  @override
  List<Object?> get props => [url, title, tabId];
}

/// Event published when an error occurs that affects multiple BLoCs
class GlobalErrorEvent extends GlobalEvent {
  const GlobalErrorEvent({
    required this.error,
    required this.context,
    this.stackTrace,
    this.affectedBlocs,
  });

  final Object error;
  final String context;
  final StackTrace? stackTrace;
  final List<String>? affectedBlocs;

  @override
  int get priority => 10; // High priority for errors

  @override
  List<Object?> get props => [error, context, stackTrace, affectedBlocs];
}
