import 'dart:io';

/// Result of URL validation
class UrlValidationResult {
  const UrlValidationResult({
    required this.isValid,
    required this.normalizedUrl,
    this.error,
    this.scheme,
    this.host,
    this.port,
    this.path,
    this.isSecure = false,
    this.isLocal = false,
    this.isSearch = false,
  });

  final bool isValid;
  final String normalizedUrl;
  final String? error;
  final String? scheme;
  final String? host;
  final int? port;
  final String? path;
  final bool isSecure;
  final bool isLocal;
  final bool isSearch;

  @override
  String toString() {
    return 'UrlValidationResult(isValid: $isValid, normalizedUrl: $normalizedUrl, error: $error)';
  }
}

/// Service for validating and normalizing URLs
class UrlValidator {
  static const List<String> _supportedSchemes = [
    'http',
    'https',
    'file',
    'ftp',
    'ftps',
    'data',
    'about',
  ];

  static const List<String> _searchEngines = [
    'google.com',
    'bing.com',
    'duckduckgo.com',
    'yahoo.com',
    'yandex.com',
    'baidu.com',
  ];

  static const String _defaultSearchEngine = 'https://www.google.com/search?q=';
  static const String _defaultScheme = 'https';

  /// Validates and normalizes a URL input
  static UrlValidationResult validate(String input) {
    if (input.trim().isEmpty) {
      return const UrlValidationResult(
        isValid: false,
        normalizedUrl: '',
        error: 'URL cannot be empty',
      );
    }

    final trimmedInput = input.trim();

    // Handle special URLs
    if (_isSpecialUrl(trimmedInput)) {
      return _handleSpecialUrl(trimmedInput);
    }

    // Try to parse as URI
    try {
      Uri uri;
      
      // If input doesn't have a scheme, try to determine what it is
      if (!_hasScheme(trimmedInput)) {
        final result = _inferUrlType(trimmedInput);
        if (result != null) return result;
        
        // Default to HTTPS for domain-like inputs
        uri = Uri.parse('$_defaultScheme://$trimmedInput');
      } else {
        uri = Uri.parse(trimmedInput);
      }

      return _validateUri(uri, trimmedInput);
    } catch (e) {
      // If parsing fails, treat as search query
      return _createSearchUrl(trimmedInput);
    }
  }

  /// Validates a URI object
  static UrlValidationResult _validateUri(Uri uri, String originalInput) {
    // Check if scheme is supported
    if (!_supportedSchemes.contains(uri.scheme.toLowerCase())) {
      return UrlValidationResult(
        isValid: false,
        normalizedUrl: originalInput,
        error: 'Unsupported URL scheme: ${uri.scheme}',
      );
    }

    // Validate host for network schemes
    if (_isNetworkScheme(uri.scheme)) {
      if (uri.host.isEmpty) {
        return UrlValidationResult(
          isValid: false,
          normalizedUrl: originalInput,
          error: 'Invalid host name',
        );
      }

      // Check for valid host format
      if (!_isValidHost(uri.host)) {
        return UrlValidationResult(
          isValid: false,
          normalizedUrl: originalInput,
          error: 'Invalid host format: ${uri.host}',
        );
      }
    }

    // Validate port
    if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
      return UrlValidationResult(
        isValid: false,
        normalizedUrl: originalInput,
        error: 'Invalid port number: ${uri.port}',
      );
    }

    // Create normalized URL
    final normalizedUrl = _normalizeUri(uri);

