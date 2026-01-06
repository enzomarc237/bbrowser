import 'package:equatable/equatable.dart';

/// Supported preference value types
enum PreferenceType {
  string,
  integer,
  double,
  boolean,
  list,
  map,
}

/// User preference entity for storing application settings
class UserPreference extends Equatable {
  /// Unique identifier for the preference
  final int id;
  
  /// Unique key for the preference
  final String key;
  
  /// String representation of the value
  final String? value;
  
  /// Type of the preference value
  final PreferenceType valueType;
  
  /// Category for grouping preferences
  final String category;
  
  /// Whether the value is encrypted
  final bool isEncrypted;
  
  /// When the preference was created
  final DateTime createdAt;
  
  /// When the preference was last updated
  final DateTime updatedAt;

  const UserPreference({
    required this.id,
    required this.key,
    this.value,
    required this.valueType,
    this.category = 'general',
    this.isEncrypted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a user preference from a database map
  factory UserPreference.fromMap(Map<String, dynamic> map) {
    return UserPreference(
      id: map['id'] as int,
      key: map['key'] as String,
      value: map['value'] as String?,
      valueType: _parseValueType(map['value_type'] as String),
      category: map['category'] as String? ?? 'general',
      isEncrypted: (map['is_encrypted'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert user preference to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'value_type': valueType.name,
      'category': category,
      'is_encrypted': isEncrypted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy of the preference with updated fields
  UserPreference copyWith({
    int? id,
    String? key,
    String? value,
    PreferenceType? valueType,
    String? category,
    bool? isEncrypted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreference(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      category: category ?? this.category,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a new preference with current timestamp
  factory UserPreference.create({
    required String key,
    required dynamic value,
    String category = 'general',
    bool isEncrypted = false,
  }) {
    final now = DateTime.now();
    final valueType = _inferValueType(value);
    final stringValue = _serializeValue(value, valueType);
    
    return UserPreference(
      id: 0, // Will be set by database
      key: key,
      value: stringValue,
      valueType: valueType,
      category: category,
      isEncrypted: isEncrypted,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update the preference value
  UserPreference updateValue(dynamic newValue) {
    final valueType = _inferValueType(newValue);
    final stringValue = _serializeValue(newValue, valueType);
    
    return copyWith(
      value: stringValue,
      valueType: valueType,
      updatedAt: DateTime.now(),
    );
  }

  /// Get the typed value
  T? getValue<T>() {
    if (value == null) return null;
    
    try {
      switch (valueType) {
        case PreferenceType.string:
          return value as T?;
        case PreferenceType.integer:
          return int.parse(value!) as T?;
        case PreferenceType.double:
          return double.parse(value!) as T?;
        case PreferenceType.boolean:
          return (value!.toLowerCase() == 'true') as T?;
        case PreferenceType.list:
          // Simple comma-separated list
          return value!.split(',').map((e) => e.trim()).toList() as T?;
        case PreferenceType.map:
          // Simple key=value pairs separated by semicolons
          final pairs = value!.split(';');
          final map = <String, String>{};
          for (final pair in pairs) {
            final parts = pair.split('=');
            if (parts.length == 2) {
              map[parts[0].trim()] = parts[1].trim();
            }
          }
          return map as T?;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get string value with default
  String getStringValue([String defaultValue = '']) {
    return getValue<String>() ?? defaultValue;
  }

  /// Get integer value with default
  int getIntValue([int defaultValue = 0]) {
    return getValue<int>() ?? defaultValue;
  }

  /// Get double value with default
  double getDoubleValue([double defaultValue = 0.0]) {
    return getValue<double>() ?? defaultValue;
  }

  /// Get boolean value with default
  bool getBoolValue([bool defaultValue = false]) {
    return getValue<bool>() ?? defaultValue;
  }

  /// Get list value with default
  List<String> getListValue([List<String> defaultValue = const []]) {
    return getValue<List<String>>() ?? defaultValue;
  }

  /// Get map value with default
  Map<String, String> getMapValue([Map<String, String> defaultValue = const {}]) {
    return getValue<Map<String, String>>() ?? defaultValue;
  }

  /// Validate preference data
  bool get isValid {
    return key.trim().isNotEmpty;
  }

  /// Check if preference matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return key.toLowerCase().contains(lowerQuery) ||
           category.toLowerCase().contains(lowerQuery) ||
           (value?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'valueType': valueType.name,
      'category': category,
      'isEncrypted': isEncrypted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON for import
  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      id: json['id'] as int,
      key: json['key'] as String,
      value: json['value'] as String?,
      valueType: _parseValueType(json['valueType'] as String),
      category: json['category'] as String? ?? 'general',
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Parse value type from string
  static PreferenceType _parseValueType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'string':
        return PreferenceType.string;
      case 'integer':
        return PreferenceType.integer;
      case 'double':
        return PreferenceType.double;
      case 'boolean':
        return PreferenceType.boolean;
      case 'list':
        return PreferenceType.list;
      case 'map':
        return PreferenceType.map;
      default:
        return PreferenceType.string;
    }
  }

  /// Infer value type from dynamic value
  static PreferenceType _inferValueType(dynamic value) {
    if (value is String) return PreferenceType.string;
    if (value is int) return PreferenceType.integer;
    if (value is double) return PreferenceType.double;
    if (value is bool) return PreferenceType.boolean;
    if (value is List) return PreferenceType.list;
    if (value is Map) return PreferenceType.map;
    return PreferenceType.string;
  }

  /// Serialize value to string
  static String? _serializeValue(dynamic value, PreferenceType type) {
    if (value == null) return null;
    
    switch (type) {
      case PreferenceType.string:
        return value.toString();
      case PreferenceType.integer:
      case PreferenceType.double:
      case PreferenceType.boolean:
        return value.toString();
      case PreferenceType.list:
        if (value is List) {
          return value.map((e) => e.toString()).join(',');
        }
        return value.toString();
      case PreferenceType.map:
        if (value is Map) {
          return value.entries
              .map((e) => '${e.key}=${e.value}')
              .join(';');
        }
        return value.toString();
    }
  }

  @override
  List<Object?> get props => [
        id,
        key,
        value,
        valueType,
        category,
        isEncrypted,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserPreference(id: $id, key: $key, value: $value, type: $valueType)';
  }
}

/// Common preference categories
class PreferenceCategories {
  static const String general = 'general';
  static const String appearance = 'appearance';
  static const String privacy = 'privacy';
  static const String security = 'security';
  static const String search = 'search';
  static const String session = 'session';
  static const String network = 'network';
  static const String advanced = 'advanced';
}

/// Common preference keys
class PreferenceKeys {
  // Appearance
  static const String themeMode = 'theme_mode';
  static const String fontSize = 'font_size';
  static const String showBookmarksBar = 'show_bookmarks_bar';
  
  // General
  static const String homepageUrl = 'homepage_url';
  static const String defaultSearchEngine = 'default_search_engine';
  static const String downloadPath = 'download_path';
  
  // Privacy
  static const String enableJavaScript = 'enable_javascript';
  static const String blockPopups = 'block_popups';
  static const String enableCookies = 'enable_cookies';
  static const String historyRetentionDays = 'history_retention_days';
  
  // Session
  static const String autoSaveSession = 'auto_save_session';
  static const String restoreSessionOnStartup = 'restore_session_on_startup';
  static const String maxTabsPerSession = 'max_tabs_per_session';
  
  // Security
  static const String enableHttpsOnly = 'enable_https_only';
  static const String blockMixedContent = 'block_mixed_content';
  static const String enableSafeMode = 'enable_safe_mode';
}
