import 'package:equatable/equatable.dart';
import 'dart:convert';

/// Represents a user preference setting
class UserPreference extends Equatable {
  const UserPreference({
    required this.id,
    required this.category,
    required this.key,
    required this.value,
    this.valueType = PreferenceValueType.string,
    this.description,
    this.isUserSetting = true,
    this.isEncrypted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for the preference
  final int id;

  /// Category of the preference (e.g., 'general', 'privacy', 'appearance')
  final String category;

  /// Key name of the preference
  final String key;

  /// Value of the preference (stored as string)
  final String value;

  /// Type of the value for proper parsing
  final PreferenceValueType valueType;

  /// Optional description of what this preference does
  final String? description;

  /// Whether this is a user-configurable setting
  final bool isUserSetting;

  /// Whether the value should be encrypted
  final bool isEncrypted;

  /// When the preference was created
  final DateTime createdAt;

  /// When the preference was last updated
  final DateTime updatedAt;

  /// Creates a copy of this preference with updated values
  UserPreference copyWith({
    int? id,
    String? category,
    String? key,
    String? value,
    PreferenceValueType? valueType,
    String? description,
    bool? isUserSetting,
    bool? isEncrypted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreference(
      id: id ?? this.id,
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      description: description ?? this.description,
      isUserSetting: isUserSetting ?? this.isUserSetting,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a new preference
  factory UserPreference.create({
    required String category,
    required String key,
    required dynamic value,
    PreferenceValueType? valueType,
    String? description,
    bool isUserSetting = true,
    bool isEncrypted = false,
  }) {
    final now = DateTime.now();
    final detectedType = valueType ?? _detectValueType(value);
    
    return UserPreference(
      id: 0, // Will be set by database
      category: category,
      key: key,
      value: _valueToString(value, detectedType),
      valueType: detectedType,
      description: description,
      isUserSetting: isUserSetting,
      isEncrypted: isEncrypted,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a preference from JSON data
  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      id: json['id'] as int,
      category: json['category'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      valueType: PreferenceValueType.values.firstWhere(
        (type) => type.name == (json['value_type'] as String),
        orElse: () => PreferenceValueType.string,
      ),
      description: json['description'] as String?,
      isUserSetting: (json['is_user_setting'] as int? ?? 1) == 1,
      isEncrypted: (json['is_encrypted'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }

  /// Creates a preference from database row
  factory UserPreference.fromDatabase(Map<String, dynamic> row) {
    return UserPreference.fromJson(row);
  }

  /// Converts the preference to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'key': key,
      'value': value,
      'value_type': valueType.name,
      'description': description,
      'is_user_setting': isUserSetting ? 1 : 0,
      'is_encrypted': isEncrypted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Converts the preference to database format
  Map<String, dynamic> toDatabase() {
    return toJson();
  }

  /// Get the typed value of the preference
  T getValue<T>() {
    switch (valueType) {
      case PreferenceValueType.string:
        return value as T;
      case PreferenceValueType.integer:
        return int.parse(value) as T;
      case PreferenceValueType.double:
        return double.parse(value) as T;
      case PreferenceValueType.boolean:
        return (value.toLowerCase() == 'true') as T;
      case PreferenceValueType.json:
        return jsonDecode(value) as T;
      case PreferenceValueType.list:
        return (value.split(',').map((s) => s.trim()).toList()) as T;
    }
  }

  /// Get the value as a string
  String get stringValue => getValue<String>();

  /// Get the value as an integer
  int get intValue => getValue<int>();

  /// Get the value as a double
  double get doubleValue => getValue<double>();

  /// Get the value as a boolean
  bool get boolValue => getValue<bool>();

  /// Get the value as a JSON object
  Map<String, dynamic> get jsonValue => getValue<Map<String, dynamic>>();

  /// Get the value as a list
  List<String> get listValue => getValue<List<String>>();

  /// Update the value with proper type conversion
  UserPreference updateValue(dynamic newValue) {
    final newValueType = _detectValueType(newValue);
    return copyWith(
      value: _valueToString(newValue, newValueType),
      valueType: newValueType,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if preference is valid
  bool get isValid {
    try {
      // Try to parse the value according to its type
      switch (valueType) {
        case PreferenceValueType.integer:
          int.parse(value);
          break;
        case PreferenceValueType.double:
          double.parse(value);
          break;
        case PreferenceValueType.boolean:
          final lower = value.toLowerCase();
          if (lower != 'true' && lower != 'false') return false;
          break;
        case PreferenceValueType.json:
          jsonDecode(value);
          break;
        case PreferenceValueType.string:
        case PreferenceValueType.list:
          // Always valid for strings and lists
          break;
      }
      return category.isNotEmpty && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get full preference identifier
  String get fullKey => '$category.$key';

  /// Check if this preference matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return category.toLowerCase().contains(lowerQuery) ||
           key.toLowerCase().contains(lowerQuery) ||
           value.toLowerCase().contains(lowerQuery) ||
           (description?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Static helper to detect value type
  static PreferenceValueType _detectValueType(dynamic value) {
    if (value is bool) return PreferenceValueType.boolean;
    if (value is int) return PreferenceValueType.integer;
    if (value is double) return PreferenceValueType.double;
    if (value is List) return PreferenceValueType.list;
    if (value is Map) return PreferenceValueType.json;
    return PreferenceValueType.string;
  }

  /// Static helper to convert value to string
  static String _valueToString(dynamic value, PreferenceValueType type) {
    switch (type) {
      case PreferenceValueType.string:
        return value.toString();
      case PreferenceValueType.integer:
        return value.toString();
      case PreferenceValueType.double:
        return value.toString();
      case PreferenceValueType.boolean:
        return value.toString();
      case PreferenceValueType.json:
        return jsonEncode(value);
      case PreferenceValueType.list:
        if (value is List) {
          return value.join(',');
        }
        return value.toString();
    }
  }

  @override
  List<Object?> get props => [
        id,
        category,
        key,
        value,
        valueType,
        description,
        isUserSetting,
        isEncrypted,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserPreference(category: $category, key: $key, value: $value, type: $valueType)';
  }
}

/// Types of preference values
enum PreferenceValueType {
  string,
  integer,
  double,
  boolean,
  json,
  list,
}

/// Predefined preference categories
class PreferenceCategories {
  static const String general = 'general';
  static const String privacy = 'privacy';
  static const String appearance = 'appearance';
  static const String security = 'security';
  static const String performance = 'performance';
  static const String network = 'network';
  static const String downloads = 'downloads';
  static const String notifications = 'notifications';
  static const String accessibility = 'accessibility';
  static const String developer = 'developer';
  static const String experimental = 'experimental';
  static const String sync = 'sync';
  static const String search = 'search';
  static const String content = 'content';
  static const String extensions = 'extensions';
}

/// Predefined preference keys
class PreferenceKeys {
  // General preferences
  static const String defaultSearchEngine = 'default_search_engine';
  static const String homePage = 'home_page';
  static const String startupBehavior = 'startup_behavior';
  static const String downloadLocation = 'download_location';
  static const String language = 'language';
  static const String timezone = 'timezone';

  // Privacy preferences
  static const String trackingProtection = 'tracking_protection';
  static const String cookiePolicy = 'cookie_policy';
  static const String dntHeader = 'dnt_header';
  static const String clearDataOnExit = 'clear_data_on_exit';
  static const String incognitoMode = 'incognito_mode';
  static const String passwordSaving = 'password_saving';

  // Appearance preferences
  static const String theme = 'theme';
  static const String fontSize = 'font_size';
  static const String fontFamily = 'font_family';
  static const String showBookmarksBar = 'show_bookmarks_bar';
  static const String showTabBar = 'show_tab_bar';
  static const String compactMode = 'compact_mode';

  // Security preferences
  static const String httpsOnly = 'https_only';
  static const String certificateValidation = 'certificate_validation';
  static const String mixedContentBlocking = 'mixed_content_blocking';
  static const String safeBrowsing = 'safe_browsing';
  static const String passwordManager = 'password_manager';

  // Performance preferences
  static const String hardwareAcceleration = 'hardware_acceleration';
  static const String preloadPages = 'preload_pages';
  static const String backgroundSync = 'background_sync';
  static const String memoryOptimization = 'memory_optimization';
  static const String diskCache = 'disk_cache';

  // Network preferences
  static const String proxySettings = 'proxy_settings';
  static const String dnsOverHttps = 'dns_over_https';
  static const String networkPrediction = 'network_prediction';
  static const String connectionTimeout = 'connection_timeout';

  // Content preferences
  static const String javascriptEnabled = 'javascript_enabled';
  static const String imagesEnabled = 'images_enabled';
  static const String popupBlocking = 'popup_blocking';
  static const String autoplayPolicy = 'autoplay_policy';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String locationSharing = 'location_sharing';
  static const String cameraAccess = 'camera_access';
  static const String microphoneAccess = 'microphone_access';

  // Developer preferences
  static const String developerMode = 'developer_mode';
  static const String debugLogging = 'debug_logging';
  static const String consoleLogging = 'console_logging';
  static const String networkLogging = 'network_logging';
  static const String performanceLogging = 'performance_logging';
}

/// Default preference values
class DefaultPreferences {
  static final Map<String, UserPreference> defaults = {
    // General
    '${PreferenceCategories.general}.${PreferenceKeys.defaultSearchEngine}': 
      UserPreference.create(
        category: PreferenceCategories.general,
        key: PreferenceKeys.defaultSearchEngine,
        value: 'https://www.google.com/search?q=%s',
        description: 'Default search engine URL',
      ),
    
    '${PreferenceCategories.general}.${PreferenceKeys.homePage}': 
      UserPreference.create(
        category: PreferenceCategories.general,
        key: PreferenceKeys.homePage,
        value: 'about:blank',
        description: 'Home page URL',
      ),
    
    '${PreferenceCategories.general}.${PreferenceKeys.startupBehavior}': 
      UserPreference.create(
        category: PreferenceCategories.general,
        key: PreferenceKeys.startupBehavior,
        value: 'restore_session',
        description: 'What to do on startup',
      ),

    // Privacy
    '${PreferenceCategories.privacy}.${PreferenceKeys.trackingProtection}': 
      UserPreference.create(
        category: PreferenceCategories.privacy,
        key: PreferenceKeys.trackingProtection,
        value: true,
        description: 'Enable tracking protection',
      ),
    
    '${PreferenceCategories.privacy}.${PreferenceKeys.cookiePolicy}': 
      UserPreference.create(
        category: PreferenceCategories.privacy,
        key: PreferenceKeys.cookiePolicy,
        value: 'block_third_party',
        description: 'Cookie acceptance policy',
      ),

    // Appearance
    '${PreferenceCategories.appearance}.${PreferenceKeys.theme}': 
      UserPreference.create(
        category: PreferenceCategories.appearance,
        key: PreferenceKeys.theme,
        value: 'system',
        description: 'UI theme (light, dark, system)',
      ),
    
    '${PreferenceCategories.appearance}.${PreferenceKeys.fontSize}': 
      UserPreference.create(
        category: PreferenceCategories.appearance,
        key: PreferenceKeys.fontSize,
        value: 16,
        description: 'Default font size',
      ),

    // Security
    '${PreferenceCategories.security}.${PreferenceKeys.httpsOnly}': 
      UserPreference.create(
        category: PreferenceCategories.security,
        key: PreferenceKeys.httpsOnly,
        value: false,
        description: 'Force HTTPS connections',
      ),
    
    '${PreferenceCategories.security}.${PreferenceKeys.safeBrowsing}': 
      UserPreference.create(
        category: PreferenceCategories.security,
        key: PreferenceKeys.safeBrowsing,
        value: true,
        description: 'Enable safe browsing protection',
      ),

    // Performance
    '${PreferenceCategories.performance}.${PreferenceKeys.hardwareAcceleration}': 
      UserPreference.create(
        category: PreferenceCategories.performance,
        key: PreferenceKeys.hardwareAcceleration,
        value: true,
        description: 'Use hardware acceleration when available',
      ),

    // Content
    '${PreferenceCategories.content}.${PreferenceKeys.javascriptEnabled}': 
      UserPreference.create(
        category: PreferenceCategories.content,
        key: PreferenceKeys.javascriptEnabled,
        value: true,
        description: 'Enable JavaScript execution',
      ),
    
    '${PreferenceCategories.content}.${PreferenceKeys.popupBlocking}': 
      UserPreference.create(
        category: PreferenceCategories.content,
        key: PreferenceKeys.popupBlocking,
        value: true,
        description: 'Block popup windows',
      ),
  };

  /// Get default preference by full key
  static UserPreference? getDefault(String fullKey) {
    return defaults[fullKey];
  }

  /// Get all default preferences for a category
  static List<UserPreference> getDefaultsForCategory(String category) {
    return defaults.values
        .where((pref) => pref.category == category)
        .toList();
  }

  /// Get all default preferences
  static List<UserPreference> getAllDefaults() {
    return defaults.values.toList();
  }
}
