import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    as inapp_webview;

import '../services/webview_renderer_service.dart';

/// Alternative WebView widget that supports multiple rendering engines
class AlternativeWebView extends StatefulWidget {
  final String initialUrl;
  final WebViewRendererPreferences preferences;
  final Function(dynamic controller)? onWebViewCreated;
  final Function(String url)? onPageStarted;
  final Function(String url)? onPageFinished;
  final Function(dynamic error)? onWebResourceError;
  final Function(dynamic controller)? onControllerCreated;

  const AlternativeWebView({
    super.key,
    required this.initialUrl,
    this.preferences = const WebViewRendererPreferences(),
    this.onWebViewCreated,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    this.onControllerCreated,
  });

  @override
  State<AlternativeWebView> createState() => _AlternativeWebViewState();
}

class _AlternativeWebViewState extends State<AlternativeWebView> {
  late final BaseWebViewRenderer _selectedRenderer;
  late final dynamic _controller;
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  void _initializeRenderer() {
    // Get the effective renderer based on preferences
    final rendererId = widget.preferences.getEffectiveRendererId();
    _selectedRenderer = WebViewRendererFactory.getRendererById(rendererId) ??
        WebViewRendererFactory.getRecommendedRenderer();

    // Create appropriate controller based on renderer
    _createWebViewController();
  }

  void _createWebViewController() {
    switch (_selectedRenderer.rendererId) {
      case 'webkit':
        _controller = _createWebKitController();
        break;
      case 'android_webview':
        _controller = _createAndroidWebViewController();
        break;
      case 'inapp_webview':
        // InAppWebView doesn't use the same controller interface
        _initializeInAppWebView();
        return;
      default:
        throw UnsupportedError(
            'Unsupported renderer: ${_selectedRenderer.rendererId}');
    }

    // Setup common callbacks
    widget.onControllerCreated?.call(_controller);
  }

  webview_flutter.WebViewController _createWebKitController() {
    late final webview_flutter.PlatformWebViewControllerCreationParams params;
    if (webview_flutter.WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {},
      );
    } else {
      params = const webview_flutter.PlatformWebViewControllerCreationParams();
    }

    final controller =
        webview_flutter.WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        webview_flutter.NavigationDelegate(
          onProgress: (int progress) {
            // Handle progress updates if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            widget.onPageStarted?.call(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            widget.onPageFinished?.call(url);
          },
          onWebResourceError: (webview_flutter.WebResourceError error) {
            widget.onWebResourceError?.call(error);
          },
        ),
      );

    controller.loadRequest(Uri.parse(widget.initialUrl));

    // Platform-specific setup
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
    } else if (controller.platform is WebKitWebViewController) {
      // WebKit specific setup
    }

    return controller;
  }

  webview_flutter.WebViewController _createAndroidWebViewController() {
    const params = webview_flutter.PlatformWebViewControllerCreationParams();
    final controller =
        webview_flutter.WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        webview_flutter.NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            widget.onPageStarted?.call(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            widget.onPageFinished?.call(url);
          },
          onWebResourceError: (webview_flutter.WebResourceError error) {
            widget.onWebResourceError?.call(error);
          },
        ),
      );

    controller.loadRequest(Uri.parse(widget.initialUrl));
    return controller;
  }

  void _initializeInAppWebView() {
    // InAppWebView uses a different widget approach
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRenderer.rendererId == 'inapp_webview') {
      return _buildInAppWebView();
    }

    return Stack(
      children: [
        // WebView content
        if (_controller != null)
          webview_flutter.WebViewWidget(controller: _controller)
        else
          const Center(child: CircularProgressIndicator()),

        // Loading indicator
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ProgressCircle(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading ${_currentUrl ?? widget.initialUrl}...',
                      style: MacosTheme.of(context).typography.body,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInAppWebView() {
    return inapp_webview.InAppWebView(
      initialUrlRequest: inapp_webview.URLRequest(
        url: inapp_webview.WebUri(widget.initialUrl),
      ),
      initialSettings: inapp_webview.InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (inapp_webview.InAppWebViewController controller) {
        widget.onWebViewCreated?.call(controller);
      },
      onLoadStart: (controller, url) {
        setState(() {
          _isLoading = true;
          _currentUrl = url.toString();
        });
        widget.onPageStarted?.call(url.toString());
      },
      onLoadStop: (controller, url) {
        setState(() {
          _isLoading = false;
          _currentUrl = url.toString();
        });
        widget.onPageFinished?.call(url.toString());
      },
      onReceivedError: (controller, request, error) {
        widget.onWebResourceError?.call(error);
      },
    );
  }
}

/// Demo widget for testing different renderers
class WebViewRendererDemo extends StatelessWidget {
  final String testUrl;

  const WebViewRendererDemo({
    super.key,
    this.testUrl = 'https://example.com',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WebView Renderer Demo',
            style: MacosTheme.of(context).typography.title2,
          ),
          const SizedBox(height: 16),
          Text(
            'Test different WebView renderers with any URL:',
            style: MacosTheme.of(context).typography.body,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MacosTextField(
                  placeholder: 'Enter URL to test',
                  controller: TextEditingController(text: testUrl),
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () {
                  // Open demo in new window or refresh
                },
                child: const Text('Test'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Available Renderers:',
            style: MacosTheme.of(context).typography.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...WebViewRendererFactory.getAvailableRenderers().map(
            (renderer) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  MacosCheckbox(
                    value: renderer.rendererId ==
                        WebViewRendererFactory.getRecommendedRenderer()
                            .rendererId,
                    onChanged: (value) {},
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          renderer.rendererName,
                          style: MacosTheme.of(context).typography.body,
                        ),
                        Text(
                          renderer.description,
                          style: MacosTheme.of(context).typography.caption1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
