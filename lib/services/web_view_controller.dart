import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Callback for navigation events
typedef NavigationCallback = void Function(String url);

/// Callback for page loading events
typedef LoadingCallback = void Function(bool isLoading, double progress);

/// Callback for page title changes
typedef TitleCallback = void Function(String title);

/// Callback for page errors
typedef ErrorCallback = void Function(String error, String? url);

/// Service class for managing WebView controllers and their lifecycle
class WebViewControllerService {
  final Map<String, WebViewController> _controllers = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  
  // Callbacks
  NavigationCallback? onNavigationRequest;
  LoadingCallback? onLoadingChanged;
  TitleCallback? onTitleChanged;
  ErrorCallback? onPageError;

  /// Creates a new WebView controller for the given tab ID
  Future<WebViewController> createController(String tabId) async {
    // Dispose existing controller if any
    await disposeController(tabId);

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    // Configure the controller
    await _configureController(controller, tabId);
    
    _controllers[tabId] = controller;
    return controller;
  }

  /// Configures a WebView controller with settings and callbacks
  Future<void> _configureController(WebViewController controller, String tabId) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0x00000000));

    // Set up navigation delegate
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          onLoadingChanged?.call(true, progress / 100.0);
        },
        onPageStarted: (String url) {
          onLoadingChanged?.call(true, 0.0);
          onNavigationRequest?.call(url);
        },
        onPageFinished: (String url) {
          onLoadingChanged?.call(false, 1.0);
          _updatePageTitle(controller, tabId);
        },
        onWebResourceError: (WebResourceError error) {
          onPageError?.call(error.description, error.url);
          onLoadingChanged?.call(false, 1.0);
        },
        onNavigationRequest: (NavigationRequest request) {
          // Allow all navigation requests by default
          // Custom filtering can be added here
          return NavigationDecision.navigate;
        },
      ),
    );

    // Configure platform-specific settings
    if (controller.platform is WebKitWebViewController) {
      final webKitController = controller.platform as WebKitWebViewController;
      await webKitController.setAllowsBackForwardNavigationGestures(true);
      
      // Set up additional WebKit-specific configurations
      await webKitController.setInspectable(kDebugMode);
    }
  }

  /// Updates the page title for the given tab
  Future<void> _updatePageTitle(WebViewController controller, String tabId) async {
    try {
      final title = await controller.getTitle();
      if (title != null && title.isNotEmpty) {
        onTitleChanged?.call(title);
      }
    } catch (e) {
      debugPrint('Error getting page title: $e');
    }
  }

  /// Gets the WebView controller for the given tab ID
  WebViewController? getController(String tabId) {
    return _controllers[tabId];
  }

  /// Loads a URL in the WebView for the given tab
  Future<void> loadUrl(String tabId, String url) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        await controller.loadRequest(Uri.parse(url));
      } catch (e) {
        onPageError?.call('Failed to load URL: $e', url);
      }
    }
  }

  /// Navigates back in the WebView for the given tab
  Future<bool> goBack(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      final canGoBack = await controller.canGoBack();
      if (canGoBack) {
        await controller.goBack();
        return true;
      }
    }
    return false;
  }

  /// Navigates forward in the WebView for the given tab
  Future<bool> goForward(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      final canGoForward = await controller.canGoForward();
      if (canGoForward) {
        await controller.goForward();
        return true;
      }
    }
    return false;
  }

  /// Reloads the current page in the WebView for the given tab
  Future<void> reload(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      await controller.reload();
    }
  }

  /// Gets the current URL of the WebView for the given tab
  Future<String?> getCurrentUrl(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        return await controller.currentUrl();
      } catch (e) {
        debugPrint('Error getting current URL: $e');
      }
    }
    return null;
  }

  /// Gets the current title of the WebView for the given tab
  Future<String?> getCurrentTitle(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        return await controller.getTitle();
      } catch (e) {
        debugPrint('Error getting current title: $e');
      }
    }
    return null;
  }

  /// Checks if the WebView can go back for the given tab
  Future<bool> canGoBack(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        return await controller.canGoBack();
      } catch (e) {
        debugPrint('Error checking canGoBack: $e');
      }
    }
    return false;
  }

  /// Checks if the WebView can go forward for the given tab
  Future<bool> canGoForward(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        return await controller.canGoForward();
      } catch (e) {
        debugPrint('Error checking canGoForward: $e');
      }
    }
    return false;
  }

  /// Executes JavaScript in the WebView for the given tab
  Future<String?> evaluateJavaScript(String tabId, String script) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      try {
        final result = await controller.runJavaScriptReturningResult(script);
        return result.toString();
      } catch (e) {
        debugPrint('Error executing JavaScript: $e');
        onPageError?.call('JavaScript execution failed: $e', null);
      }
    }
    return null;
  }

  /// Sets the user agent for the WebView
  Future<void> setUserAgent(String tabId, String userAgent) async {
    final controller = _controllers[tabId];
    if (controller != null && controller.platform is WebKitWebViewController) {
      final webKitController = controller.platform as WebKitWebViewController;
      await webKitController.setUserAgent(userAgent);
    }
  }

  /// Clears the cache for all WebViews
  Future<void> clearCache() async {
    for (final controller in _controllers.values) {
      try {
        await controller.clearCache();
      } catch (e) {
        debugPrint('Error clearing cache: $e');
      }
    }
  }

  /// Clears local storage for all WebViews
  Future<void> clearLocalStorage() async {
    for (final controller in _controllers.values) {
      try {
        await controller.clearLocalStorage();
      } catch (e) {
        debugPrint('Error clearing local storage: $e');
      }
    }
  }

  /// Disposes the WebView controller for the given tab
  Future<void> disposeController(String tabId) async {
    // Cancel any subscriptions
    final subscription = _subscriptions[tabId];
    if (subscription != null) {
      await subscription.cancel();
      _subscriptions.remove(tabId);
    }

    // Remove the controller
    _controllers.remove(tabId);
  }

  /// Disposes all WebView controllers
  Future<void> disposeAll() async {
    final tabIds = List<String>.from(_controllers.keys);
    for (final tabId in tabIds) {
      await disposeController(tabId);
    }
  }

  /// Gets the number of active controllers
  int get activeControllerCount => _controllers.length;

  /// Gets all active tab IDs
  List<String> get activeTabIds => List<String>.from(_controllers.keys);

  /// Checks if a controller exists for the given tab ID
  bool hasController(String tabId) => _controllers.containsKey(tabId);
}
