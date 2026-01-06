import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/web_view_controller.dart';
import '../blocs/tab/tab_bloc.dart';
import '../blocs/tab/tab_event.dart';

/// Widget that displays web content using WebView
class BrowserWebViewWidget extends StatefulWidget {
  const BrowserWebViewWidget({
    super.key,
    required this.tabId,
    required this.initialUrl,
    this.onWebViewCreated,
  });

  final String tabId;
  final String initialUrl;
  final VoidCallback? onWebViewCreated;

  @override
  State<BrowserWebViewWidget> createState() => _BrowserWebViewWidgetState();
}

class _BrowserWebViewWidgetState extends State<BrowserWebViewWidget> {
  late final WebViewControllerService _webViewService;
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _webViewService = WebViewControllerService();
    _setupWebViewCallbacks();
    _initializeWebView();
  }

  /// Sets up callbacks for WebView events
  void _setupWebViewCallbacks() {
    _webViewService.onNavigationRequest = (url) {
      _updateTabState(url: url, isLoading: true);
    };

    _webViewService.onLoadingChanged = (isLoading, progress) {
      setState(() {
        _isLoading = isLoading;
      });
      _updateTabState(
        isLoading: isLoading,
        loadingProgress: progress,
      );
    };

    _webViewService.onTitleChanged = (title) {
      _updateTabState(title: title);
    };

    _webViewService.onPageError = (error, url) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
      _updateTabState(
        hasError: true,
        errorMessage: error,
        isLoading: false,
      );
    };
  }

  /// Initializes the WebView controller
  Future<void> _initializeWebView() async {
    try {
      _controller = await _webViewService.createController(widget.tabId);
      
      // Load initial URL if provided
      if (widget.initialUrl.isNotEmpty && widget.initialUrl != 'about:blank') {
        await _webViewService.loadUrl(widget.tabId, widget.initialUrl);
      }

      // Update navigation capabilities
      await _updateNavigationCapabilities();

      widget.onWebViewCreated?.call();
      
      setState(() {
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize WebView: $e';
        _isLoading = false;
      });
      _updateTabState(
        hasError: true,
        errorMessage: _error,
        isLoading: false,
      );
    }
  }

  /// Updates the tab state through the TabBloc
  void _updateTabState({
    String? url,
    String? title,
    bool? isLoading,
    double? loadingProgress,
    bool? hasError,
    String? errorMessage,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    final tabBloc = context.read<TabBloc>();
    tabBloc.add(TabUpdated(
      tabId: widget.tabId,
      url: url,
      title: title,
      isLoading: isLoading,
      loadingProgress: loadingProgress,
      hasError: hasError,
      errorMessage: errorMessage,
      canGoBack: canGoBack,
      canGoForward: canGoForward,
      isSecure: url?.startsWith('https://') ?? false,
    ));
  }

  /// Updates navigation capabilities (back/forward buttons)
  Future<void> _updateNavigationCapabilities() async {
    if (_controller != null) {
      final canGoBack = await _webViewService.canGoBack(widget.tabId);
      final canGoForward = await _webViewService.canGoForward(widget.tabId);
      
      _updateTabState(
        canGoBack: canGoBack,
        canGoForward: canGoForward,
      );
    }
  }

  /// Loads a new URL in the WebView
  Future<void> loadUrl(String url) async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    
    await _webViewService.loadUrl(widget.tabId, url);
    await _updateNavigationCapabilities();
  }

  /// Navigates back in the WebView
  Future<bool> goBack() async {
    final success = await _webViewService.goBack(widget.tabId);
    if (success) {
      await _updateNavigationCapabilities();
    }
    return success;
  }

  /// Navigates forward in the WebView
  Future<bool> goForward() async {
    final success = await _webViewService.goForward(widget.tabId);
    if (success) {
      await _updateNavigationCapabilities();
    }
    return success;
  }

  /// Reloads the current page
  Future<void> reload() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    
    await _webViewService.reload(widget.tabId);
    await _updateNavigationCapabilities();
  }

  /// Gets the current URL
  Future<String?> getCurrentUrl() async {
    return await _webViewService.getCurrentUrl(widget.tabId);
  }

  /// Gets the current title
  Future<String?> getCurrentTitle() async {
    return await _webViewService.getCurrentTitle(widget.tabId);
  }

  /// Executes JavaScript in the WebView
  Future<String?> evaluateJavaScript(String script) async {
    return await _webViewService.evaluateJavaScript(widget.tabId, script);
  }

  @override
  void dispose() {
    _webViewService.disposeController(widget.tabId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorView();
    }

    if (_controller == null) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  /// Builds the loading view
  Widget _buildLoadingView() {
    return Container(
      color: MacosTheme.of(context).canvasColor,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProgressCircle(),
            SizedBox(height: 16.0),
            Text('Initializing WebView...'),
          ],
        ),
      ),
    );
  }

  /// Builds the error view
  Widget _buildErrorView() {
    return Container(
      color: MacosTheme.of(context).canvasColor,
      child: Center(
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
              'WebView Error',
              style: MacosTheme.of(context).typography.largeTitle,
            ),
            const SizedBox(height: 16.0),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                _error ?? 'Unknown error occurred',
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
                  onPressed: () => _initializeWebView(),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16.0),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () => reload(),
                  child: const Text('Reload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the loading overlay
  Widget _buildLoadingOverlay() {
    return Container(
      color: MacosTheme.of(context).canvasColor.withOpacity(0.8),
      child: const Center(
        child: ProgressCircle(),
      ),
    );
  }
}

/// Extension to provide WebView functionality to other widgets
extension BrowserWebViewWidgetController on GlobalKey<_BrowserWebViewWidgetState> {
  /// Loads a URL in the WebView
  Future<void> loadUrl(String url) async {
    await currentState?.loadUrl(url);
  }

  /// Navigates back in the WebView
  Future<bool> goBack() async {
    return await currentState?.goBack() ?? false;
  }

  /// Navigates forward in the WebView
  Future<bool> goForward() async {
    return await currentState?.goForward() ?? false;
  }

  /// Reloads the current page
  Future<void> reload() async {
    await currentState?.reload();
  }

  /// Gets the current URL
  Future<String?> getCurrentUrl() async {
    return await currentState?.getCurrentUrl();
  }

  /// Gets the current title
  Future<String?> getCurrentTitle() async {
    return await currentState?.getCurrentTitle();
  }

  /// Executes JavaScript in the WebView
  Future<String?> evaluateJavaScript(String script) async {
    return await currentState?.evaluateJavaScript(script);
  }
}
