import '../../lib/models/tab.dart';

/// Builder pattern for creating test entities with fluent API
/// Provides flexible test data creation with sensible defaults

class TabBuilder {
  String _id = 'test-tab';
  String _title = 'Test Tab';
  String _url = 'https://example.com';
  String? _favicon;
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  double _loadingProgress = 0.0;
  bool _isSecure = false;
  bool _hasError = false;
  String? _errorMessage;
  DateTime? _createdAt;
  DateTime? _lastAccessedAt;

  TabBuilder withId(String id) {
    _id = id;
    return this;
  }

  TabBuilder withTitle(String title) {
    _title = title;
    return this;
  }

  TabBuilder withUrl(String url) {
    _url = url;
    return this;
  }

  TabBuilder withFavicon(String? favicon) {
    _favicon = favicon;
    return this;
  }

  TabBuilder asLoading() {
    _isLoading = true;
    return this;
  }

  TabBuilder asNotLoading() {
    _isLoading = false;
    return this;
  }

  TabBuilder withLoadingProgress(double progress) {
    _loadingProgress = progress;
    return this;
  }

  TabBuilder canNavigateBack() {
    _canGoBack = true;
    return this;
  }

  TabBuilder cannotNavigateBack() {
    _canGoBack = false;
    return this;
  }

  TabBuilder canNavigateForward() {
    _canGoForward = true;
    return this;
  }

  TabBuilder cannotNavigateForward() {
    _canGoForward = false;
    return this;
  }

  TabBuilder asSecure() {
    _isSecure = true;
    return this;
  }

  TabBuilder asInsecure() {
    _isSecure = false;
    return this;
  }

  TabBuilder withError(String errorMessage) {
    _hasError = true;
    _errorMessage = errorMessage;
    return this;
  }

  TabBuilder withoutError() {
    _hasError = false;
    _errorMessage = null;
    return this;
  }

  TabBuilder withCreatedAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  TabBuilder withLastAccessedAt(DateTime lastAccessedAt) {
    _lastAccessedAt = lastAccessedAt;
    return this;
  }

  TabBuilder withTimestamps() {
    final now = DateTime.now();
    _createdAt = now;
    _lastAccessedAt = now;
    return this;
  }

  /// Creates a tab in loading state with progress
  TabBuilder asLoadingWithProgress(double progress) {
    _isLoading = true;
    _loadingProgress = progress;
    return this;
  }

  /// Creates a tab with navigation capabilities
  TabBuilder withNavigationCapabilities({
    bool canGoBack = true,
    bool canGoForward = true,
  }) {
    _canGoBack = canGoBack;
    _canGoForward = canGoForward;
    return this;
  }

  /// Creates a secure HTTPS tab
  TabBuilder asHttpsTab() {
    _isSecure = true;
    if (!_url.startsWith('https://')) {
      _url = _url.replaceFirst('http://', 'https://');
    }
    return this;
  }

  /// Creates an insecure HTTP tab
  TabBuilder asHttpTab() {
    _isSecure = false;
    if (!_url.startsWith('http://')) {
      _url = _url.replaceFirst('https://', 'http://');
    }
    return this;
  }

  Tab build() {
    return Tab(
      id: _id,
      title: _title,
      url: _url,
      favicon: _favicon,
      isLoading: _isLoading,
      canGoBack: _canGoBack,
      canGoForward: _canGoForward,
      loadingProgress: _loadingProgress,
      isSecure: _isSecure,
      hasError: _hasError,
      errorMessage: _errorMessage,
      createdAt: _createdAt,
      lastAccessedAt: _lastAccessedAt,
    );
  }
}

/// Utility class for creating common tab scenarios
class TabScenarios {
  /// Creates a new blank tab
  static Tab newBlankTab({String? id}) {
    return TabBuilder()
        .withId(id ?? 'new-tab-${DateTime.now().millisecondsSinceEpoch}')
        .withTitle('New Tab')
        .withUrl('about:blank')
        .withTimestamps()
        .build();
  }

  /// Creates a tab loading a webpage
  static Tab loadingTab({
    String? id,
    String url = 'https://example.com',
    double progress = 0.5,
  }) {
    return TabBuilder()
        .withId(id ?? 'loading-tab')
        .withTitle('Loading...')
        .withUrl(url)
        .asLoadingWithProgress(progress)
        .asHttpsTab()
        .withTimestamps()
        .build();
  }

