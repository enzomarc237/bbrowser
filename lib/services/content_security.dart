import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Security level for content filtering
enum SecurityLevel {
  strict,
  moderate,
  permissive,
}

/// Cookie management policy
enum CookiePolicy {
  acceptAll,
  blockThirdParty,
  blockAll,
}

/// Content security configuration
class ContentSecurityConfig {
  const ContentSecurityConfig({
    this.securityLevel = SecurityLevel.moderate,
    this.cookiePolicy = CookiePolicy.blockThirdParty,
    this.blockTrackers = true,
    this.blockAds = false,
    this.enableJavaScript = true,
    this.enableImages = true,
    this.enablePopups = false,
    this.enableDownloads = true,
    this.enableGeolocation = false,
    this.enableCamera = false,
    this.enableMicrophone = false,
    this.enableNotifications = false,
    this.httpsOnly = false,
    this.blockMixedContent = true,
    this.userAgent,
  });

  final SecurityLevel securityLevel;
  final CookiePolicy cookiePolicy;
  final bool blockTrackers;
  final bool blockAds;
  final bool enableJavaScript;
  final bool enableImages;
  final bool enablePopups;
  final bool enableDownloads;
  final bool enableGeolocation;
  final bool enableCamera;
  final bool enableMicrophone;
  final bool enableNotifications;
  final bool httpsOnly;
  final bool blockMixedContent;
  final String? userAgent;

  ContentSecurityConfig copyWith({
    SecurityLevel? securityLevel,
    CookiePolicy? cookiePolicy,
    bool? blockTrackers,
    bool? blockAds,
    bool? enableJavaScript,
    bool? enableImages,
    bool? enablePopups,
    bool? enableDownloads,
    bool? enableGeolocation,
    bool? enableCamera,
    bool? enableMicrophone,
    bool? enableNotifications,
    bool? httpsOnly,
    bool? blockMixedContent,
    String? userAgent,
  }) {
    return ContentSecurityConfig(
      securityLevel: securityLevel ?? this.securityLevel,
      cookiePolicy: cookiePolicy ?? this.cookiePolicy,
      blockTrackers: blockTrackers ?? this.blockTrackers,
      blockAds: blockAds ?? this.blockAds,
      enableJavaScript: enableJavaScript ?? this.enableJavaScript,
      enableImages: enableImages ?? this.enableImages,
      enablePopups: enablePopups ?? this.enablePopups,
      enableDownloads: enableDownloads ?? this.enableDownloads,
      enableGeolocation: enableGeolocation ?? this.enableGeolocation,
      enableCamera: enableCamera ?? this.enableCamera,
      enableMicrophone: enableMicrophone ?? this.enableMicrophone,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      httpsOnly: httpsOnly ?? this.httpsOnly,
      blockMixedContent: blockMixedContent ?? this.blockMixedContent,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'securityLevel': securityLevel.index,
      'cookiePolicy': cookiePolicy.index,
      'blockTrackers': blockTrackers,
      'blockAds': blockAds,
      'enableJavaScript': enableJavaScript,
      'enableImages': enableImages,
      'enablePopups': enablePopups,
      'enableDownloads': enableDownloads,
      'enableGeolocation': enableGeolocation,
      'enableCamera': enableCamera,
      'enableMicrophone': enableMicrophone,
      'enableNotifications': enableNotifications,
      'httpsOnly': httpsOnly,
      'blockMixedContent': blockMixedContent,
      'userAgent': userAgent,
    };
  }

  factory ContentSecurityConfig.fromJson(Map<String, dynamic> json) {
    return ContentSecurityConfig(
      securityLevel: SecurityLevel.values[json['securityLevel'] ?? 1],
      cookiePolicy: CookiePolicy.values[json['cookiePolicy'] ?? 1],
      blockTrackers: json['blockTrackers'] ?? true,
      blockAds: json['blockAds'] ?? false,
      enableJavaScript: json['enableJavaScript'] ?? true,
      enableImages: json['enableImages'] ?? true,
      enablePopups: json['enablePopups'] ?? false,
      enableDownloads: json['enableDownloads'] ?? true,
      enableGeolocation: json['enableGeolocation'] ?? false,
      enableCamera: json['enableCamera'] ?? false,
      enableMicrophone: json['enableMicrophone'] ?? false,
      enableNotifications: json['enableNotifications'] ?? false,
      httpsOnly: json['httpsOnly'] ?? false,
      blockMixedContent: json['blockMixedContent'] ?? true,
      userAgent: json['userAgent'],
    );
  }
}

/// Content security service for managing web content security and privacy
class ContentSecurityService {
  static const String _configKey = 'content_security_config';
  static const String _cookiesKey = 'stored_cookies';
  static const String _blockedDomainsKey = 'blocked_domains';
  static const String _trustedDomainsKey = 'trusted_domains';

