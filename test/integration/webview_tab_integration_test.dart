import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:bbrowser/widgets/content_view.dart';
import 'package:bbrowser/widgets/web_view_widget.dart';
import 'package:bbrowser/blocs/tab/tab_bloc.dart';
import 'package:bbrowser/blocs/tab/tab_state.dart';
import 'package:bbrowser/blocs/tab/tab_event.dart';
import 'package:bbrowser/models/tab.dart';

// Mock classes
class MockTabBloc extends Mock implements TabBloc {}

void main() {
  group('WebView Tab Integration', () {
    late MockTabBloc mockTabBloc;

    setUp(() {
      mockTabBloc = MockTabBloc();
    });

    Widget createTestWidget({
      required TabState initialState,
    }) {
      when(() => mockTabBloc.state).thenReturn(initialState);
      
      return MacosApp(
        home: BlocProvider<TabBloc>.value(
          value: mockTabBloc,
          child: const MacosScaffold(
            children: [
              ContentView(),
            ],
          ),
        ),
      );
    }

    group('Content View Integration', () {
      testWidgets('should show WebView when tab has URL', (tester) async {
        final tabState = TabLoaded(
          tabs: [
            Tab.newTab(
              id: 'test_tab',
              url: 'https://example.com',
              title: 'Example Page',
            ),
          ],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show WebView widget
        expect(find.byType(WebViewWidget), findsOneWidget);
        expect(find.text('WebView Integration Coming Soon'), findsNothing);
      });

      testWidgets('should show welcome view when no tabs', (tester) async {
        const tabState = TabInitial();

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show welcome view
        expect(find.text('Welcome to Browser'), findsOneWidget);
        expect(find.text('Create a new tab to start browsing the web'), findsOneWidget);
        expect(find.byType(WebViewWidget), findsNothing);
      });

      testWidgets('should show no tab view when no active tab', (tester) async {
        final tabState = TabLoaded(
          tabs: [
            Tab.newTab(
              id: 'test_tab',
              url: 'https://example.com',
              title: 'Example Page',
            ),
          ],
          activeTabId: null,
        );

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show no tab view
        expect(find.text('No Tab Selected'), findsOneWidget);
        expect(find.byType(WebViewWidget), findsNothing);
      });

      testWidgets('should show error view when tab has error', (tester) async {
        final tabState = TabLoaded(
          tabs: [
            Tab.newTab(
              id: 'test_tab',
              url: 'https://example.com',
              title: 'Example Page',
            ).copyWith(
              hasError: true,
              errorMessage: 'Network error',
            ),
          ],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show error view
        expect(find.text('Error Loading Page'), findsOneWidget);
        expect(find.text('Network error'), findsOneWidget);
        expect(find.byType(WebViewWidget), findsNothing);
      });

      testWidgets('should show loading view when tab is loading', (tester) async {
        const tabState = TabLoading();

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show loading indicator
        expect(find.byType(ProgressCircle), findsOneWidget);
        expect(find.byType(WebViewWidget), findsNothing);
      });
    });

    group('Tab State Updates', () {
      testWidgets('should update WebView when tab URL changes', (tester) async {
        final initialTab = Tab.newTab(
          id: 'test_tab',
          url: 'https://example.com',
          title: 'Example Page',
        );

        final initialState = TabLoaded(
          tabs: [initialTab],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: initialState));

        // Verify initial WebView
        expect(find.byType(WebViewWidget), findsOneWidget);

        // Simulate tab URL update
        final updatedTab = initialTab.copyWith(
          url: 'https://google.com',
          title: 'Google',
        );

        final updatedState = TabLoaded(
          tabs: [updatedTab],
          activeTabId: 'test_tab',
        );

        when(() => mockTabBloc.state).thenReturn(updatedState);

        // Trigger rebuild
        await tester.pumpWidget(createTestWidget(initialState: updatedState));

        // Should still show WebView (with updated URL)
        expect(find.byType(WebViewWidget), findsOneWidget);
      });

      testWidgets('should handle tab switching', (tester) async {
        final tab1 = Tab.newTab(
          id: 'tab1',
          url: 'https://example.com',
          title: 'Example',
        );

        final tab2 = Tab.newTab(
          id: 'tab2',
          url: 'https://google.com',
          title: 'Google',
        );

        final initialState = TabLoaded(
          tabs: [tab1, tab2],
          activeTabId: 'tab1',
        );

        await tester.pumpWidget(createTestWidget(initialState: initialState));

        // Should show WebView for tab1
        expect(find.byType(WebViewWidget), findsOneWidget);

        // Switch to tab2
        final switchedState = TabLoaded(
          tabs: [tab1, tab2],
          activeTabId: 'tab2',
        );

        when(() => mockTabBloc.state).thenReturn(switchedState);

        await tester.pumpWidget(createTestWidget(initialState: switchedState));

        // Should still show WebView (now for tab2)
        expect(find.byType(WebViewWidget), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle WebView initialization errors gracefully', (tester) async {
        final tabState = TabLoaded(
          tabs: [
            Tab.newTab(
              id: 'test_tab',
              url: 'invalid-url',
              title: 'Invalid URL',
            ),
          ],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show WebView widget (which will handle the error internally)
        expect(find.byType(WebViewWidget), findsOneWidget);
      });

      testWidgets('should handle empty URL gracefully', (tester) async {
        final tabState = TabLoaded(
          tabs: [
            Tab.newTab(
              id: 'test_tab',
              url: '',
              title: 'Empty URL',
            ),
          ],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show WebView widget
        expect(find.byType(WebViewWidget), findsOneWidget);
      });

      testWidgets('should handle about:blank URL', (tester) async {
        final tabState = TabLoaded(
          tabs: [
            Tab.newTab(
              id: 'test_tab',
              url: 'about:blank',
              title: 'New Tab',
            ),
          ],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Should show WebView widget
        expect(find.byType(WebViewWidget), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should handle new tab creation', (tester) async {
        const initialState = TabInitial();

        await tester.pumpWidget(createTestWidget(initialState: initialState));

        // Find and tap the "New Tab" button
        final newTabButton = find.text('New Tab');
        expect(newTabButton, findsOneWidget);

        await tester.tap(newTabButton);
        await tester.pump();

        // Verify that TabCreated event would be dispatched
        verify(() => mockTabBloc.add(const TabCreated())).called(1);
      });

      testWidgets('should handle reload action', (tester) async {
        final tabState = TabLoaded(
          tabs: [
            Tab.newTab(
              id: 'test_tab',
              url: 'https://example.com',
              title: 'Example Page',
            ).copyWith(
              hasError: true,
              errorMessage: 'Network error',
            ),
          ],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: tabState));

        // Find and tap the "Reload" button in error view
        final reloadButton = find.text('Reload');
        expect(reloadButton, findsOneWidget);

        await tester.tap(reloadButton);
        await tester.pump();

        // Verify that TabReload event would be dispatched
        verify(() => mockTabBloc.add(const TabReload())).called(1);
      });
    });

    group('Performance', () {
      testWidgets('should not recreate WebView unnecessarily', (tester) async {
        final tab = Tab.newTab(
          id: 'test_tab',
          url: 'https://example.com',
          title: 'Example Page',
        );

        final initialState = TabLoaded(
          tabs: [tab],
          activeTabId: 'test_tab',
        );

        await tester.pumpWidget(createTestWidget(initialState: initialState));

        // Get initial WebView widget
        final initialWebView = tester.widget<WebViewWidget>(find.byType(WebViewWidget));

        // Update tab with same ID but different title
        final updatedTab = tab.copyWith(title: 'Updated Title');
        final updatedState = TabLoaded(
          tabs: [updatedTab],
          activeTabId: 'test_tab',
        );

        when(() => mockTabBloc.state).thenReturn(updatedState);

        await tester.pumpWidget(createTestWidget(initialState: updatedState));

        // WebView should be the same instance (same tabId)
        final updatedWebView = tester.widget<WebViewWidget>(find.byType(WebViewWidget));
        expect(updatedWebView.tabId, equals(initialWebView.tabId));
      });
    });
  });
}
