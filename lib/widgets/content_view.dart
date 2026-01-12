import 'package:flutter/material.dart';
import 'package.flutter_bloc/flutter_bloc.dart';
import 'package.macos_ui/macos_ui.dart';
import 'package.webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../blocs/tab/tab_bloc.dart';
import '../blocs/tab/tab_state.dart';
import '../blocs/tab/tab_event.dart';

/// Content view widget that displays the main browser content
class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  final Map<String, WebViewController> _webControllers = {};
  Timer? _titleUpdateTimer;
  StreamSubscription<NavigationCommand>? _navigationCommandSubscription;

  @override
  void initState() {
    super.initState();
    _navigationCommandSubscription = context.read<TabBloc>().navigationCommands.listen((command) {
      if (_webControllers.containsKey(command.tabId)) {
        final controller = _webControllers[command.tabId]!;
        if (command is NavigateBackCommand) {
          controller.goBack();
        } else if (command is NavigateForwardCommand) {
          controller.goForward();
        } else if (command is ReloadCommand) {
          controller.reload();
        } else if (command is LoadUrlCommand) {
          controller.loadRequest(Uri.parse(command.url));
        }
      }
    });
  }

  @override
  void dispose() {
    _titleUpdateTimer?.cancel();
    _navigationCommandSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      builder: (context, state) {
        if (state is TabLoaded) {
          final currentTabIds = state.tabs.map((t) => t.id).toSet();
          final controllerIds = _webControllers.keys.toList();

          for (final id in controllerIds) {
            if (!currentTabIds.contains(id)) {
              _webControllers.remove(id);
            }
          }
        }
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
              return _buildWebView(context, state);
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

  Widget _buildWebView(BuildContext context, TabLoaded state) {
    final activeTab = state.activeTab!;
    _getOrCreateWebViewController(activeTab.id, context);

    return IndexedStack(
      index: state.tabs.indexWhere((tab) => tab.id == activeTab.id),
      children: state.tabs.map((tab) {
        final webViewController = _getOrCreateWebViewController(tab.id, context);
        return WebViewWidget(controller: webViewController);
      }).toList(),
    );
  }

  WebViewController _getOrCreateWebViewController(String tabId, BuildContext context) {
    if (_webControllers.containsKey(tabId)) {
      return _webControllers[tabId]!;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            context.read<TabBloc>().add(TabUpdated(
              tabId: tabId,
              isLoading: true,
              url: url,
            ));
          },
          onPageFinished: (String url) async {
            final title = await _webControllers[tabId]?.getTitle() ?? '';
            context.read<TabBloc>().add(TabUpdated(
              tabId: tabId,
              isLoading: false,
              title: title,
              canGoBack: await _webControllers[tabId]?.canGoBack(),
              canGoForward: await _webControllers[tabId]?.canGoForward(),
            ));
          },
          onWebResourceError: (WebResourceError error) {
            context.read<TabBloc>().add(TabUpdated(
              tabId: tabId,
              hasError: true,
              errorMessage: error.description,
            ));
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              context.read<TabBloc>().add(TabUrlUpdated(tabId: tabId, url: change.url!));
              _debounceTitleUpdate(tabId);
            }
          },
        ),
      );

    _webControllers[tabId] = controller;

    final initialUrl = context.read<TabBloc>().state.tabs.firstWhere((tab) => tab.id == tabId).url;
    controller.loadRequest(Uri.parse(initialUrl));

    return controller;
  }

  void _debounceTitleUpdate(String tabId) {
    _titleUpdateTimer?.cancel();
    _titleUpdateTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_webControllers.containsKey(tabId)) {
        final controller = _webControllers[tabId]!;
        final title = await controller.getTitle() ?? '';
        if (mounted) {
          context.read<TabBloc>().add(TabTitleUpdated(tabId: tabId, title: title));
        }
      }
    });
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
