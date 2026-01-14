import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import '../blocs/tab/tab_bloc.dart';
import '../blocs/tab/tab_state.dart';
import '../blocs/tab/tab_event.dart';
import '../services/webview_renderer_service.dart';
import 'alternative_webview.dart';

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
                return _buildErrorView(
                    context, activeTab.errorMessage ?? 'Unknown error');
              }

              // Use AlternativeWebView with automatic renderer selection
              return AlternativeWebView(
                initialUrl: activeTab.url,
                preferences: const WebViewRendererPreferences(),
                onWebViewCreated: (controller) {
                  // WebView created successfully
                },
                onPageStarted: (url) {
                  // Loading started
                },
                onPageFinished: (url) {
                  // Loading finished
                },
                onWebResourceError: (error) {
                  // Handle WebView error
                },
              );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () => _createNewTab(context),
                child: const Text('New Tab'),
              ),
              const SizedBox(width: 16.0),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () => _openRendererDemo(context),
                child: const Text('Demo'),
              ),
            ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () => _createNewTab(context),
                child: const Text('New Tab'),
              ),
              const SizedBox(width: 16.0),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () => _openRendererDemo(context),
                child: const Text('Demo'),
              ),
            ],
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

  /// Creates a new tab
  void _createNewTab(BuildContext context) {
    context.read<TabBloc>().add(const TabCreated());
  }

  /// Reloads the current page
  void _reloadPage(BuildContext context) {
    context.read<TabBloc>().add(const TabReload());
  }

  /// Opens the WebView renderer demo dialog
  void _openRendererDemo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebView Renderer Demo'),
        content: const SizedBox(
          height: 400,
          width: 600,
          child: WebViewRendererDemo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
