import 'package:flutter_test/flutter_test.dart';
import '../../../lib/models/tab.dart';

import '../../fixtures/entity_builders.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('Tab Model Tests', () {
    group('Constructor and Factory Tests', () {
      test('should create Tab with all required parameters', () {
        // Arrange
        const id = 'test-tab-1';
        const title = 'Test Tab';
        const url = 'https://example.com';
        final createdAt = DateTime.now();

        // Act
        final tab = Tab(
          id: id,
          title: title,
          url: url,
          createdAt: createdAt,
        );

        // Assert
        expect(tab.id, equals(id));
        expect(tab.title, equals(title));
        expect(tab.url, equals(url));
        expect(tab.createdAt, equals(createdAt));
        expect(tab.isLoading, isFalse);
        expect(tab.canGoBack, isFalse);
        expect(tab.canGoForward, isFalse);
        expect(tab.loadingProgress, equals(0.0));
        expect(tab.isSecure, isFalse);
        expect(tab.hasError, isFalse);
        expect(tab.errorMessage, isNull);
        expect(tab.favicon, isNull);
        expect(tab.lastAccessedAt, isNull);
      });

      test('should create Tab with all optional parameters', () {
        // Arrange
        const id = 'test-tab-2';
        const title = 'Full Tab';
        const url = 'https://secure-site.com';
        const favicon = 'https://secure-site.com/favicon.ico';
        const isLoading = true;
        const canGoBack = true;
        const canGoForward = true;
        const loadingProgress = 0.75;
        const isSecure = true;
        const hasError = false;
        const errorMessage = null;
        final createdAt = DateTime.now();
        final lastAccessedAt = DateTime.now();

        // Act
        final tab = Tab(
          id: id,
          title: title,
          url: url,
          favicon: favicon,
          isLoading: isLoading,
          canGoBack: canGoBack,
          canGoForward: canGoForward,
          loadingProgress: loadingProgress,
          isSecure: isSecure,
          hasError: hasError,
          errorMessage: errorMessage,
          createdAt: createdAt,
          lastAccessedAt: lastAccessedAt,
        );

        // Assert
        expect(tab.id, equals(id));
        expect(tab.title, equals(title));
        expect(tab.url, equals(url));
        expect(tab.favicon, equals(favicon));
        expect(tab.isLoading, equals(isLoading));
        expect(tab.canGoBack, equals(canGoBack));
        expect(tab.canGoForward, equals(canGoForward));
        expect(tab.loadingProgress, equals(loadingProgress));
        expect(tab.isSecure, equals(isSecure));
        expect(tab.hasError, equals(hasError));
        expect(tab.errorMessage, equals(errorMessage));
        expect(tab.createdAt, equals(createdAt));
        expect(tab.lastAccessedAt, equals(lastAccessedAt));
      });

      test('should create new tab using factory constructor', () {
        // Act
        final tab = Tab.newTab();

        // Assert
        expect(tab.id, isNotEmpty);
        expect(tab.id, startsWith('tab_'));
        expect(tab.title, equals('New Tab'));
        expect(tab.url, equals('about:blank'));
        expect(tab.createdAt, isNotNull);
        expect(tab.lastAccessedAt, isNotNull);
        expect(tab.isLoading, isFalse);
        expect(tab.hasError, isFalse);
      });

      test('should create new tab with custom parameters', () {
        // Arrange
        const customId = 'custom-tab-id';
        const customUrl = 'https://custom.com';
        const customTitle = 'Custom Tab';

        // Act
        final tab = Tab.newTab(
          id: customId,
          url: customUrl,
          title: customTitle,
        );

        // Assert
        expect(tab.id, equals(customId));
        expect(tab.title, equals(customTitle));
        expect(tab.url, equals(customUrl));
        expect(tab.createdAt, isNotNull);
        expect(tab.lastAccessedAt, isNotNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize Tab to JSON correctly', () {
        // Arrange
        final tab = TabBuilder()
            .withId('json-tab')
            .withTitle('JSON Test Tab')
            .withUrl('https://json-test.com')
            .withFavicon('https://json-test.com/favicon.ico')
            .asLoading()
            .withLoadingProgress(0.5)
            .canNavigateBack()
            .asSecure()
            .withTimestamps()
            .build();

        // Act
        final json = tab.toJson();

        // Assert
        expect(json['id'], equals('json-tab'));
        expect(json['title'], equals('JSON Test Tab'));
        expect(json['url'], equals('https://json-test.com'));
        expect(json['favicon'], equals('https://json-test.com/favicon.ico'));
        expect(json['isLoading'], isTrue);
        expect(json['canGoBack'], isTrue);
        expect(json['canGoForward'], isFalse);
        expect(json['loadingProgress'], equals(0.5));
        expect(json['isSecure'], isTrue);
        expect(json['hasError'], isFalse);
        expect(json['errorMessage'], isNull);
        expect(json['createdAt'], isNotNull);
        expect(json['lastAccessedAt'], isNotNull);
      });

      test('should deserialize Tab from JSON correctly', () {
        // Arrange
        final createdAt = DateTime.now();
        final lastAccessedAt = DateTime.now();
        final json = {
          'id': 'json-tab',
          'title': 'JSON Test Tab',
          'url': 'https://json-test.com',
          'favicon': 'https://json-test.com/favicon.ico',
          'isLoading': true,
          'canGoBack': true,
          'canGoForward': false,
          'loadingProgress': 0.5,
          'isSecure': true,
          'hasError': false,
          'errorMessage': null,
          'createdAt': createdAt.toIso8601String(),
          'lastAccessedAt': lastAccessedAt.toIso8601String(),
        };

        // Act
        final tab = Tab.fromJson(json);

        // Assert
        expect(tab.id, equals('json-tab'));
        expect(tab.title, equals('JSON Test Tab'));
        expect(tab.url, equals('https://json-test.com'));
        expect(tab.favicon, equals('https://json-test.com/favicon.ico'));
        expect(tab.isLoading, isTrue);
        expect(tab.canGoBack, isTrue);
        expect(tab.canGoForward, isFalse);
        expect(tab.loadingProgress, equals(0.5));
        expect(tab.isSecure, isTrue);
        expect(tab.hasError, isFalse);
        expect(tab.errorMessage, isNull);
        expect(tab.createdAt, isNotNull);
        expect(tab.lastAccessedAt, isNotNull);
      });

      test('should handle null values in JSON deserialization', () {
        // Arrange
        final json = {
          'id': 'minimal-tab',
          'title': 'Minimal Tab',
          'url': 'https://minimal.com',
          'favicon': null,
          'errorMessage': null,
          'createdAt': null,
          'lastAccessedAt': null,
        };

        // Act
        final tab = Tab.fromJson(json);

        // Assert
        expect(tab.id, equals('minimal-tab'));
        expect(tab.title, equals('Minimal Tab'));
        expect(tab.url, equals('https://minimal.com'));
        expect(tab.favicon, isNull);
        expect(tab.errorMessage, isNull);
        expect(tab.createdAt, isNull);
        expect(tab.lastAccessedAt, isNull);
        expect(tab.isLoading, isFalse); // Default value
        expect(tab.loadingProgress, equals(0.0)); // Default value
      });

      test('should handle missing optional fields in JSON', () {
        // Arrange
        final json = {
          'id': 'basic-tab',
          'title': 'Basic Tab',
          'url': 'https://basic.com',
        };

        // Act
        final tab = Tab.fromJson(json);

        // Assert
        expect(tab.id, equals('basic-tab'));
        expect(tab.title, equals('Basic Tab'));
        expect(tab.url, equals('https://basic.com'));
        expect(tab.favicon, isNull);
        expect(tab.isLoading, isFalse);
        expect(tab.canGoBack, isFalse);
        expect(tab.canGoForward, isFalse);
        expect(tab.loadingProgress, equals(0.0));
        expect(tab.isSecure, isFalse);
        expect(tab.hasError, isFalse);
        expect(tab.errorMessage, isNull);
      });

      test('should round-trip serialize and deserialize correctly', () {
        // Arrange
        final originalTab = TabBuilder()
            .withId('roundtrip-tab')
            .withTitle('Round Trip Test')
            .withUrl('https://roundtrip.com')
            .withFavicon('https://roundtrip.com/icon.png')
            .asLoadingWithProgress(0.75)
            .withNavigationCapabilities(canGoBack: true, canGoForward: true)
            .asSecure()
            .withError('Test error message')
            .withTimestamps()
            .build();

        // Act
        final json = originalTab.toJson();
        final deserializedTab = Tab.fromJson(json);

        // Assert
        expect(deserializedTab.id, equals(originalTab.id));
        expect(deserializedTab.title, equals(originalTab.title));
        expect(deserializedTab.url, equals(originalTab.url));
        expect(deserializedTab.favicon, equals(originalTab.favicon));
        expect(deserializedTab.isLoading, equals(originalTab.isLoading));
        expect(deserializedTab.canGoBack, equals(originalTab.canGoBack));
        expect(deserializedTab.canGoForward, equals(originalTab.canGoForward));
        expect(deserializedTab.loadingProgress, equals(originalTab.loadingProgress));
        expect(deserializedTab.isSecure, equals(originalTab.isSecure));
        expect(deserializedTab.hasError, equals(originalTab.hasError));
        expect(deserializedTab.errorMessage, equals(originalTab.errorMessage));
        expect(deserializedTab, equals(originalTab)); // Test Equatable
      });
    });

    group('CopyWith Method Tests', () {
      late Tab originalTab;

      setUp(() {
        originalTab = TabBuilder()
            .withId('original-tab')
            .withTitle('Original Title')
            .withUrl('https://original.com')
            .withFavicon('https://original.com/favicon.ico')
            .asLoadingWithProgress(0.3)
            .canNavigateBack()
            .asSecure()
            .withTimestamps()
            .build();
      });

      test('should copy with updated title', () {
        // Act
        final updatedTab = originalTab.copyWith(title: 'Updated Title');

        // Assert
        expect(updatedTab.title, equals('Updated Title'));
        expect(updatedTab.id, equals(originalTab.id));
        expect(updatedTab.url, equals(originalTab.url));
        expect(updatedTab.favicon, equals(originalTab.favicon));
        expect(updatedTab.isLoading, equals(originalTab.isLoading));
      });

      test('should copy with updated URL', () {
        // Act
        final updatedTab = originalTab.copyWith(url: 'https://updated.com');

        // Assert
        expect(updatedTab.url, equals('https://updated.com'));
        expect(updatedTab.title, equals(originalTab.title));
        expect(updatedTab.id, equals(originalTab.id));
      });

      test('should copy with updated loading state', () {
        // Act
        final updatedTab = originalTab.copyWith(
          isLoading: false,
          loadingProgress: 1.0,
        );

        // Assert
        expect(updatedTab.isLoading, isFalse);
        expect(updatedTab.loadingProgress, equals(1.0));
        expect(updatedTab.title, equals(originalTab.title));
      });

      test('should copy with updated navigation capabilities', () {
        // Act
        final updatedTab = originalTab.copyWith(
          canGoBack: false,
          canGoForward: true,
        );

        // Assert
        expect(updatedTab.canGoBack, isFalse);
        expect(updatedTab.canGoForward, isTrue);
        expect(updatedTab.title, equals(originalTab.title));
      });

      test('should copy with null favicon using sentinel', () {
        // Act
        final updatedTab = originalTab.copyWith(favicon: null);

        // Assert
        expect(updatedTab.favicon, isNull);
        expect(updatedTab.title, equals(originalTab.title));
        expect(updatedTab.url, equals(originalTab.url));
      });

      test('should copy with error state', () {
        // Act
        final updatedTab = originalTab.copyWith(
          hasError: true,
          errorMessage: 'Network error',
        );

        // Assert
        expect(updatedTab.hasError, isTrue);
        expect(updatedTab.errorMessage, equals('Network error'));
        expect(updatedTab.title, equals(originalTab.title));
      });

      test('should copy with null error message using sentinel', () {
        // Arrange
        final tabWithError = originalTab.copyWith(
          hasError: true,
          errorMessage: 'Some error',
        );

        // Act
        final updatedTab = tabWithError.copyWith(
          hasError: false,
          errorMessage: null,
        );

        // Assert
        expect(updatedTab.hasError, isFalse);
        expect(updatedTab.errorMessage, isNull);
      });

      test('should copy with updated timestamps', () {
        // Arrange
        final newCreatedAt = DateTime.now().add(const Duration(hours: 1));
        final newLastAccessedAt = DateTime.now().add(const Duration(hours: 2));

        // Act
        final updatedTab = originalTab.copyWith(
          createdAt: newCreatedAt,
          lastAccessedAt: newLastAccessedAt,
        );

        // Assert
        expect(updatedTab.createdAt, equals(newCreatedAt));
        expect(updatedTab.lastAccessedAt, equals(newLastAccessedAt));
        expect(updatedTab.title, equals(originalTab.title));
      });

      test('should copy with null timestamps using sentinel', () {
        // Act
        final updatedTab = originalTab.copyWith(
          createdAt: null,
          lastAccessedAt: null,
        );

        // Assert
        expect(updatedTab.createdAt, isNull);
        expect(updatedTab.lastAccessedAt, isNull);
        expect(updatedTab.title, equals(originalTab.title));
      });

      test('should not modify original tab when copying', () {
        // Arrange
        final originalTitle = originalTab.title;
        final originalUrl = originalTab.url;

        // Act
        originalTab.copyWith(
          title: 'Modified Title',
          url: 'https://modified.com',
        );

        // Assert
        expect(originalTab.title, equals(originalTitle));
        expect(originalTab.url, equals(originalUrl));
      });
    });

    group('Equatable Implementation Tests', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final tab1 = TabBuilder()
            .withId('equal-tab')
            .withTitle('Equal Tab')
            .withUrl('https://equal.com')
            .build();

        final tab2 = TabBuilder()
            .withId('equal-tab')
            .withTitle('Equal Tab')
            .withUrl('https://equal.com')
            .build();

        // Assert
        expect(tab1, equals(tab2));
        expect(tab1.hashCode, equals(tab2.hashCode));
      });

      test('should not be equal when IDs are different', () {
        // Arrange
        final tab1 = TabBuilder()
            .withId('tab-1')
            .withTitle('Same Title')
            .withUrl('https://same.com')
            .build();

        final tab2 = TabBuilder()
            .withId('tab-2')
            .withTitle('Same Title')
            .withUrl('https://same.com')
            .build();

        // Assert
        expect(tab1, isNot(equals(tab2)));
        expect(tab1.hashCode, isNot(equals(tab2.hashCode)));
      });

      test('should not be equal when titles are different', () {
        // Arrange
        final tab1 = TabBuilder()
            .withId('same-tab')
            .withTitle('Title 1')
            .withUrl('https://same.com')
            .build();

        final tab2 = TabBuilder()
            .withId('same-tab')
            .withTitle('Title 2')
            .withUrl('https://same.com')
            .build();

        // Assert
        expect(tab1, isNot(equals(tab2)));
      });

      test('should not be equal when loading states are different', () {
        // Arrange
        final tab1 = TabBuilder()
            .withId('same-tab')
            .withTitle('Same Title')
            .withUrl('https://same.com')
            .asLoading()
            .build();

        final tab2 = TabBuilder()
            .withId('same-tab')
            .withTitle('Same Title')
            .withUrl('https://same.com')
            .asNotLoading()
            .build();

        // Assert
        expect(tab1, isNot(equals(tab2)));
      });

      test('should handle null values in equality comparison', () {
        // Arrange
        final tab1 = TabBuilder()
            .withId('null-tab')
            .withTitle('Null Test')
            .withUrl('https://null.com')
            .withFavicon(null)
            .build();

        final tab2 = TabBuilder()
            .withId('null-tab')
            .withTitle('Null Test')
            .withUrl('https://null.com')
            .withFavicon(null)
            .build();

        // Assert
        expect(tab1, equals(tab2));
        expect(tab1.hashCode, equals(tab2.hashCode));
      });
    });

    group('ToString Method Tests', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final tab = TabBuilder()
            .withId('string-tab')
            .withTitle('String Test Tab')
            .withUrl('https://string-test.com')
            .asLoading()
            .build();

        // Act
        final stringRepresentation = tab.toString();

        // Assert
        expect(stringRepresentation, contains('string-tab'));
        expect(stringRepresentation, contains('String Test Tab'));
        expect(stringRepresentation, contains('https://string-test.com'));
        expect(stringRepresentation, contains('true')); // isLoading
      });
    });

    group('Edge Cases and Validation Tests', () {
      test('should handle empty strings', () {
        // Act & Assert
        expect(
          () => Tab(id: '', title: 'Valid Title', url: 'https://valid.com'),
          returnsNormally,
        );

        expect(
          () => Tab(id: 'valid-id', title: '', url: 'https://valid.com'),
          returnsNormally,
        );

        expect(
          () => Tab(id: 'valid-id', title: 'Valid Title', url: ''),
          returnsNormally,
        );
      });

      test('should handle extreme loading progress values', () {
        // Arrange & Act
        final tab1 = TabBuilder().withLoadingProgress(0.0).build();
        final tab2 = TabBuilder().withLoadingProgress(1.0).build();
        final tab3 = TabBuilder().withLoadingProgress(0.5).build();

        // Assert
        expect(tab1.loadingProgress, equals(0.0));
        expect(tab2.loadingProgress, equals(1.0));
        expect(tab3.loadingProgress, equals(0.5));
      });

      test('should validate tab state consistency', () {
        // Arrange
        final validTab = TabScenarios.loadedTab();
        final loadingTab = TabScenarios.loadingTab();
        final errorTab = TabScenarios.errorTab();

        // Assert
        expect(TestValidators.isValidTab(validTab), isTrue);
        expect(TestValidators.isValidTab(loadingTab), isTrue);
        expect(TestValidators.isValidTab(errorTab), isTrue);
        expect(TestValidators.isConsistentTabState(validTab), isTrue);
        expect(TestValidators.isConsistentTabState(loadingTab), isTrue);
        expect(TestValidators.isConsistentTabState(errorTab), isTrue);
      });

      test('should validate timestamp ordering', () {
        // Arrange
        final now = DateTime.now();
        final past = now.subtract(const Duration(hours: 1));
        final future = now.add(const Duration(hours: 1));

        final validTab = TabBuilder()
            .withCreatedAt(past)
            .withLastAccessedAt(now)
            .build();

        final invalidTab = TabBuilder()
            .withCreatedAt(future)
            .withLastAccessedAt(now)
            .build();

        // Assert
        expect(TestValidators.areTimestampsValid(validTab), isTrue);
        expect(TestValidators.areTimestampsValid(invalidTab), isFalse);
      });
    });

    group('Builder Pattern Tests', () {
      test('should create tabs using TabBuilder fluent API', () {
        // Act
        final tab = TabBuilder()
            .withId('builder-tab')
            .withTitle('Builder Test')
            .withUrl('https://builder.com')
            .asHttpsTab()
            .asLoadingWithProgress(0.8)
            .withNavigationCapabilities(canGoBack: true, canGoForward: false)
            .withTimestamps()
            .build();

        // Assert
        expect(tab.id, equals('builder-tab'));
        expect(tab.title, equals('Builder Test'));
        expect(tab.url, equals('https://builder.com'));
        expect(tab.isSecure, isTrue);
        expect(tab.isLoading, isTrue);
        expect(tab.loadingProgress, equals(0.8));
        expect(tab.canGoBack, isTrue);
        expect(tab.canGoForward, isFalse);
        expect(tab.createdAt, isNotNull);
        expect(tab.lastAccessedAt, isNotNull);
      });

      test('should create tabs using scenario helpers', () {
        // Act
        final newTab = TabScenarios.newBlankTab();
        final loadingTab = TabScenarios.loadingTab();
        final loadedTab = TabScenarios.loadedTab();
        final errorTab = TabScenarios.errorTab();

        // Assert
        expect(newTab.url, equals('about:blank'));
        expect(newTab.title, equals('New Tab'));

        expect(loadingTab.isLoading, isTrue);
        expect(loadingTab.loadingProgress, greaterThan(0.0));

        expect(loadedTab.isLoading, isFalse);
        expect(loadedTab.loadingProgress, equals(1.0));

        expect(errorTab.hasError, isTrue);
        expect(errorTab.errorMessage, isNotNull);
      });

      test('should create edge case tabs', () {
        // Act
        final edgeCases = TabScenarios.edgeCaseTabs();

        // Assert
        expect(edgeCases['empty_title']!.title, isEmpty);
        expect(edgeCases['very_long_title']!.title.length, equals(500));
        expect(edgeCases['unicode_title']!.title, contains('🌐'));
        expect(edgeCases['data_url']!.url, startsWith('data:'));
        expect(edgeCases['file_url']!.url, startsWith('file:'));
      });
    });
  });
}