  ContentSecurityConfig _config = const ContentSecurityConfig();
  final Set<String> _blockedDomains = {};
  final Set<String> _trustedDomains = {};
  final Map<String, Map<String, String>> _storedCookies = {};

  // Callbacks for security events
  Function(String url, String reason)? onContentBlocked;
  Function(String domain, String reason)? onDomainBlocked;
  Function(String url, String permission)? onPermissionRequested;

  /// Gets the current security configuration
  ContentSecurityConfig get config => _config;

  /// Gets blocked domains
  Set<String> get blockedDomains => Set.from(_blockedDomains);

  /// Gets trusted domains
  Set<String> get trustedDomains => Set.from(_trustedDomains);

  /// Initializes the content security service
  Future<void> initialize() async {
    await _loadConfiguration();
    await _loadBlockedDomains();
    await _loadTrustedDomains();
    await _loadStoredCookies();
  }

  /// Updates the security configuration
  Future<void> updateConfig(ContentSecurityConfig newConfig) async {
    _config = newConfig;
    await _saveConfiguration();
  }

  /// Checks if a URL should be blocked
  bool shouldBlockUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();

      // Check if domain is explicitly blocked
      if (_blockedDomains.contains(domain)) {
        onContentBlocked?.call(url, 'Domain blocked');
        return true;
      }

      // Check if domain is trusted (bypass other checks)
      if (_trustedDomains.contains(domain)) {
        return false;
      }

      // Check HTTPS-only mode
      if (_config.httpsOnly && uri.scheme != 'https') {
        onContentBlocked?.call(url, 'HTTPS-only mode enabled');
        return true;
      }

      // Check mixed content
      if (_config.blockMixedContent && uri.scheme == 'http') {
        // This would need context about the parent page to determine if it's mixed content
        // For now, we'll allow HTTP unless HTTPS-only is enabled
      }

