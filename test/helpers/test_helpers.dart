import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../lib/models/tab.dart' as tab_model;
import '../../lib/blocs/tab/tab_bloc.dart';
import '../../lib/blocs/tab/tab_state.dart';

/// Common test utilities and helper functions for BBrowser tests

/// Mock classes for testing
class MockTabBloc extends Mock implements TabBloc {}

/// Test utilities for widget testing
class WidgetTestHelpers {
  /// Creates a MaterialApp wrapper for widget testing
  static Widget createTestApp({
    required Widget child,
    List<BlocProvider>? providers,
  }) {
    Widget app = MaterialApp(
      home: Scaffold(body: child),
    );

    if (providers != null && providers.isNotEmpty) {
      app = MultiBlocProvider(
        providers: providers,
        child: app,
      );
    }

    return app;
  }

  /// Creates a test app with TabBloc provider
  static Widget createTestAppWithTabBloc({
    required Widget child,
    TabBloc? tabBloc,
  }) {
    return createTestApp(
      child: child,
      providers: [
        BlocProvider<TabBloc>.value(
          value: tabBloc ?? MockTabBloc(),
        ),
      ],
    );
  }

  /// Pumps a widget with common test setup
  static Future<void> pumpTestWidget(
    WidgetTester tester,
    Widget widget, {
    List<BlocProvider>? providers,
  }) async {
    await tester.pumpWidget(
      createTestApp(
        child: widget,
        providers: providers,
      ),
    );
  }

  /// Pumps a widget with TabBloc provider
  static Future<void> pumpTestWidgetWithTabBloc(
    WidgetTester tester,
    Widget widget, {
    TabBloc? tabBloc,
  }) async {
    await tester.pumpWidget(
      createTestAppWithTabBloc(
        child: widget,
        tabBloc: tabBloc,
      ),
    );
  }

  /// Finds a widget by its key
  static Finder findByTestKey(String key) {
    return find.byKey(Key(key));
  }

  /// Finds a widget by its type
  static Finder findByWidgetType<T extends Widget>() {
    return find.byType(T);
  }

  /// Taps a widget and pumps the frame
  static Future<void> tapAndPump(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
  }

  /// Enters text into a text field and pumps
  static Future<void> enterTextAndPump(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Waits for a specific condition to be true
  static Future<void> waitForCondition(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (!condition() && stopwatch.elapsed < timeout) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    stopwatch.stop();
    
    if (!condition()) {
      throw TimeoutException(
        'Condition not met within timeout',
        timeout,
      );
    }
  }
}

/// Test utilities for BLoC testing
class BlocTestHelpers {
  /// Sets up common mock behaviors for TabBloc
  static void setupMockTabBloc(MockTabBloc mockBloc) {
    when(() => mockBloc.state).thenReturn(const TabInitial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
  }

  /// Creates a mock TabBloc with initial state
  static MockTabBloc createMockTabBloc({TabState? initialState}) {
    final mockBloc = MockTabBloc();
    when(() => mockBloc.state).thenReturn(initialState ?? const TabInitial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    return mockBloc;
  }
}

/// Test utilities for data validation
class TestValidators {
  /// Validates that a Tab object has all required fields
  static bool isValidTab(tab_model.Tab tab) {
    return tab.id.isNotEmpty &&
           tab.title.isNotEmpty &&
           tab.url.isNotEmpty &&
           tab.loadingProgress >= 0.0 &&
           tab.loadingProgress <= 1.0;
  }

  /// Validates that a Tab is in a consistent state
  static bool isConsistentTabState(tab_model.Tab tab) {
    // If loading, progress should be < 1.0
    if (tab.isLoading && tab.loadingProgress >= 1.0) {
      return false;
    }

    // If not loading, progress should be 0.0 or 1.0
    if (!tab.isLoading && tab.loadingProgress > 0.0 && tab.loadingProgress < 1.0) {
      return false;
    }

    // If has error, should not be loading
    if (tab.hasError && tab.isLoading) {
      return false;
    }

    // If has error, should have error message
    if (tab.hasError && (tab.errorMessage == null || tab.errorMessage!.isEmpty)) {
      return false;
    }

    // HTTPS URLs should be secure
    if (tab.url.startsWith('https://') && !tab.isSecure) {
      return false;
    }

    return true;
  }

  /// Validates that timestamps are in correct order
  static bool areTimestampsValid(tab_model.Tab tab) {
    if (tab.createdAt == null || tab.lastAccessedAt == null) {
      return true; // Null timestamps are allowed
    }

    // lastAccessedAt should be >= createdAt
    return !tab.lastAccessedAt!.isBefore(tab.createdAt!);
  }
}

/// Test utilities for performance testing
class PerformanceTestHelpers {
  /// Measures the execution time of a function
  static Future<Duration> measureExecutionTime(Future<void> Function() function) async {
    final stopwatch = Stopwatch()..start();
    await function();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Measures memory usage during test execution
  static Future<T> measureMemoryUsage<T>(Future<T> Function() function) async {
    // Note: Actual memory measurement would require platform-specific code
    // This is a placeholder for memory measurement functionality
    return await function();
  }

  /// Creates a performance benchmark
  static Future<void> benchmark(
    String name,
    Future<void> Function() function, {
    int iterations = 100,
    Duration? maxExpectedTime,
  }) async {
    final times = <Duration>[];
    
    for (int i = 0; i < iterations; i++) {
      final time = await measureExecutionTime(function);
      times.add(time);
    }

    final averageTime = Duration(
      microseconds: times
          .map((t) => t.inMicroseconds)
          .reduce((a, b) => a + b) ~/
          times.length,
    );

    print('Benchmark $name:');
    print('  Average time: ${averageTime.inMilliseconds}ms');
    print('  Min time: ${times.map((t) => t.inMilliseconds).reduce((a, b) => a < b ? a : b)}ms');
    print('  Max time: ${times.map((t) => t.inMilliseconds).reduce((a, b) => a > b ? a : b)}ms');

    if (maxExpectedTime != null && averageTime > maxExpectedTime) {
      throw Exception(
        'Performance benchmark failed: $name took ${averageTime.inMilliseconds}ms, '
        'expected max ${maxExpectedTime.inMilliseconds}ms',
      );
    }
  }
}

/// Test utilities for async operations
class AsyncTestHelpers {
  /// Waits for all microtasks to complete
  static Future<void> flushMicrotasks() async {
    await Future.delayed(Duration.zero);
  }

  /// Waits for a specific duration
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Retries an operation until it succeeds or times out
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt < maxAttempts) {
          await wait(delay);
        }
      }
    }
    
    throw lastException!;
  }
}

/// Custom exception for test timeouts
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
