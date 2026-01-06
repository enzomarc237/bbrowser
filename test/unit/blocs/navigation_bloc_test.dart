import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:bbrowser/blocs/navigation/navigation_bloc.dart';
import 'package:bbrowser/blocs/navigation/navigation_event.dart';
import 'package:bbrowser/blocs/navigation/navigation_state.dart';

void main() {
  group('NavigationBloc', () {
    late NavigationBloc navigationBloc;

    setUp(() {
      navigationBloc = NavigationBloc();
    });

    tearDown(() {
      navigationBloc.close();
    });

    test('initial state is NavigationInitial', () {
      expect(navigationBloc.state, equals(const NavigationInitial()));
    });

    group('NavigationStarted', () {
      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationLoading when NavigationStarted is added',
        build: () => navigationBloc,
        act: (bloc) => bloc.add(const NavigationStarted(
          tabId: 'test_tab',
          url: 'https://example.com',
        )),
        expect: () => [
          const NavigationLoading(
            url: 'https://example.com',
            tabId: 'test_tab',
            progress: 0.0,
          ),
        ],
      );
    });

    group('NavigationCompleted', () {
      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationLoaded when NavigationCompleted is added',
        build: () => navigationBloc,
        act: (bloc) => bloc.add(const NavigationCompleted(
          tabId: 'test_tab',
          url: 'https://example.com',
          title: 'Example Page',
        )),
        expect: () => [
          const NavigationLoaded(
            currentUrl: 'https://example.com',
            tabId: 'test_tab',
            title: 'Example Page',
            canGoBack: false,
            canGoForward: false,
            isSecure: true,
          ),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'updates navigation history when NavigationCompleted is added',
        build: () => navigationBloc,
        act: (bloc) {
          bloc.add(const NavigationCompleted(
            tabId: 'test_tab',
            url: 'https://example.com',
            title: 'Example Page',
          ));
          bloc.add(const NavigationCompleted(
            tabId: 'test_tab',
            url: 'https://google.com',
            title: 'Google',
          ));
        },
        expect: () => [
          const NavigationLoaded(
            currentUrl: 'https://example.com',
            tabId: 'test_tab',
            title: 'Example Page',
            canGoBack: false,
            canGoForward: false,
            isSecure: true,
          ),
          const NavigationLoaded(
            currentUrl: 'https://google.com',
            tabId: 'test_tab',
            title: 'Google',
            canGoBack: true,
            canGoForward: false,
            isSecure: true,
          ),
        ],
      );
    });

    group('NavigationFailed', () {
      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationError when NavigationFailed is added',
        build: () => navigationBloc,
        act: (bloc) => bloc.add(const NavigationFailed(
          tabId: 'test_tab',
          url: 'https://invalid-url.com',
          error: 'Network error',
        )),
        expect: () => [
          const NavigationError(
            message: 'Network error',
            url: 'https://invalid-url.com',
            tabId: 'test_tab',
            isRecoverable: true,
          ),
        ],
      );
    });

    group('Navigation History', () {
      blocTest<NavigationBloc, NavigationState>(
        'handles back navigation correctly',
        build: () => navigationBloc,
        act: (bloc) {
          // Navigate to first page
          bloc.add(const NavigationCompleted(
            tabId: 'test_tab',
            url: 'https://example.com',
            title: 'Example',
          ));
          // Navigate to second page
          bloc.add(const NavigationCompleted(
            tabId: 'test_tab',
            url: 'https://google.com',
            title: 'Google',
          ));
          // Go back
          bloc.add(const NavigationBackRequested(tabId: 'test_tab'));
        },
        expect: () => [
          const NavigationLoaded(
            currentUrl: 'https://example.com',
            tabId: 'test_tab',
            title: 'Example',
            canGoBack: false,
            canGoForward: false,
            isSecure: true,
          ),
          const NavigationLoaded(
            currentUrl: 'https://google.com',
            tabId: 'test_tab',
            title: 'Google',
            canGoBack: true,
            canGoForward: false,
            isSecure: true,
          ),
          const NavigationLoading(
            url: 'https://example.com',
            tabId: 'test_tab',
            progress: 0.0,
          ),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'handles forward navigation correctly',
        build: () => navigationBloc,
        seed: () => const NavigationLoaded(
          currentUrl: 'https://example.com',
          tabId: 'test_tab',
          title: 'Example',
          canGoBack: false,
          canGoForward: true,
          isSecure: true,
        ),
        act: (bloc) {
          // Set up history manually for this test
          bloc.add(const NavigationCompleted(
            tabId: 'test_tab',
            url: 'https://example.com',
            title: 'Example',
          ));
          bloc.add(const NavigationCompleted(
            tabId: 'test_tab',
            url: 'https://google.com',
            title: 'Google',
          ));
          bloc.add(const NavigationBackRequested(tabId: 'test_tab'));
          bloc.add(const NavigationForwardRequested(tabId: 'test_tab'));
        },
        skip: 1, // Skip the seed state
        expect: () => [
          const NavigationLoaded(
            currentUrl: 'https://example.com',
            tabId: 'test_tab',
            title: 'Example',
            canGoBack: false,
            canGoForward: false,
            isSecure: true,
          ),
          const NavigationLoaded(
            currentUrl: 'https://google.com',
            tabId: 'test_tab',
            title: 'Google',
            canGoBack: true,
            canGoForward: false,
            isSecure: true,
          ),
          const NavigationLoading(
            url: 'https://example.com',
            tabId: 'test_tab',
            progress: 0.0,
          ),
          const NavigationLoading(
            url: 'https://google.com',
            tabId: 'test_tab',
            progress: 0.0,
          ),
        ],
      );

      test('tracks navigation history correctly', () {
        const tabId = 'test_tab';
        
        // Add some navigation history
        navigationBloc.add(const NavigationCompleted(
          tabId: tabId,
          url: 'https://example.com',
          title: 'Example',
        ));
        
        // Wait for the event to be processed
        expectLater(
          navigationBloc.stream,
          emitsInOrder([
            const NavigationLoaded(
              currentUrl: 'https://example.com',
              tabId: tabId,
              title: 'Example',
              canGoBack: false,
              canGoForward: false,
              isSecure: true,
            ),
          ]),
        );
        
        // Check navigation capabilities
        expect(navigationBloc.canGoBack(tabId), isFalse);
        expect(navigationBloc.canGoForward(tabId), isFalse);
      });
    });

    group('NavigationReloadRequested', () {
      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationLoading when reload is requested',
        build: () => navigationBloc,
        seed: () => const NavigationLoaded(
          currentUrl: 'https://example.com',
          tabId: 'test_tab',
          title: 'Example',
          canGoBack: false,
          canGoForward: false,
          isSecure: true,
        ),
        act: (bloc) => bloc.add(const NavigationReloadRequested(tabId: 'test_tab')),
        expect: () => [
          const NavigationLoading(
            url: 'https://example.com',
            tabId: 'test_tab',
            progress: 0.0,
          ),
        ],
      );
    });

    group('NavigationUrlChanged', () {
      blocTest<NavigationBloc, NavigationState>(
        'updates URL when NavigationUrlChanged is added',
        build: () => navigationBloc,
        seed: () => const NavigationLoaded(
          currentUrl: 'https://example.com',
          tabId: 'test_tab',
          title: 'Example',
          canGoBack: false,
          canGoForward: false,
          isSecure: true,
        ),
        act: (bloc) => bloc.add(const NavigationUrlChanged(
          tabId: 'test_tab',
          url: 'https://google.com',
        )),
        expect: () => [
          const NavigationLoaded(
            currentUrl: 'https://google.com',
            tabId: 'test_tab',
            title: 'Example',
            canGoBack: false,
            canGoForward: false,
            isSecure: true,
          ),
        ],
      );
    });

    group('NavigationTitleChanged', () {
      blocTest<NavigationBloc, NavigationState>(
        'updates title when NavigationTitleChanged is added',
        build: () => navigationBloc,
        seed: () => const NavigationLoaded(
          currentUrl: 'https://example.com',
          tabId: 'test_tab',
          title: 'Example',
          canGoBack: false,
          canGoForward: false,
          isSecure: true,
        ),
        act: (bloc) => bloc.add(const NavigationTitleChanged(
          tabId: 'test_tab',
          title: 'New Title',
        )),
        expect: () => [
          const NavigationLoaded(
            currentUrl: 'https://example.com',
            tabId: 'test_tab',
            title: 'New Title',
            canGoBack: false,
            canGoForward: false,
            isSecure: true,
          ),
        ],
      );
    });

    group('NavigationProgressChanged', () {
      blocTest<NavigationBloc, NavigationState>(
        'updates progress when NavigationProgressChanged is added',
        build: () => navigationBloc,
        seed: () => const NavigationLoading(
          url: 'https://example.com',
          tabId: 'test_tab',
          progress: 0.0,
        ),
        act: (bloc) => bloc.add(const NavigationProgressChanged(
          tabId: 'test_tab',
          progress: 0.5,
        )),
        expect: () => [
          const NavigationLoading(
            url: 'https://example.com',
            tabId: 'test_tab',
            progress: 0.5,
          ),
        ],
      );
    });

    group('NavigationHistoryCleared', () {
      blocTest<NavigationBloc, NavigationState>(
        'clears navigation history when NavigationHistoryCleared is added',
        build: () => navigationBloc,
        seed: () => const NavigationLoaded(
          currentUrl: 'https://example.com',
          tabId: 'test_tab',
          title: 'Example',
          canGoBack: true,
          canGoForward: false,
          isSecure: true,
        ),
        act: (bloc) => bloc.add(const NavigationHistoryCleared(tabId: 'test_tab')),
        expect: () => [
          const NavigationLoaded(
            currentUrl: 'https://example.com',
            tabId: 'test_tab',
            title: 'Example',
            canGoBack: false,
            canGoForward: false,
            isSecure: true,
          ),
        ],
      );
    });

    group('NavigationTabClosed', () {
      blocTest<NavigationBloc, NavigationState>(
        'resets to initial state when active tab is closed',
        build: () => navigationBloc,
        seed: () => const NavigationLoaded(
          currentUrl: 'https://example.com',
          tabId: 'test_tab',
          title: 'Example',
          canGoBack: false,
          canGoForward: false,
          isSecure: true,
        ),
        act: (bloc) => bloc.add(const NavigationTabClosed(tabId: 'test_tab')),
        expect: () => [
          const NavigationInitial(),
        ],
      );
    });

    group('Multiple Tabs', () {
      test('handles multiple tabs independently', () {
        const tab1 = 'tab1';
        const tab2 = 'tab2';
        
        // Navigate in tab1
        navigationBloc.add(const NavigationCompleted(
          tabId: tab1,
          url: 'https://example.com',
          title: 'Example',
        ));
        
        // Navigate in tab2
        navigationBloc.add(const NavigationCompleted(
          tabId: tab2,
          url: 'https://google.com',
          title: 'Google',
        ));
        
        // Check that histories are independent
        expect(navigationBloc.getNavigationHistory(tab1), isNotEmpty);
        expect(navigationBloc.getNavigationHistory(tab2), isNotEmpty);
        expect(navigationBloc.getNavigationHistory(tab1), 
               isNot(equals(navigationBloc.getNavigationHistory(tab2))));
      });
    });

    group('Security Detection', () {
      test('correctly identifies secure URLs', () {
        navigationBloc.add(const NavigationCompleted(
          tabId: 'test_tab',
          url: 'https://secure-site.com',
          title: 'Secure Site',
        ));
        
        expectLater(
          navigationBloc.stream,
          emitsInOrder([
            const NavigationLoaded(
              currentUrl: 'https://secure-site.com',
              tabId: 'test_tab',
              title: 'Secure Site',
              canGoBack: false,
              canGoForward: false,
              isSecure: true,
            ),
          ]),
        );
      });

      test('correctly identifies insecure URLs', () {
        navigationBloc.add(const NavigationCompleted(
          tabId: 'test_tab',
          url: 'http://insecure-site.com',
          title: 'Insecure Site',
        ));
        
        expectLater(
          navigationBloc.stream,
          emitsInOrder([
            const NavigationLoaded(
              currentUrl: 'http://insecure-site.com',
              tabId: 'test_tab',
              title: 'Insecure Site',
              canGoBack: false,
              canGoForward: false,
              isSecure: false,
            ),
          ]),
        );
      });
    });
  });
}
