import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin that provides lifecycle management for BLoCs
/// 
/// This mixin helps prevent memory leaks by properly managing
/// stream subscriptions and other resources. It should be used
/// by all BLoCs that need to manage external resources.
/// 
/// Example:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with BlocLifecycleMixin {
///   MyBloc() : super(MyInitialState()) {
///     // Register subscriptions
///     addSubscription(someStream.listen(handleData));
///   }
/// }
/// ```
mixin BlocLifecycleMixin<Event, State> on BlocBase<State> {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<void Function()> _disposables = [];

  /// Add a stream subscription to be managed by this BLoC
  /// 
  /// The subscription will be automatically cancelled when the BLoC is closed
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Add a timer to be managed by this BLoC
  /// 
  /// The timer will be automatically cancelled when the BLoC is closed
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Add a custom disposable function to be called when the BLoC is closed
  /// 
  /// This is useful for cleaning up resources that don't fit the standard patterns
  void addDisposable(void Function() disposable) {
    _disposables.add(disposable);
  }

  /// Remove a specific subscription from management
  /// 
  /// This is useful when you need to cancel a subscription before the BLoC is closed
  void removeSubscription(StreamSubscription subscription) {
    _subscriptions.remove(subscription);
    subscription.cancel();
  }

  /// Remove a specific timer from management
  /// 
  /// This is useful when you need to cancel a timer before the BLoC is closed
  void removeTimer(Timer timer) {
    _timers.remove(timer);
    timer.cancel();
  }

  /// Get the number of active subscriptions
  int get activeSubscriptionsCount => _subscriptions.length;

  /// Get the number of active timers
  int get activeTimersCount => _timers.length;

  /// Get the number of registered disposables
  int get disposablesCount => _disposables.length;

  /// Check if the BLoC has any active resources
  bool get hasActiveResources =>
      _subscriptions.isNotEmpty || _timers.isNotEmpty || _disposables.isNotEmpty;

  @override
  Future<void> close() async {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    // Call all disposable functions
    for (final disposable in _disposables) {
      try {
        disposable();
      } catch (e) {
        // Log error but don't prevent other disposables from running
        print('Error disposing resource: $e');
      }
    }
    _disposables.clear();

    return super.close();
  }
}

/// Mixin that provides debouncing functionality for BLoCs
/// 
/// This mixin helps prevent rapid-fire events from overwhelming
/// the BLoC by debouncing similar events.
/// 
/// Example:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with BlocDebounceMixin {
///   MyBloc() : super(MyInitialState()) {
///     on<SearchEvent>((event, emit) async {
///       await debounce(
///         key: 'search',
///         duration: Duration(milliseconds: 300),
///         action: () => _handleSearch(event, emit),
///       );
///     });
///   }
/// }
/// ```
mixin BlocDebounceMixin<Event, State> on BlocBase<State> {
  final Map<String, Timer> _debounceTimers = {};

  /// Debounce an action with the given key and duration
  /// 
  /// If another call with the same key is made before the duration expires,
  /// the previous call is cancelled and a new timer is started.
  Future<void> debounce({
    required String key,
    required Duration duration,
    required Future<void> Function() action,
  }) async {
    // Cancel existing timer for this key
    _debounceTimers[key]?.cancel();

    // Create new timer
    final completer = Completer<void>();
    _debounceTimers[key] = Timer(duration, () async {
      _debounceTimers.remove(key);
      try {
        await action();
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Cancel debounce for a specific key
  void cancelDebounce(String key) {
    _debounceTimers[key]?.cancel();
    _debounceTimers.remove(key);
  }

  /// Cancel all active debounce timers
  void cancelAllDebounce() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  /// Get the number of active debounce timers
  int get activeDebounceCount => _debounceTimers.length;

  @override
  Future<void> close() async {
    cancelAllDebounce();
    return super.close();
  }
}

/// Mixin that provides throttling functionality for BLoCs
/// 
/// This mixin helps limit the rate of event processing by
/// throttling similar events.
/// 
/// Example:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with BlocThrottleMixin {
///   MyBloc() : super(MyInitialState()) {
///     on<ScrollEvent>((event, emit) async {
///       await throttle(
///         key: 'scroll',
///         duration: Duration(milliseconds: 100),
///         action: () => _handleScroll(event, emit),
///       );
///     });
///   }
/// }
/// ```
mixin BlocThrottleMixin<Event, State> on BlocBase<State> {
  final Map<String, DateTime> _lastExecutionTimes = {};

  /// Throttle an action with the given key and duration
  /// 
  /// The action will only be executed if the specified duration has passed
  /// since the last execution with the same key.
  Future<void> throttle({
    required String key,
    required Duration duration,
    required Future<void> Function() action,
  }) async {
    final now = DateTime.now();
    final lastExecution = _lastExecutionTimes[key];

    if (lastExecution == null || now.difference(lastExecution) >= duration) {
      _lastExecutionTimes[key] = now;
      await action();
    }
  }

  /// Reset throttle for a specific key
  void resetThrottle(String key) {
    _lastExecutionTimes.remove(key);
  }

  /// Reset all throttle timers
  void resetAllThrottle() {
    _lastExecutionTimes.clear();
  }

  /// Get the number of active throttle keys
  int get activeThrottleCount => _lastExecutionTimes.length;
}