    return UrlValidationResult(
      isValid: true,
      normalizedUrl: normalizedUrl,
      scheme: uri.scheme,
      host: uri.host.isNotEmpty ? uri.host : null,
      port: uri.hasPort ? uri.port : null,
      path: uri.path.isNotEmpty ? uri.path : null,
      isSecure: _isSecureScheme(uri.scheme),
      isLocal: _isLocalHost(uri.host),
    );
  }

  /// Checks if input has a URL scheme
  static bool _hasScheme(String input) {
    return input.contains('://') || input.startsWith('about:') || input.startsWith('data:');
  }

  /// Checks if scheme is for network protocols
  static bool _isNetworkScheme(String scheme) {
    return ['http', 'https', 'ftp', 'ftps'].contains(scheme.toLowerCase());
  }

  /// Checks if scheme is secure
  static bool _isSecureScheme(String scheme) {
    return ['https', 'ftps'].contains(scheme.toLowerCase());
  }

  /// Checks if host is localhost
  static bool _isLocalHost(String host) {
    return ['localhost', '127.0.0.1', '::1', '0.0.0.0'].contains(host.toLowerCase());
  }

  /// Validates host format
  static bool _isValidHost(String host) {
    if (host.isEmpty) return false;

    // Check for IP address
    if (_isValidIpAddress(host)) return true;

    // Check for domain name
    if (_isValidDomainName(host)) return true;

    return false;
  }

  /// Validates IP address format
  static bool _isValidIpAddress(String host) {
    try {
      final address = InternetAddress(host);
      return address.address == host;
    } catch (e) {
      return false;
    }
  }

  /// Validates domain name format
  static bool _isValidDomainName(String host) {
    // Basic domain name validation
    final domainRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$',
    );
    
    return domainRegex.hasMatch(host) && host.length <= 253;
  }

  /// Infers URL type from input without scheme
  static UrlValidationResult? _inferUrlType(String input) {
    // Check if it looks like a domain
    if (_looksLikeDomain(input)) {
      return null; // Let the main logic handle it
    }

    // Check if it looks like a file path
    if (_looksLikeFilePath(input)) {
      return _handleFilePath(input);
    }

    // Check if it's an IP address
    if (_isValidIpAddress(input)) {
      return null; // Let the main logic handle it
    }

    // If none of the above, treat as search
    return _createSearchUrl(input);
  }

  /// Checks if input looks like a domain
  static bool _looksLikeDomain(String input) {
    // Must contain at least one dot
    if (!input.contains('.')) return false;

    // Must not contain spaces
    if (input.contains(' ')) return false;

    // Must not contain common search terms
    if (input.contains(' ') || input.contains('?') || input.contains('=')) {
      return false;
    }

    // Check if it has a valid TLD
    final parts = input.split('.');
    if (parts.length < 2) return false;

    final tld = parts.last.toLowerCase();
    return tld.length >= 2 && tld.length <= 6 && RegExp(r'^[a-z]+$').hasMatch(tld);
  }

  /// Checks if input looks like a file path
  static bool _looksLikeFilePath(String input) {
    return input.startsWith('/') || 
           input.startsWith('./') || 
           input.startsWith('../') ||
           (Platform.isWindows && input.contains(':\\'));
  }

  /// Handles file path inputs
  static UrlValidationResult _handleFilePath(String input) {
    try {
      final uri = Uri.file(input);
      return UrlValidationResult(
        isValid: true,
        normalizedUrl: uri.toString(),
        scheme: 'file',
        path: input,
      );
    } catch (e) {
      return UrlValidationResult(
        isValid: false,
        normalizedUrl: input,
        error: 'Invalid file path: $input',
      );
    }
  }

  /// Handles special URLs like about:blank
  static bool _isSpecialUrl(String input) {
    return input.startsWith('about:') || 
           input.startsWith('data:') ||
           input == 'localhost' ||
           input.startsWith('chrome://') ||
           input.startsWith('edge://') ||
           input.startsWith('safari://');
  }

  /// Handles special URL cases
  static UrlValidationResult _handleSpecialUrl(String input) {
    if (input.startsWith('about:')) {
      return UrlValidationResult(
        isValid: true,
        normalizedUrl: input,
        scheme: 'about',
      );
    }

    if (input.startsWith('data:')) {
      return UrlValidationResult(
        isValid: true,
        normalizedUrl: input,
        scheme: 'data',
      );
    }

    if (input == 'localhost') {
      return const UrlValidationResult(
        isValid: true,
        normalizedUrl: 'http://localhost',
        scheme: 'http',
        host: 'localhost',
        isLocal: true,
      );
    }

    // Handle browser-specific URLs by converting to about:blank
    return const UrlValidationResult(
      isValid: true,
      normalizedUrl: 'about:blank',
      scheme: 'about',
    );
  }

  /// Creates a search URL from query
  static UrlValidationResult _createSearchUrl(String query) {
    final encodedQuery = Uri.encodeComponent(query);
    final searchUrl = '$_defaultSearchEngine$encodedQuery';

    return UrlValidationResult(
      isValid: true,
      normalizedUrl: searchUrl,
      scheme: 'https',
      host: 'www.google.com',
      isSecure: true,
      isSearch: true,
    );
  }

  /// Normalizes a URI to a standard format
  static String _normalizeUri(Uri uri) {
    // Build normalized URI
    final buffer = StringBuffer();
    
    // Add scheme
    buffer.write(uri.scheme.toLowerCase());
    buffer.write('://');
    
    // Add host (convert to lowercase for network schemes)
    if (uri.host.isNotEmpty) {
      if (_isNetworkScheme(uri.scheme)) {
        buffer.write(uri.host.toLowerCase());
      } else {
        buffer.write(uri.host);
      }
    }
    
    // Add port if not default
    if (uri.hasPort && !_isDefaultPort(uri.scheme, uri.port)) {
      buffer.write(':${uri.port}');
    }
    
    // Add path
    if (uri.path.isNotEmpty && uri.path != '/') {
      buffer.write(uri.path);
    } else if (_isNetworkScheme(uri.scheme)) {
      buffer.write('/');
    }
    
    // Add query
    if (uri.query.isNotEmpty) {
      buffer.write('?${uri.query}');
    }
    
    // Add fragment
    if (uri.fragment.isNotEmpty) {
      buffer.write('#${uri.fragment}');
    }
    
    return buffer.toString();
  }

  /// Checks if port is default for scheme
  static bool _isDefaultPort(String scheme, int port) {
    switch (scheme.toLowerCase()) {
      case 'http':
        return port == 80;
      case 'https':
        return port == 443;
      case 'ftp':
        return port == 21;
      case 'ftps':
        return port == 990;
      default:
        return false;
    }
  }

  /// Validates URL for security concerns
  static bool isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return _isSecureScheme(uri.scheme);
    } catch (e) {
      return false;
    }
  }

  /// Checks if URL is a local resource
  static bool isLocalUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return _isLocalHost(uri.host) || uri.scheme == 'file';
    } catch (e) {
      return false;
    }
  }

  /// Extracts domain from URL
  static String? extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : null;
    } catch (e) {
      return null;
    }
  }

  /// Checks if URL is a search query
  static bool isSearchUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return _searchEngines.any((engine) => uri.host.contains(engine)) &&
             uri.path.contains('search');
    } catch (e) {
      return false;
    }
  }

  /// Gets the base URL (scheme + host + port)
  static String? getBaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return null;
      
      final buffer = StringBuffer();
      buffer.write(uri.scheme);
      buffer.write('://');
      buffer.write(uri.host);
      
      if (uri.hasPort && !_isDefaultPort(uri.scheme, uri.port)) {
        buffer.write(':${uri.port}');
      }
      
      return buffer.toString();
    } catch (e) {
      return null;
    }
  }

  /// Resolves a relative URL against a base URL
  static String? resolveUrl(String baseUrl, String relativeUrl) {
    try {
      final base = Uri.parse(baseUrl);
      final resolved = base.resolve(relativeUrl);
      return resolved.toString();
    } catch (e) {
      return null;
    }
  }
}
