import 'package:flutter_test/flutter_test.dart';
import 'package:bbrowser/services/content_security.dart';

void main() {
  group('ContentSecurityService', () {
    late ContentSecurityService service;

    setUp(() {
      service = ContentSecurityService();
    });

    group('Configuration Management', () {
      test('should have default configuration', () {
        final config = service.config;
        
        expect(config.securityLevel, equals(SecurityLevel.moderate));
        expect(config.cookiePolicy, equals(CookiePolicy.blockThirdParty));
        expect(config.blockTrackers, isTrue);
        expect(config.blockAds, isFalse);
        expect(config.enableJavaScript, isTrue);
        expect(config.enableImages, isTrue);
        expect(config.enablePopups, isFalse);
        expect(config.enableDownloads, isTrue);
        expect(config.enableGeolocation, isFalse);
        expect(config.enableCamera, isFalse);
        expect(config.enableMicrophone, isFalse);
        expect(config.enableNotifications, isFalse);
        expect(config.httpsOnly, isFalse);
        expect(config.blockMixedContent, isTrue);
      });

      test('should update configuration', () async {
        final newConfig = service.config.copyWith(
          securityLevel: SecurityLevel.strict,
          blockAds: true,
          httpsOnly: true,
        );

        await service.updateConfig(newConfig);

        expect(service.config.securityLevel, equals(SecurityLevel.strict));
        expect(service.config.blockAds, isTrue);
        expect(service.config.httpsOnly, isTrue);
        expect(service.config.blockTrackers, isTrue); // Should preserve other settings
      });
    });

    group('URL Blocking', () {
      test('should not block valid URLs by default', () {
        expect(service.shouldBlockUrl('https://example.com'), isFalse);
        expect(service.shouldBlockUrl('http://example.com'), isFalse);
        expect(service.shouldBlockUrl('https://google.com/search'), isFalse);
      });

      test('should block URLs from blocked domains', () async {
        await service.blockDomain('blocked-site.com');
        
        expect(service.shouldBlockUrl('https://blocked-site.com'), isTrue);
        expect(service.shouldBlockUrl('http://blocked-site.com/path'), isTrue);
        expect(service.shouldBlockUrl('https://example.com'), isFalse);
      });

      test('should not block URLs from trusted domains', () async {
        await service.trustDomain('trusted-site.com');
        
        // Even with strict settings, trusted domains should not be blocked
        final strictConfig = service.config.copyWith(
          securityLevel: SecurityLevel.strict,
          httpsOnly: true,
        );
        await service.updateConfig(strictConfig);
        
        expect(service.shouldBlockUrl('http://trusted-site.com'), isFalse);
        expect(service.shouldBlockUrl('https://trusted-site.com'), isFalse);
      });

      test('should block HTTP URLs when HTTPS-only is enabled', () async {
        final httpsOnlyConfig = service.config.copyWith(httpsOnly: true);
        await service.updateConfig(httpsOnlyConfig);
        
        expect(service.shouldBlockUrl('http://example.com'), isTrue);
        expect(service.shouldBlockUrl('https://example.com'), isFalse);
      });

      test('should block invalid URLs', () {
        expect(service.shouldBlockUrl('invalid-url'), isTrue);
        expect(service.shouldBlockUrl(''), isTrue);
      });
    });

    group('Resource Blocking', () {
      test('should block JavaScript when disabled', () async {
        final noJsConfig = service.config.copyWith(enableJavaScript: false);
        await service.updateConfig(noJsConfig);
        
        expect(service.shouldBlockResource('https://example.com/script.js', 'script'), isTrue);
        expect(service.shouldBlockResource('https://example.com/image.jpg', 'image'), isFalse);
      });

      test('should block images when disabled', () async {
        final noImagesConfig = service.config.copyWith(enableImages: false);
        await service.updateConfig(noImagesConfig);
        
        expect(service.shouldBlockResource('https://example.com/image.jpg', 'image'), isTrue);
        expect(service.shouldBlockResource('https://example.com/script.js', 'script'), isFalse);
      });

      test('should block popups when disabled', () async {
        final noPopupsConfig = service.config.copyWith(enablePopups: false);
        await service.updateConfig(noPopupsConfig);
        
        expect(service.shouldBlockResource('https://example.com/popup', 'popup'), isTrue);
      });

      test('should block tracking resources when enabled', () async {
        final blockTrackersConfig = service.config.copyWith(blockTrackers: true);
        await service.updateConfig(blockTrackersConfig);
        
        expect(service.shouldBlockResource('https://google-analytics.com/analytics.js', 'script'), isTrue);
        expect(service.shouldBlockResource('https://googletagmanager.com/gtm.js', 'script'), isTrue);
        expect(service.shouldBlockResource('https://facebook.com/tr', 'image'), isTrue);
        expect(service.shouldBlockResource('https://example.com/script.js', 'script'), isFalse);
      });

      test('should block ad resources when enabled', () async {
        final blockAdsConfig = service.config.copyWith(blockAds: true);
        await service.updateConfig(blockAdsConfig);
        
        expect(service.shouldBlockResource('https://googlesyndication.com/ads.js', 'script'), isTrue);
        expect(service.shouldBlockResource('https://doubleclick.net/ad', 'image'), isTrue);
        expect(service.shouldBlockResource('https://example.com/ads/banner.jpg', 'image'), isTrue);
        expect(service.shouldBlockResource('https://example.com/content.jpg', 'image'), isFalse);
      });
    });

    group('Permission Management', () {
      test('should deny permissions by default for moderate security', () {
        expect(service.shouldGrantPermission('https://example.com', 'geolocation'), isFalse);
        expect(service.shouldGrantPermission('https://example.com', 'camera'), isFalse);
        expect(service.shouldGrantPermission('https://example.com', 'microphone'), isFalse);
        expect(service.shouldGrantPermission('https://example.com', 'notifications'), isFalse);
      });

      test('should grant permissions when enabled in config', () async {
        final permissiveConfig = service.config.copyWith(
          enableGeolocation: true,
          enableCamera: true,
          enableMicrophone: true,
          enableNotifications: true,
        );
        await service.updateConfig(permissiveConfig);
        
        expect(service.shouldGrantPermission('https://example.com', 'geolocation'), isTrue);
        expect(service.shouldGrantPermission('https://example.com', 'camera'), isTrue);
        expect(service.shouldGrantPermission('https://example.com', 'microphone'), isTrue);
        expect(service.shouldGrantPermission('https://example.com', 'notifications'), isTrue);
      });

      test('should always grant permissions for trusted domains', () async {
        await service.trustDomain('trusted-site.com');
        
        expect(service.shouldGrantPermission('https://trusted-site.com', 'geolocation'), isTrue);
        expect(service.shouldGrantPermission('https://trusted-site.com', 'camera'), isTrue);
        expect(service.shouldGrantPermission('https://trusted-site.com', 'microphone'), isTrue);
      });

      test('should handle unknown permissions based on security level', () async {
        // Strict security - deny unknown permissions
        final strictConfig = service.config.copyWith(securityLevel: SecurityLevel.strict);
        await service.updateConfig(strictConfig);
        expect(service.shouldGrantPermission('https://example.com', 'unknown'), isFalse);
        
        // Permissive security - allow unknown permissions
        final permissiveConfig = service.config.copyWith(securityLevel: SecurityLevel.permissive);
        await service.updateConfig(permissiveConfig);
        expect(service.shouldGrantPermission('https://example.com', 'unknown'), isTrue);
      });
    });

    group('Domain Management', () {
      test('should manage blocked domains', () async {
        expect(service.blockedDomains, isEmpty);
        
        await service.blockDomain('bad-site.com');
        expect(service.blockedDomains, contains('bad-site.com'));
        
        await service.unblockDomain('bad-site.com');
        expect(service.blockedDomains, isNot(contains('bad-site.com')));
      });

      test('should manage trusted domains', () async {
        expect(service.trustedDomains, isEmpty);
        
        await service.trustDomain('good-site.com');
        expect(service.trustedDomains, contains('good-site.com'));
        
        await service.untrustDomain('good-site.com');
        expect(service.trustedDomains, isNot(contains('good-site.com')));
      });

      test('should normalize domain names to lowercase', () async {
        await service.blockDomain('EXAMPLE.COM');
        expect(service.blockedDomains, contains('example.com'));
        
        await service.trustDomain('GOOGLE.COM');
        expect(service.trustedDomains, contains('google.com'));
      });
    });

    group('Cookie Management', () {
      test('should accept cookies based on policy', () async {
        // Accept all cookies
        final acceptAllConfig = service.config.copyWith(cookiePolicy: CookiePolicy.acceptAll);
        await service.updateConfig(acceptAllConfig);
        expect(service.shouldAcceptCookie('https://example.com', 'session', 'abc123'), isTrue);
        
        // Block all cookies
        final blockAllConfig = service.config.copyWith(cookiePolicy: CookiePolicy.blockAll);
        await service.updateConfig(blockAllConfig);
        expect(service.shouldAcceptCookie('https://example.com', 'session', 'abc123'), isFalse);
        
        // Block third-party (currently accepts all first-party)
        final blockThirdPartyConfig = service.config.copyWith(cookiePolicy: CookiePolicy.blockThirdParty);
        await service.updateConfig(blockThirdPartyConfig);
        expect(service.shouldAcceptCookie('https://example.com', 'session', 'abc123'), isTrue);
      });

      test('should store and retrieve cookies', () async {
        await service.storeCookie('example.com', 'session', 'abc123');
        await service.storeCookie('example.com', 'user', 'john');
        
        final cookies = service.getCookies('example.com');
        expect(cookies['session'], equals('abc123'));
        expect(cookies['user'], equals('john'));
        
        final emptyCookies = service.getCookies('other-site.com');
        expect(emptyCookies, isEmpty);
      });

      test('should clear cookies', () async {
        await service.storeCookie('example.com', 'session', 'abc123');
        await service.storeCookie('google.com', 'user', 'jane');
        
        // Clear domain-specific cookies
        await service.clearDomainCookies('example.com');
        expect(service.getCookies('example.com'), isEmpty);
        expect(service.getCookies('google.com'), isNotEmpty);
        
        // Clear all cookies
        await service.clearAllCookies();
        expect(service.getCookies('google.com'), isEmpty);
      });
    });

    group('User Agent', () {
      test('should return null user agent by default', () {
        expect(service.getUserAgent(), isNull);
      });

      test('should return custom user agent when set', () async {
        const customUserAgent = 'CustomBrowser/1.0';
        final configWithUserAgent = service.config.copyWith(userAgent: customUserAgent);
        await service.updateConfig(configWithUserAgent);
        
        expect(service.getUserAgent(), equals(customUserAgent));
      });
    });

    group('Configuration Serialization', () {
      test('should serialize and deserialize configuration', () {
        final originalConfig = ContentSecurityConfig(
          securityLevel: SecurityLevel.strict,
          cookiePolicy: CookiePolicy.blockAll,
          blockTrackers: false,
          blockAds: true,
          enableJavaScript: false,
          httpsOnly: true,
          userAgent: 'TestAgent/1.0',
        );

        final json = originalConfig.toJson();
        final deserializedConfig = ContentSecurityConfig.fromJson(json);

        expect(deserializedConfig.securityLevel, equals(originalConfig.securityLevel));
        expect(deserializedConfig.cookiePolicy, equals(originalConfig.cookiePolicy));
        expect(deserializedConfig.blockTrackers, equals(originalConfig.blockTrackers));
        expect(deserializedConfig.blockAds, equals(originalConfig.blockAds));
        expect(deserializedConfig.enableJavaScript, equals(originalConfig.enableJavaScript));
        expect(deserializedConfig.httpsOnly, equals(originalConfig.httpsOnly));
        expect(deserializedConfig.userAgent, equals(originalConfig.userAgent));
      });
    });

    group('Reset Functionality', () {
      test('should reset to defaults', () async {
        // Modify configuration and add domains
        await service.updateConfig(service.config.copyWith(
          securityLevel: SecurityLevel.strict,
          blockAds: true,
        ));
        await service.blockDomain('blocked.com');
        await service.trustDomain('trusted.com');
        await service.storeCookie('example.com', 'test', 'value');

        // Reset to defaults
        await service.resetToDefaults();

        // Verify everything is reset
        expect(service.config.securityLevel, equals(SecurityLevel.moderate));
        expect(service.config.blockAds, isFalse);
        expect(service.blockedDomains, isEmpty);
        expect(service.trustedDomains, isEmpty);
        expect(service.getCookies('example.com'), isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle invalid URLs gracefully', () {
        expect(service.shouldBlockUrl(''), isTrue);
        expect(service.shouldBlockUrl('invalid-url'), isTrue);
        expect(service.shouldGrantPermission('invalid-url', 'camera'), isFalse);
        expect(service.shouldAcceptCookie('invalid-url', 'test', 'value'), isFalse);
      });
    });
  });
}
