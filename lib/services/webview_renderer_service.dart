/// Service for managing alternative WebView renderers
/// Provides abstraction layer for different webpage rendering engines
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform types
enum PlatformType {
  web,
  android,
  ios,
  macos,
  windows,
  linux,
  unknown,
}

/// Base interface for all WebView renderers
abstract class BaseWebViewRenderer {
  /// Unique identifier for the renderer
  String get rendererId;

  /// Human-readable name
  String get rendererName;

  /// Description of the renderer
  String get description;

  /// Platform compatibility
  List<PlatformType> get supportedPlatforms;

  /// Check if renderer is available on current platform
  bool isAvailable() {
    return supportedPlatforms.contains(_getCurrentPlatformType());
  }

  /// Get current platform type
  PlatformType _getCurrentPlatformType() {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isMacOS) return PlatformType.macos;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.unknown;
  }
}

/// WebKit-based renderer (WKWebView on iOS/macOS)
class WebKitRenderer extends BaseWebViewRenderer {
  @override
  String get rendererId => 'webkit';

  @override
  String get rendererName => 'WebKit (WKWebView)';

  @override
  String get description =>
      'Native WebKit rendering engine with full JavaScript support';

  @override
  List<PlatformType> get supportedPlatforms => [
        PlatformType.ios,
        PlatformType.macos,
      ];
}

/// Android WebView renderer
class AndroidWebViewRenderer extends BaseWebViewRenderer {
  @override
  String get rendererId => 'android_webview';

  @override
  String get rendererName => 'Android WebView';

  @override
  String get description =>
      'Chromium-based Android WebView with modern features';

  @override
  List<PlatformType> get supportedPlatforms => [
        PlatformType.android,
      ];
}

/// InAppWebView renderer (alternative cross-platform solution)
class InAppWebViewRenderer extends BaseWebViewRenderer {
  @override
  String get rendererId => 'inapp_webview';

  @override
  String get rendererName => 'InAppWebView';

  @override
  String get description =>
      'Cross-platform webview with enhanced features and customizations';

  @override
  List<PlatformType> get supportedPlatforms => [
        PlatformType.android,
        PlatformType.ios,
        PlatformType.macos,
        PlatformType.windows,
        PlatformType.linux,
      ];
}

/// WebView renderer factory for creating appropriate renderers
class WebViewRendererFactory {
  static final List<BaseWebViewRenderer> _renderers = [
    WebKitRenderer(),
    AndroidWebViewRenderer(),
    InAppWebViewRenderer(),
  ];

  /// Get all available renderers
  static List<BaseWebViewRenderer> getAvailableRenderers() {
    return _renderers.where((renderer) => renderer.isAvailable()).toList();
  }

  /// Get recommended renderer for current platform
  static BaseWebViewRenderer getRecommendedRenderer() {
    final available = getAvailableRenderers();
    if (available.isEmpty) {
      throw UnsupportedError(
          'No WebView renderers available for current platform');
    }

    // Platform-specific recommendations
    if (Platform.isAndroid) {
      return available.firstWhere(
        (r) => r.rendererId == 'android_webview',
        orElse: () => available.first,
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return available.firstWhere(
        (r) => r.rendererId == 'webkit',
        orElse: () => available.first,
      );
    }

    // Default to InAppWebView for cross-platform
    return available.firstWhere(
      (r) => r.rendererId == 'inapp_webview',
      orElse: () => available.first,
    );
  }

  /// Get renderer by ID
  static BaseWebViewRenderer? getRendererById(String rendererId) {
    try {
      return getAvailableRenderers().firstWhere(
        (r) => r.rendererId == rendererId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if renderer is supported
  static bool isRendererSupported(String rendererId) {
    final renderer = getRendererById(rendererId);
    return renderer != null && renderer.isAvailable();
  }
}

/// Renderer preferences for user configuration
class WebViewRendererPreferences {
  /// User's preferred renderer ID
  final String preferredRendererId;

  /// Auto-select recommended renderer based on platform
  final bool autoSelect;

  /// Platform-specific overrides
  final Map<PlatformType, String> platformRendererOverrides;

  const WebViewRendererPreferences({
    this.preferredRendererId = 'auto',
    this.autoSelect = true,
    this.platformRendererOverrides = const {},
  });

  /// Get effective renderer ID for current platform
  String getEffectiveRendererId() {
    if (autoSelect) {
      return WebViewRendererFactory.getRecommendedRenderer().rendererId;
    }

    if (preferredRendererId == 'auto') {
      return WebViewRendererFactory.getRecommendedRenderer().rendererId;
    }

    final currentPlatform = _getCurrentPlatformType();
    if (platformRendererOverrides.containsKey(currentPlatform)) {
      return platformRendererOverrides[currentPlatform]!;
    }

    return WebViewRendererFactory.isRendererSupported(preferredRendererId)
        ? preferredRendererId
        : WebViewRendererFactory.getRecommendedRenderer().rendererId;
  }

  PlatformType _getCurrentPlatformType() {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isMacOS) return PlatformType.macos;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.unknown;
  }

  /// Create copy with updated preferences
  WebViewRendererPreferences copyWith({
    String? preferredRendererId,
    bool? autoSelect,
    Map<PlatformType, String>? platformRendererOverrides,
  }) {
    return WebViewRendererPreferences(
      preferredRendererId: preferredRendererId ?? this.preferredRendererId,
      autoSelect: autoSelect ?? this.autoSelect,
      platformRendererOverrides:
          platformRendererOverrides ?? this.platformRendererOverrides,
    );
  }
}
