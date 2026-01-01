import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:bbrowser/blocs/tab/tab_bloc.dart';
import 'package:bbrowser/blocs/tab/tab_event.dart';
import 'package:bbrowser/blocs/tab/tab_state.dart';
import 'package:bbrowser/models/tab.dart';

void main() {
  group('TabBloc', () {
    late TabBloc tabBloc;

    setUp(() {
      tabBloc = TabBloc();
    });

    tearDown(() {
      tabBloc.close();
    });

    test('initial state is TabInitial', () {
      expect(tabBloc.state, equals(const TabInitial()));
    });

    group('TabCreated', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with new tab when first tab is created',
        build: () => tabBloc,
        act: (bloc) => bloc.add(const TabCreated(
          url: 'https://example.com',
          title: 'Example',
        )),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.length, 'tabs length', 1)
              .having((state) => state.tabs.first.url, 'first tab url', 'https://example.com')
              .having((state) => state.tabs.first.title, 'first tab title', 'Example')
              .having((state) => state.activeTabId, 'active tab id', isNotNull),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabLoaded with additional tab when tab is added to existing tabs',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabCreated(
          url: 'https://second.com',
          title: 'Second',
        )),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.length, 'tabs length', 2)
              .having((state) => state.tabs.last.url, 'last tab url', 'https://second.com')
              .having((state) => state.tabs.last.title, 'last tab title', 'Second'),
        ],
      );

      blocTest<TabBloc, TabState>(
        'creates tab without making it active when makeActive is false',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabCreated(
          url: 'https://second.com',
          title: 'Second',
          makeActive: false,
        )),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.length, 'tabs length', 2)
              .having((state) => state.activeTabId, 'active tab id', 'tab1'),
        ],
      );
    });

    group('TabSelected', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with updated active tab when valid tab is selected',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [
            Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First'),
            Tab.newTab(id: 'tab2', url: 'https://second.com', title: 'Second'),
          ],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabSelected('tab2')),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.activeTabId, 'active tab id', 'tab2'),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabError when trying to select non-existent tab',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabSelected('non-existent')),
        expect: () => [
          isA<TabError>()
              .having((state) => state.message, 'error message', contains('Tab not found')),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabError when no tabs are available',
        build: () => tabBloc,
        act: (bloc) => bloc.add(const TabSelected('tab1')),
        expect: () => [
          isA<TabError>()
              .having((state) => state.message, 'error message', contains('No tabs available')),
        ],
      );
    });

    group('TabClosed', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with remaining tabs when tab is closed',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [
            Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First'),
            Tab.newTab(id: 'tab2', url: 'https://second.com', title: 'Second'),
          ],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabClosed('tab2')),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.length, 'tabs length', 1)
              .having((state) => state.tabs.first.id, 'remaining tab id', 'tab1'),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabInitial when last tab is closed',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabClosed('tab1')),
        expect: () => [
          const TabInitial(),
        ],
      );

      blocTest<TabBloc, TabState>(
        'selects previous tab when active tab is closed',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [
            Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First'),
            Tab.newTab(id: 'tab2', url: 'https://second.com', title: 'Second'),
            Tab.newTab(id: 'tab3', url: 'https://third.com', title: 'Third'),
          ],
          activeTabId: 'tab2',
        ),
        act: (bloc) => bloc.add(const TabClosed('tab2')),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.length, 'tabs length', 2)
              .having((state) => state.activeTabId, 'active tab id', 'tab1'),
        ],
      );
    });

    group('TabUpdated', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with updated tab information',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabUpdated(
          tabId: 'tab1',
          title: 'Updated Title',
          url: 'https://updated.com',
          isLoading: true,
          loadingProgress: 0.5,
        )),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.first.title, 'updated title', 'Updated Title')
              .having((state) => state.tabs.first.url, 'updated url', 'https://updated.com')
              .having((state) => state.tabs.first.isLoading, 'is loading', true)
              .having((state) => state.tabs.first.loadingProgress, 'loading progress', 0.5),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabError when trying to update non-existent tab',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabUpdated(
          tabId: 'non-existent',
          title: 'Updated Title',
        )),
        expect: () => [
          isA<TabError>()
              .having((state) => state.message, 'error message', contains('Tab not found')),
        ],
      );
    });

    group('TabsReordered', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with reordered tabs',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [
            Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First'),
            Tab.newTab(id: 'tab2', url: 'https://second.com', title: 'Second'),
            Tab.newTab(id: 'tab3', url: 'https://third.com', title: 'Third'),
          ],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabsReordered(oldIndex: 0, newIndex: 2)),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs[0].id, 'first tab id', 'tab2')
              .having((state) => state.tabs[1].id, 'second tab id', 'tab3')
              .having((state) => state.tabs[2].id, 'third tab id', 'tab1'),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabError when reorder indices are invalid',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabsReordered(oldIndex: 0, newIndex: 5)),
        expect: () => [
          isA<TabError>()
              .having((state) => state.message, 'error message', contains('Invalid tab indices')),
        ],
      );
    });

    group('TabNavigateToUrl', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with updated active tab URL and loading state',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabNavigateToUrl('https://new-url.com')),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.activeTab?.url, 'active tab url', 'https://new-url.com')
              .having((state) => state.activeTab?.isLoading, 'is loading', true)
              .having((state) => state.activeTab?.isSecure, 'is secure', true),
        ],
      );

      blocTest<TabBloc, TabState>(
        'sets isSecure to false for HTTP URLs',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabNavigateToUrl('http://insecure.com')),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.activeTab?.isSecure, 'is secure', false),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabError when no active tab is available',
        build: () => tabBloc,
        act: (bloc) => bloc.add(const TabNavigateToUrl('https://example.com')),
        expect: () => [
          isA<TabError>()
              .having((state) => state.message, 'error message', contains('No active tab')),
        ],
      );
    });

    group('TabsRestored', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with restored tabs',
        build: () => tabBloc,
        act: (bloc) => bloc.add(TabsRestored([
          Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First'),
          Tab.newTab(id: 'tab2', url: 'https://second.com', title: 'Second'),
        ])),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.length, 'tabs length', 2)
              .having((state) => state.isSessionRestored, 'is session restored', true)
              .having((state) => state.activeTabId, 'active tab id', 'tab1'),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabInitial when empty tabs list is restored',
        build: () => tabBloc,
        act: (bloc) => bloc.add(const TabsRestored([])),
        expect: () => [
          const TabInitial(),
        ],
      );
    });

    group('TabsCleared', () {
      blocTest<TabBloc, TabState>(
        'emits TabInitial when tabs are cleared',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [
            Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First'),
            Tab.newTab(id: 'tab2', url: 'https://second.com', title: 'Second'),
          ],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabsCleared()),
        expect: () => [
          const TabInitial(),
        ],
      );
    });

    group('TabDuplicated', () {
      blocTest<TabBloc, TabState>(
        'emits TabLoaded with duplicated tab',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabDuplicated('tab1')),
        expect: () => [
          isA<TabLoaded>()
              .having((state) => state.tabs.length, 'tabs length', 2)
              .having((state) => state.tabs.last.url, 'duplicated tab url', 'https://first.com')
              .having((state) => state.tabs.last.title, 'duplicated tab title', 'First'),
        ],
      );

      blocTest<TabBloc, TabState>(
        'emits TabError when trying to duplicate non-existent tab',
        build: () => tabBloc,
        seed: () => TabLoaded(
          tabs: [Tab.newTab(id: 'tab1', url: 'https://first.com', title: 'First')],
          activeTabId: 'tab1',
        ),
        act: (bloc) => bloc.add(const TabDuplicated('non-existent')),
        expect: () => [
          isA<TabError>()
              .having((state) => state.message, 'error message', contains('Tab not found')),
        ],
      );
    });
  });
}