  /// Creates a fully loaded tab
  static Tab loadedTab({
    String? id,
    String title = 'Example Domain',
    String url = 'https://example.com',
    String? favicon,
  }) {
    return TabBuilder()
        .withId(id ?? 'loaded-tab')
        .withTitle(title)
        .withUrl(url)
        .withFavicon(favicon ?? 'https://example.com/favicon.ico')
        .asNotLoading()
        .withLoadingProgress(1.0)
        .asHttpsTab()
        .withNavigationCapabilities()
        .withTimestamps()
        .build();
  }

  /// Creates a tab with an error
  static Tab errorTab({
    String? id,
    String errorMessage = 'Failed to load page',
    String url = 'https://invalid-url.com',
  }) {
    return TabBuilder()
        .withId(id ?? 'error-tab')
        .withTitle('Error')
        .withUrl(url)
        .withError(errorMessage)
        .asNotLoading()
        .asHttpsTab() // Ensure HTTPS URLs are marked as secure
        .withTimestamps()
        .build();
  }

  /// Creates an insecure HTTP tab
  static Tab insecureTab({
    String? id,
    String title = 'Insecure Site',
    String url = 'http://insecure-site.com',
  }) {
    return TabBuilder()
        .withId(id ?? 'insecure-tab')
        .withTitle(title)
        .withUrl(url)
        .asHttpTab()
        .asNotLoading()
        .withTimestamps()
        .build();
  }

  /// Creates a tab with navigation history
  static Tab navigableTab({
    String? id,
    String title = 'Page with History',
    String url = 'https://example.com/page2',
    bool canGoBack = true,
    bool canGoForward = false,
  }) {
    return TabBuilder()
        .withId(id ?? 'navigable-tab')
        .withTitle(title)
        .withUrl(url)
        .withNavigationCapabilities(
          canGoBack: canGoBack,
          canGoForward: canGoForward,
        )
        .asHttpsTab()
        .withTimestamps()
        .build();
  }

  /// Creates a list of tabs for testing multiple tab scenarios
  static List<Tab> multipleTabsScenario() {
    return [
      newBlankTab(id: 'tab-1'),
      loadedTab(
        id: 'tab-2',
        title: 'Google',
        url: 'https://google.com',
        favicon: 'https://google.com/favicon.ico',
      ),
      loadingTab(
        id: 'tab-3',
        url: 'https://github.com',
        progress: 0.7,
      ),
      errorTab(
        id: 'tab-4',
        errorMessage: 'Network connection failed',
      ),
      insecureTab(
        id: 'tab-5',
        title: 'HTTP Site',
        url: 'http://example.org',
      ),
    ];
  }

  /// Creates tabs for performance testing
  static List<Tab> performanceTestTabs({int count = 50}) {
    return List.generate(count, (index) {
      return TabBuilder()
          .withId('perf-tab-$index')
          .withTitle('Performance Test Tab $index')
          .withUrl('https://example.com/page$index')
          .asHttpsTab()
          .withTimestamps()
          .build();
    });
  }

  /// Creates edge case tabs for robustness testing
  static Map<String, Tab> edgeCaseTabs() {
    return {
      'empty_title': TabBuilder()
          .withTitle('')
          .withUrl('https://example.com')
          .build(),
      'very_long_title': TabBuilder()
          .withTitle('A' * 500)
          .withUrl('https://example.com')
          .build(),
      'special_chars_title': TabBuilder()
          .withTitle('Special chars: !@#\$%^&*()_+{}|:"<>?[]\\;\',./')
          .withUrl('https://example.com')
          .build(),
      'unicode_title': TabBuilder()
          .withTitle('Unicode: 🌐 Browser 中文 العربية')
          .withUrl('https://example.com')
          .build(),
      'invalid_url': TabBuilder()
          .withTitle('Invalid URL')
          .withUrl('not-a-valid-url')
          .build(),
      'data_url': TabBuilder()
          .withTitle('Data URL')
          .withUrl('data:text/html,<h1>Hello World</h1>')
          .build(),
      'file_url': TabBuilder()
          .withTitle('File URL')
          .withUrl('file:///Users/test/document.html')
          .build(),
    };
  }
}
