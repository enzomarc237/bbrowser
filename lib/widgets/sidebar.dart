import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import '../blocs/tab/tab_bloc.dart';
import '../blocs/tab/tab_event.dart';
import '../blocs/tab/tab_state.dart';
import 'tab_list_item.dart';

/// Sidebar widget for tab management
class TabSidebar extends StatelessWidget {
  const TabSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      builder: (context, state) {
        return Column(
          children: [
            // Sidebar header with new tab button
            _buildSidebarHeader(context),
            
            // Tabs list
            Expanded(
              child: _buildTabsList(context, state, null),
            ),
            
            // Sidebar footer (optional)
            _buildSidebarFooter(context, state),
          ],
        );
      },
    );
  }

  /// Builds the sidebar header with new tab button
  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MacosTheme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Tabs',
            style: MacosTheme.of(context).typography.headline,
          ),
          const Spacer(),
          MacosIconButton(
            icon: const MacosIcon(
              Icons.add,
              size: 18.0,
            ),
            onPressed: () => _onNewTab(context),
            semanticLabel: 'New tab',
          ),
        ],
      ),
    );
  }

  /// Builds the tabs list
  Widget _buildTabsList(BuildContext context, TabState state, ScrollController? scrollController) {
    if (state is TabLoading) {
      return const Center(
        child: ProgressCircle(),
      );
    }

    if (state is TabError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MacosIcon(
              Icons.error_outline,
              size: 48.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Error loading tabs',
              style: MacosTheme.of(context).typography.headline,
            ),
            const SizedBox(height: 8.0),
            Text(
              state.message,
              style: MacosTheme.of(context).typography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            PushButton(
              controlSize: ControlSize.small,
              onPressed: () => _onNewTab(context),
              child: const Text('New Tab'),
            ),
          ],
        ),
      );
    }

    if (state is TabLoaded) {
      if (state.tabs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MacosIcon(
                Icons.tab,
                size: 48.0,
              ),
              const SizedBox(height: 16.0),
              Text(
                'No tabs open',
                style: MacosTheme.of(context).typography.headline,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Create a new tab to get started',
                style: MacosTheme.of(context).typography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              PushButton(
                controlSize: ControlSize.small,
                onPressed: () => _onNewTab(context),
                child: const Text('New Tab'),
              ),
            ],
          ),
        );
      }

      return ReorderableListView.builder(
        scrollController: scrollController,
        itemCount: state.tabs.length,
        onReorder: (oldIndex, newIndex) => _onReorderTabs(context, oldIndex, newIndex),
        itemBuilder: (context, index) {
          final tab = state.tabs[index];
          final isActive = tab.id == state.activeTabId;

          return TabListItem(
            key: ValueKey(tab.id),
            tab: tab,
            isActive: isActive,
            onTap: () => _onSelectTab(context, tab.id),
            onClose: () => _onCloseTab(context, tab.id),
            onDuplicate: () => _onDuplicateTab(context, tab.id),
          );
        },
      );
    }

    // Initial state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(
            Icons.web,
            size: 48.0,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Welcome to Browser',
            style: MacosTheme.of(context).typography.headline,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Create your first tab to start browsing',
            style: MacosTheme.of(context).typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          PushButton(
            controlSize: ControlSize.small,
            onPressed: () => _onNewTab(context),
            child: const Text('New Tab'),
          ),
        ],
      ),
    );
  }

  /// Builds the sidebar footer
  Widget _buildSidebarFooter(BuildContext context, TabState state) {
    if (state is! TabLoaded || state.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: MacosTheme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${state.tabs.length} tab${state.tabs.length == 1 ? '' : 's'}',
            style: MacosTheme.of(context).typography.caption1,
          ),
          const Spacer(),
          if (state.tabs.length > 1) ...[
            MacosIconButton(
              icon: const MacosIcon(
                Icons.clear_all,
                size: 16.0,
              ),
              onPressed: () => _onCloseAllTabs(context),
              semanticLabel: 'Close all tabs',
            ),
          ],
        ],
      ),
    );
  }

  /// Handles creating a new tab
  void _onNewTab(BuildContext context) {
    context.read<TabBloc>().add(const TabCreated());
  }

  /// Handles selecting a tab
  void _onSelectTab(BuildContext context, String tabId) {
    context.read<TabBloc>().add(TabSelected(tabId));
  }

  /// Handles closing a tab
  void _onCloseTab(BuildContext context, String tabId) {
    context.read<TabBloc>().add(TabClosed(tabId));
  }

  /// Handles duplicating a tab
  void _onDuplicateTab(BuildContext context, String tabId) {
    context.read<TabBloc>().add(TabDuplicated(tabId));
  }

  /// Handles reordering tabs
  void _onReorderTabs(BuildContext context, int oldIndex, int newIndex) {
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    context.read<TabBloc>().add(TabsReordered(
      oldIndex: oldIndex,
      newIndex: newIndex,
    ));
  }

  /// Handles closing all tabs
  void _onCloseAllTabs(BuildContext context) {
    context.read<TabBloc>().add(const TabsCleared());
  }
}
