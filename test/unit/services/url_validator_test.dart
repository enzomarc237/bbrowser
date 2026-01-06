import 'package:flutter_test/flutter_test.dart';
import 'package:bbrowser/services/url_validator.dart';

void main() {
  group('UrlValidator', () {
    group('Basic URL Validation', () {
      test('should validate HTTPS URLs', () {
        final result = UrlValidator.validate('https://example.com');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/'));
        expect(result.scheme, equals('https'));
        expect(result.host, equals('example.com'));
        expect(result.isSecure, isTrue);
        expect(result.isLocal, isFalse);
      });

      test('should validate HTTP URLs', () {
        final result = UrlValidator.validate('http://example.com');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('http://example.com/'));
        expect(result.scheme, equals('http'));
        expect(result.host, equals('example.com'));
        expect(result.isSecure, isFalse);
        expect(result.isLocal, isFalse);
      });

      test('should add HTTPS to domain-like inputs', () {
        final result = UrlValidator.validate('example.com');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/'));
        expect(result.scheme, equals('https'));
        expect(result.host, equals('example.com'));
        expect(result.isSecure, isTrue);
      });

      test('should handle URLs with paths', () {
        final result = UrlValidator.validate('https://example.com/path/to/page');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/path/to/page'));
        expect(result.path, equals('/path/to/page'));
      });

      test('should handle URLs with query parameters', () {
        final result = UrlValidator.validate('https://example.com/search?q=test&lang=en');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/search?q=test&lang=en'));
      });

      test('should handle URLs with fragments', () {
        final result = UrlValidator.validate('https://example.com/page#section');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/page#section'));
      });
    });

    group('Special URLs', () {
      test('should handle about:blank', () {
        final result = UrlValidator.validate('about:blank');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('about:blank'));
        expect(result.scheme, equals('about'));
      });

      test('should handle data URLs', () {
        final result = UrlValidator.validate('data:text/html,<h1>Hello</h1>');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('data:text/html,<h1>Hello</h1>'));
        expect(result.scheme, equals('data'));
      });

      test('should handle localhost', () {
        final result = UrlValidator.validate('localhost');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('http://localhost'));
        expect(result.scheme, equals('http'));
        expect(result.host, equals('localhost'));
        expect(result.isLocal, isTrue);
      });

      test('should handle localhost with port', () {
        final result = UrlValidator.validate('localhost:3000');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://localhost:3000/'));
        expect(result.host, equals('localhost'));
        expect(result.port, equals(3000));
        expect(result.isLocal, isTrue);
      });
    });

    group('Search Queries', () {
      test('should convert search queries to Google search', () {
        final result = UrlValidator.validate('flutter development');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, contains('google.com/search'));
        expect(result.normalizedUrl, contains('flutter%20development'));
        expect(result.isSearch, isTrue);
        expect(result.isSecure, isTrue);
      });

      test('should handle single word searches', () {
        final result = UrlValidator.validate('flutter');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, contains('google.com/search'));
        expect(result.normalizedUrl, contains('flutter'));
        expect(result.isSearch, isTrue);
      });

      test('should handle searches with special characters', () {
        final result = UrlValidator.validate('how to use @override in dart?');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, contains('google.com/search'));
        expect(result.isSearch, isTrue);
      });
    });

    group('IP Addresses', () {
      test('should validate IPv4 addresses', () {
        final result = UrlValidator.validate('192.168.1.1');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://192.168.1.1/'));
        expect(result.host, equals('192.168.1.1'));
      });

      test('should validate IPv4 with port', () {
        final result = UrlValidator.validate('192.168.1.1:8080');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://192.168.1.1:8080/'));
        expect(result.host, equals('192.168.1.1'));
        expect(result.port, equals(8080));
      });

      test('should handle localhost IP', () {
        final result = UrlValidator.validate('127.0.0.1');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://127.0.0.1/'));
        expect(result.host, equals('127.0.0.1'));
        expect(result.isLocal, isTrue);
      });
    });

    group('Port Handling', () {
      test('should include non-default ports', () {
        final result = UrlValidator.validate('https://example.com:8443');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com:8443/'));
        expect(result.port, equals(8443));
      });

      test('should omit default HTTP port', () {
        final result = UrlValidator.validate('http://example.com:80');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('http://example.com/'));
        expect(result.port, equals(80));
      });

      test('should omit default HTTPS port', () {
        final result = UrlValidator.validate('https://example.com:443');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/'));
        expect(result.port, equals(443));
      });

      test('should reject invalid ports', () {
        final result = UrlValidator.validate('https://example.com:99999');
        
        expect(result.isValid, isFalse);
        expect(result.error, contains('Invalid port number'));
      });
    });

    group('Error Handling', () {
      test('should reject empty input', () {
        final result = UrlValidator.validate('');
        
        expect(result.isValid, isFalse);
        expect(result.error, equals('URL cannot be empty'));
      });

      test('should reject unsupported schemes', () {
        final result = UrlValidator.validate('foobar://example.com');
        
        expect(result.isValid, isFalse);
        expect(result.error, contains('Unsupported URL scheme'));
      });

      test('should reject invalid host names', () {
        final result = UrlValidator.validate('https://invalid..host');
        
        expect(result.isValid, isFalse);
        expect(result.error, contains('Invalid host format'));
      });
    });

    group('Normalization', () {
      test('should normalize host to lowercase', () {
        final result = UrlValidator.validate('https://EXAMPLE.COM');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/'));
        expect(result.host, equals('EXAMPLE.COM'));
      });

      test('should add trailing slash for root paths', () {
        final result = UrlValidator.validate('https://example.com');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/'));
      });

      test('should preserve non-root paths', () {
        final result = UrlValidator.validate('https://example.com/path');
        
        expect(result.isValid, isTrue);
        expect(result.normalizedUrl, equals('https://example.com/path'));
      });
    });

    group('Utility Methods', () {
      test('isSecureUrl should identify secure URLs', () {
        expect(UrlValidator.isSecureUrl('https://example.com'), isTrue);
        expect(UrlValidator.isSecureUrl('http://example.com'), isFalse);
        expect(UrlValidator.isSecureUrl('ftps://example.com'), isTrue);
        expect(UrlValidator.isSecureUrl('ftp://example.com'), isFalse);
      });

      test('isLocalUrl should identify local URLs', () {
        expect(UrlValidator.isLocalUrl('http://localhost'), isTrue);
        expect(UrlValidator.isLocalUrl('http://127.0.0.1'), isTrue);
        expect(UrlValidator.isLocalUrl('file:///path/to/file'), isTrue);
        expect(UrlValidator.isLocalUrl('https://example.com'), isFalse);
      });

      test('extractDomain should extract domain from URL', () {
        expect(UrlValidator.extractDomain('https://example.com/path'), equals('example.com'));
        expect(UrlValidator.extractDomain('http://subdomain.example.com'), equals('subdomain.example.com'));
        expect(UrlValidator.extractDomain('about:blank'), isNull);
      });

      test('isSearchUrl should identify search URLs', () {
        expect(UrlValidator.isSearchUrl('https://www.google.com/search?q=test'), isTrue);
        expect(UrlValidator.isSearchUrl('https://www.bing.com/search?q=test'), isTrue);
        expect(UrlValidator.isSearchUrl('https://example.com'), isFalse);
      });

      test('getBaseUrl should extract base URL', () {
        expect(UrlValidator.getBaseUrl('https://example.com/path?query=1'), equals('https://example.com'));
        expect(UrlValidator.getBaseUrl('http://example.com:8080/path'), equals('http://example.com:8080'));
        expect(UrlValidator.getBaseUrl('about:blank'), isNull);
      });

      test('resolveUrl should resolve relative URLs', () {
        expect(
          UrlValidator.resolveUrl('https://example.com/path/', '../other'),
          equals('https://example.com/other'),
        );
        expect(
          UrlValidator.resolveUrl('https://example.com/path/', 'subpath'),
          equals('https://example.com/path/subpath'),
        );
      });
    });

    group('File URLs', () {
      test('should handle file paths', () {
        final result = UrlValidator.validate('/path/to/file.html');
        
        expect(result.isValid, isTrue);
        expect(result.scheme, equals('file'));
        expect(result.path, equals('/path/to/file.html'));
      });

      test('should handle relative file paths', () {
        final result = UrlValidator.validate('./file.html');
        
        expect(result.isValid, isTrue);
        expect(result.scheme, equals('file'));
      });
    });

    group('Domain Detection', () {
      test('should detect valid domains', () {
        final testCases = [
          'example.com',
          'subdomain.example.com',
          'example.co.uk',
          'test-site.example.org',
        ];

        for (final domain in testCases) {
          final result = UrlValidator.validate(domain);
          expect(result.isValid, isTrue, reason: 'Failed for domain: $domain');
          expect(result.scheme, equals('https'));
        }
      });

      test('should not treat search queries as domains', () {
        final testCases = [
          'how to code',
          'flutter tutorial',
          'what is dart?',
          'search term with spaces',
        ];

        for (final query in testCases) {
          final result = UrlValidator.validate(query);
          expect(result.isValid, isTrue, reason: 'Failed for query: $query');
          expect(result.isSearch, isTrue, reason: 'Should be treated as search: $query');
        }
      });
    });
  });
}
