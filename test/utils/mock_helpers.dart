import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mock classes for testing
class MockWebViewController extends Mock implements WebViewController {}

class MockNavigationDelegate extends Mock implements NavigationDelegate {}

/// Mock data for testing
class MockData {
  static const String validUrl = 'https://www.example.com';
  static const String invalidUrl = 'not-a-url';
  static const String httpsUrl = 'https://secure.example.com';
  static const String httpUrl = 'http://insecure.example.com';
  
  static const String tabTitle = 'Example Page';
  static const String tabId = 'tab-1';
  
  static const List<String> sampleUrls = [
    'https://www.google.com',
    'https://www.github.com',
    'https://www.stackoverflow.com',
    'https://www.flutter.dev',
  ];
  
  static const List<String> sampleTitles = [
    'Google',
    'GitHub',
    'Stack Overflow',
    'Flutter',
  ];
}

/// Helper functions for setting up mocks
class MockSetup {
  /// Sets up a mock WebViewController with default behavior
  static MockWebViewController setupMockWebViewController() {
    final mock = MockWebViewController();
    
    // Setup default behavior
    when(() => mock.loadRequest(any())).thenAnswer((_) async {});
    when(() => mock.canGoBack()).thenAnswer((_) async => false);
    when(() => mock.canGoForward()).thenAnswer((_) async => false);
    when(() => mock.goBack()).thenAnswer((_) async {});
    when(() => mock.goForward()).thenAnswer((_) async {});
    when(() => mock.reload()).thenAnswer((_) async {});
    when(() => mock.getTitle()).thenAnswer((_) async => MockData.tabTitle);
    when(() => mock.currentUrl()).thenAnswer((_) async => MockData.validUrl);
    
    return mock;
  }
  
  /// Sets up a mock NavigationDelegate with default behavior
  static MockNavigationDelegate setupMockNavigationDelegate() {
    final mock = MockNavigationDelegate();
    
    // Setup default behavior
    when(() => mock.onNavigationRequest).thenReturn(null);
    when(() => mock.onPageStarted).thenReturn(null);
    when(() => mock.onPageFinished).thenReturn(null);
    when(() => mock.onProgress).thenReturn(null);
    when(() => mock.onWebResourceError).thenReturn(null);
    
    return mock;
  }
}
