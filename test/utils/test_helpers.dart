import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

/// Test utilities and helpers for the browser application
class TestHelpers {
  /// Creates a test widget wrapped with MacosApp and necessary providers
  static Widget createTestWidget({
    required Widget child,
    List<BlocProvider> providers = const [],
  }) {
    return MultiBlocProvider(
      providers: providers,
      child: MacosApp(
        theme: MacosThemeData.light(),
        home: child,
      ),
    );
  }

  /// Creates a test widget with minimal MacosApp wrapper
  static Widget createMinimalTestWidget(Widget child) {
    return MacosApp(
      theme: MacosThemeData.light(),
      home: Scaffold(body: child),
    );
  }

  /// Pumps a widget and settles all animations
  static Future<void> pumpAndSettleWidget(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Finds a widget by its key
  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  /// Finds a widget by its text
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Finds a widget by its type
  static Finder findByType<T>() {
    return find.byType(T);
  }

  /// Verifies that a widget exists
  static void expectWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifies that a widget does not exist
  static void expectWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies that multiple widgets exist
  static void expectWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }
}
