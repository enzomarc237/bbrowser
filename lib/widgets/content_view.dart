import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import '../blocs/tab/tab_bloc.dart';
import '../blocs/tab/tab_state.dart';
import '../blocs/tab/tab_event.dart';

/// Content view widget that displays the main browser content
class ContentView extends StatelessWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      builder: (context, state) {
        return ContentArea(
          builder: (context, scrollController) {
            if (state is TabLoading) {
              return const Center(
                child: ProgressCircle(),
              );
            }

            if (state is TabError) {
              return _buildErrorView(context, state.message);
            }

            if (state is TabLoaded) {
              final activeTab = state.activeTab;
              
              if (activeTab == null) {
                return _buildNoTabView(context);
              }

              if (activeTab.hasError) {
                return _buildErrorView(context, activeTab.errorMessage ?? 'Unknown error');
              }

              // For now, show a placeholder until WebView is integrated
              return _buildWebContentPlaceholder(context, activeTab.url, activeTab.title);
            }

            // Initial state
            return _buildWelcomeView(context);
          },
        );
      },
    );
  }

  /// Builds the welcome view for initial state
  Widget _buildWelcomeView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(
            Icons.web,
            size: 64.0,
          ),
          const SizedBox(height: 24.0),
          Text(
            'Welcome to Browser',
            style: MacosTheme.of(context).typography.largeTitle,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Create a new tab to start browsing the web',
            style: MacosTheme.of(context).typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          PushButton(
            controlSize: ControlSize.large,
            onPressed: () => _createNewTab(context),
            child: const Text('New Tab'),
          ),
        ],
      ),
    );
  }

  /// Builds the no tab view
  Widget _buildNoTabView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(
            Icons.tab,
            size: 64.0,
          ),
          const SizedBox(height: 24.0),
          Text(
            'No Tab Selected',
            style: MacosTheme.of(context).typography.largeTitle,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Select a tab from the sidebar or create a new one',
            style: MacosTheme.of(context).typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),
          PushButton(
            controlSize: ControlSize.large,
            onPressed: () => _createNewTab(context),
            child: const Text('New Tab'),
          ),
        ],
      ),
    );
  }

  /// Builds the error view
  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MacosIcon(
            Icons.error_outline,
            size: 64.0,
            color: MacosColors.systemRedColor,
          ),
          const SizedBox(height: 24.0),
          Text(
            'Error Loading Page',
            style: MacosTheme.of(context).typography.largeTitle,
          ),
          const SizedBox(height: 16.0),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              message,
              style: MacosTheme.of(context).typography.body,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () => _reloadPage(context),
                child: const Text('Reload'),
              ),
              const SizedBox(width: 16.0),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () => _createNewTab(context),
                child: const Text('New Tab'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a placeholder for web content (until WebView is integrated)
  Widget _buildWebContentPlaceholder(BuildContext context, String url, String title) {
    return Container(
      color: MacosTheme.of(context).canvasColor,
      child: Column(
        children: [
          // Placeholder header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: MacosTheme.of(context).canvasColor,
              border: Border(
                bottom: BorderSide(
                  color: MacosTheme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                const MacosIcon(
                  Icons.language,
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty ? title : 'Loading...',
                        style: MacosTheme.of(context).typography.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (url.isNotEmpty && url != 'about:blank') ...[
                        const SizedBox(height: 4.0),
                        Text(
                          url,
                          style: MacosTheme.of(context).typography.caption1.copyWith(
                            color: MacosColors.secondaryLabelColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Placeholder content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MacosIcon(
                    Icons.web_asset,
                    size: 48.0,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'WebView Integration Coming Soon',
                    style: MacosTheme.of(context).typography.headline,
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'This is a placeholder for web content. WebView integration will be implemented in the next phase.',
                      style: MacosTheme.of(context).typography.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (url.isNotEmpty && url != 'about:blank') ...[
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: MacosTheme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'URL: $url',
                        style: MacosTheme.of(context).typography.caption1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a new tab
  void _createNewTab(BuildContext context) {
    context.read<TabBloc>().add(const TabCreated());
  }

  /// Reloads the current page
  void _reloadPage(BuildContext context) {
    context.read<TabBloc>().add(const TabReload());
  }
}