      return false;
    } catch (e) {
      debugPrint('Error checking URL: $e');
      return true; // Block invalid URLs
    }
  }

  /// Checks if a resource type should be blocked
  bool shouldBlockResource(String url, String resourceType) {
    if (shouldBlockUrl(url)) return true;

    switch (resourceType.toLowerCase()) {
      case 'script':
        if (!_config.enableJavaScript) {
          onContentBlocked?.call(url, 'JavaScript disabled');
          return true;
        }
        break;
      case 'image':
        if (!_config.enableImages) {
          onContentBlocked?.call(url, 'Images disabled');
          return true;
        }
        break;
      case 'popup':
        if (!_config.enablePopups) {
          onContentBlocked?.call(url, 'Popups blocked');
          return true;
        }
        break;
    }

    // Check for tracking scripts/pixels
    if (_config.blockTrackers && _isTrackingResource(url)) {
      onContentBlocked?.call(url, 'Tracking blocked');
      return true;
    }

    // Check for ads
    if (_config.blockAds && _isAdResource(url)) {
      onContentBlocked?.call(url, 'Ad blocked');
      return true;
    }

    return false;
  }

  /// Checks if a permission should be granted
  bool shouldGrantPermission(String url, String permission) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();

      // Check if domain is trusted
      if (_trustedDomains.contains(domain)) {
        return true;
      }

      // Check specific permissions based on config
      switch (permission.toLowerCase()) {
        case 'geolocation':
          return _config.enableGeolocation;
        case 'camera':
          return _config.enableCamera;
        case 'microphone':
          return _config.enableMicrophone;
        case 'notifications':
          return _config.enableNotifications;
        case 'downloads':
          return _config.enableDownloads;
        default:
          // Unknown permission, use security level
          switch (_config.securityLevel) {
            case SecurityLevel.strict:
              return false;
            case SecurityLevel.moderate:
              return false; // Require explicit permission
            case SecurityLevel.permissive:
              return true;
          }
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }

  /// Adds a domain to the blocked list
  Future<void> blockDomain(String domain) async {
    _blockedDomains.add(domain.toLowerCase());
    await _saveBlockedDomains();
    onDomainBlocked?.call(domain, 'User blocked');
  }

  /// Removes a domain from the blocked list
  Future<void> unblockDomain(String domain) async {
    _blockedDomains.remove(domain.toLowerCase());
    await _saveBlockedDomains();
  }

  /// Adds a domain to the trusted list
  Future<void> trustDomain(String domain) async {
    _trustedDomains.add(domain.toLowerCase());
    await _saveTrustedDomains();
  }

  /// Removes a domain from the trusted list
  Future<void> untrustDomain(String domain) async {
    _trustedDomains.remove(domain.toLowerCase());
    await _saveTrustedDomains();
  }

  /// Manages cookies based on policy
  bool shouldAcceptCookie(String url, String cookieName, String cookieValue) {
    try {
      final uri = Uri.parse(url);
      // Note: domain could be used for more sophisticated cookie policies
      // final domain = uri.host.toLowerCase();

      switch (_config.cookiePolicy) {
        case CookiePolicy.blockAll:
          return false;
        case CookiePolicy.blockThirdParty:
          // This would need context about the main page domain
          // For now, accept all first-party cookies
          return true;
        case CookiePolicy.acceptAll:
          return true;
      }
    } catch (e) {
      debugPrint('Error checking cookie: $e');
      return false;
    }
  }

  /// Stores a cookie
  Future<void> storeCookie(String domain, String name, String value) async {
    _storedCookies.putIfAbsent(domain, () => {});
    _storedCookies[domain]![name] = value;
    await _saveStoredCookies();
  }

  /// Gets cookies for a domain
  Map<String, String> getCookies(String domain) {
    return Map.from(_storedCookies[domain] ?? {});
  }

  /// Clears all cookies
  Future<void> clearAllCookies() async {
    _storedCookies.clear();
    await _saveStoredCookies();
  }

  /// Clears cookies for a specific domain
  Future<void> clearDomainCookies(String domain) async {
    _storedCookies.remove(domain);
    await _saveStoredCookies();
  }

  /// Gets the user agent string
  String? getUserAgent() {
    return _config.userAgent;
  }

  /// Checks if a resource is a tracking resource
  bool _isTrackingResource(String url) {
    final trackingPatterns = [
      'google-analytics.com',
      'googletagmanager.com',
      'facebook.com/tr',
      'doubleclick.net',
      'googlesyndication.com',
      'amazon-adsystem.com',
      'adsystem.amazon.com',
      'scorecardresearch.com',
      'quantserve.com',
      'outbrain.com',
      'taboola.com',
    ];

    return trackingPatterns.any((pattern) => url.contains(pattern));
  }

  /// Checks if a resource is an ad resource
  bool _isAdResource(String url) {
    final adPatterns = [
      '/ads/',
      '/advertisement/',
      'googlesyndication.com',
      'doubleclick.net',
      'amazon-adsystem.com',
      'adsystem.amazon.com',
      'outbrain.com',
      'taboola.com',
      'media.net',
      'adsense.google.com',
    ];

    return adPatterns.any((pattern) => url.contains(pattern));
  }

  /// Loads configuration from storage
  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        _config = ContentSecurityConfig.fromJson(configMap);
      }
    } catch (e) {
      debugPrint('Error loading security config: $e');
    }
  }

  /// Saves configuration to storage
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(_config.toJson());
      await prefs.setString(_configKey, configJson);
    } catch (e) {
      debugPrint('Error saving security config: $e');
    }
  }

  /// Loads blocked domains from storage
  Future<void> _loadBlockedDomains() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final domains = prefs.getStringList(_blockedDomainsKey) ?? [];
      _blockedDomains.addAll(domains);
    } catch (e) {
      debugPrint('Error loading blocked domains: $e');
    }
  }

  /// Saves blocked domains to storage
  Future<void> _saveBlockedDomains() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_blockedDomainsKey, _blockedDomains.toList());
    } catch (e) {
      debugPrint('Error saving blocked domains: $e');
    }
  }

  /// Loads trusted domains from storage
  Future<void> _loadTrustedDomains() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final domains = prefs.getStringList(_trustedDomainsKey) ?? [];
      _trustedDomains.addAll(domains);
    } catch (e) {
      debugPrint('Error loading trusted domains: $e');
    }
  }

  /// Saves trusted domains to storage
  Future<void> _saveTrustedDomains() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_trustedDomainsKey, _trustedDomains.toList());
    } catch (e) {
      debugPrint('Error saving trusted domains: $e');
    }
  }

  /// Loads stored cookies from storage
  Future<void> _loadStoredCookies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookiesJson = prefs.getString(_cookiesKey);
      if (cookiesJson != null) {
        final cookiesMap = jsonDecode(cookiesJson) as Map<String, dynamic>;
        _storedCookies.clear();
        cookiesMap.forEach((domain, cookies) {
          _storedCookies[domain] = Map<String, String>.from(cookies);
        });
      }
    } catch (e) {
      debugPrint('Error loading stored cookies: $e');
    }
  }

  /// Saves stored cookies to storage
  Future<void> _saveStoredCookies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookiesJson = jsonEncode(_storedCookies);
      await prefs.setString(_cookiesKey, cookiesJson);
    } catch (e) {
      debugPrint('Error saving stored cookies: $e');
    }
  }

  /// Resets all security settings to defaults
  Future<void> resetToDefaults() async {
    _config = const ContentSecurityConfig();
    _blockedDomains.clear();
    _trustedDomains.clear();
    _storedCookies.clear();

    await _saveConfiguration();
    await _saveBlockedDomains();
    await _saveTrustedDomains();
    await _saveStoredCookies();
  }
}
