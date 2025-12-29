# Browser Technical Specifications

## Development Requirements

### System Requirements
- **macOS**: 11.0 or later (Intel or Apple Silicon)
- **Flutter**: 3.16.0 or later (stable channel)
- **Dart**: 3.2.0 or later
- **Xcode**: 14.2 or later
- **CocoaPods**: Latest version
- **RAM**: Minimum 8GB (16GB recommended)
- **Disk**: 10GB for Flutter SDK + project dependencies

### Target Deployment
- **Minimum macOS**: 11.0 (Big Sur)
- **Recommended macOS**: 12.0+ (Monterey+)
- **Architecture**: Both Intel and Apple Silicon (universal binary)

## Core Dependencies

### State Management & Reactive
```yaml
flutter_bloc: ^8.1.0          # BLoC pattern implementation
bloc: ^8.1.0                  # Core BLoC logic
equatable: ^2.0.5             # Value equality for events/states
provider: ^6.0.0              # Alternative: Provider pattern
```

### WebView & Networking
```yaml
webview_flutter: ^4.7.0       # WebView for macOS
webview_flutter_wkwebview: ^3.0.0  # WebKit WebView
dio: ^5.3.0                   # HTTP client with interceptors
dio_smart_retry: ^6.0.0       # Retry logic with exponential backoff
pretty_dio_logger: ^1.3.0     # HTTP request/response logging
```

### Local Storage & Database
```yaml
hive: ^2.2.0                  # Lightweight key-value store
hive_flutter: ^1.1.0          # Flutter integration
sqflite: ^2.3.0               # SQLite for structured data
path_provider: ^2.1.0         # System directory access
shared_preferences: ^2.2.0    # Simple preference storage
```

### Security & Encryption
```yaml
flutter_secure_storage: ^9.0.0  # Keychain credential storage
pointycastle: ^3.7.0            # Cryptographic operations
```

### UI & Navigation
```yaml
macos_ui: ^1.13.0             # Native macOS UI components & styling
go_router: ^11.1.0            # Declarative routing & deep linking
google_fonts: ^6.0.0          # Font management
flutter_svg: ^2.0.0           # SVG rendering
cached_network_image: ^3.3.0  # Image caching
animations: ^2.0.7            # Material motion animations
```

### Analytics & Logging
```yaml
firebase_analytics: ^10.4.0    # Event analytics
firebase_crashlytics: ^11.3.0  # Crash reporting
logger: ^2.0.0                # Application logging
```

### Code Generation & Utilities
```yaml
intl: ^0.19.0                 # Internationalization
get_it: ^7.6.0                # Service locator (dependency injection)
freezed: ^2.4.0               # Code generation for immutable models
freezed_annotation: ^2.4.0    # Freezed annotations
json_serializable: ^6.7.0     # JSON serialization
```

### Development Dependencies
```yaml
flutter_test:
  sdk: flutter

mocktail: ^1.0.0              # Mocking library
bloc_test: ^9.1.0             # BLoC testing utilities
test: ^1.24.0                 # Unit testing framework
integration_test:
  sdk: flutter
```

## Browser-Specific Libraries

### WebView Management
```yaml
# Core WebView support (already in flutter_macos)
webview_flutter: ^4.7.0
webview_flutter_wkwebview: ^3.0.0  # WebKit engine

# For advanced WebView features
javascript_channel: ^1.0.0    # Dart-JavaScript bridge
```

### History & Database Schema
```yaml
sqflite: ^2.3.0               # SQLite for history/bookmarks
drift: ^2.14.0                # ORM for type-safe queries (optional)
```

### Download Management
```yaml
dio_downloader_plugin: ^1.0.0 # Download file management
path_provider: ^2.1.0         # Download directory access
```

## API & Service Architecture

### WebView Integration Strategy
**Approach**: Full WebKit WebView with custom controls
- Embed webkit WebView in Flutter
- Custom UI layer for browser controls
- JavaScript channel for communication
- Support for all web standards

### Browser Data Persistence

```
SQLite Schema:

tabs (id, title, url, favicon, position, pinned, created_at, closed_at)
history (id, url, title, favicon, timestamp, visit_count, favicon_data)
bookmarks (id, url, title, folder_id, created_at, position)
bookmark_folders (id, title, parent_id, position)
settings (key, value, user_id, updated_at)
downloads (id, url, filename, path, size, status, created_at)
```

### Hive Boxes
```yaml
app_state:
  - current_tab_id
  - window_size
  - window_position
  - sidebar_width

preferences:
  - theme_mode (dark/light)
  - search_engine
  - homepage_url
  - startup_behavior

session:
  - open_tabs (serialized)
  - last_active_tab
  - scroll_positions (per URL)
```

## Performance Targets

### Startup Time
- **Cold start**: < 1 second
- **Warm start**: < 300ms
- **Time to interactive**: < 1.5 seconds

### Responsiveness
- **UI frame rate**: 60 FPS minimum (120 FPS on supported displays)
- **Tab switching**: < 100ms
- **Page load indication**: Instant visual feedback

### Memory Usage
- **Idle**: < 80MB
- **Single tab browsing**: < 150MB
- **Multiple tabs (5-10)**: < 300MB
- **Max recommended**: < 500MB

### Network
- **DNS resolution**: < 100ms (with caching)
- **Page render**: < 2 seconds typical
- **Favicon load**: < 500ms
- **History search**: < 200ms

## macOS-Specific Configuration

### Info.plist Settings
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Allow Browser to discover local network resources</string>

<key>NSBonjourServiceTypes</key>
<array>
    <string>_http._tcp</string>
    <string>_https._tcp</string>
</array>

<key>NSPhotoLibraryUsageDescription</key>
<string>Allow Browser to access your photo library for file uploads</string>

<key>NSDocumentsFolderUsageDescription</key>
<string>Allow Browser to access your documents for downloads</string>
```

### Entitlements (Debugging & Release)
```xml
<!-- Network access -->
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>

<!-- File access -->
<key>com.apple.security.files.downloads-folder-level</key>
<string>readwrite</string>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>

<!-- Hardware -->
<key>com.apple.security.device.camera</key>
<true/>
<key>com.apple.security.device.microphone</key>
<true/>

<!-- Keychain -->
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.yourcompany.browser</string>
</array>
```

## Build Configuration

### pubspec.yaml Structure
```yaml
name: webkit_browser
description: A native macOS browser built with Flutter
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.16.0'

dependencies:
  flutter:
    sdk: flutter
  # ... dependencies listed above

dev_dependencies:
  flutter_test:
    sdk: flutter
  # ... development dependencies listed above

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
  fonts:
    - family: InterVariable
      fonts:
        - asset: assets/fonts/Inter_18pt-Regular.ttf
        - asset: assets/fonts/Inter_18pt-Bold.ttf
          weight: 700
```

### Build Flavors
```
- debug: Local development, verbose logging
- staging: Staging environment, standard logging
- production: Production build, minimal logging
```

### Code Generation
```bash
# Generate freezed models, json_serializable
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes (auto-generate on save)
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

## Browser-Specific Components

### URL Bar
- Text input with validation
- Auto-complete from history/bookmarks
- Search engine integration
- Paste detection
- URL formatting/validation

### Tab Bar
- Horizontal scrolling list
- Tab drag & drop
- Context menu (close, duplicate, etc.)
- New tab button
- Tab preview on hover

### WebView Container
- Full WebView embedding
- Progress tracking
- Error handling
- Context menu override
- JavaScript channel setup

### History Database
- Full-text search indexing
- Date-based grouping
- Visit count tracking
- Automatic cleanup (90 days)

## Testing Infrastructure

### Unit Testing
- **Framework**: test package
- **Mocking**: mocktail
- **Target**: > 80% code coverage
- **Scope**: BLoCs, repositories, utilities

### Integration Testing
- **Framework**: integration_test
- **Scope**: Tab management, navigation flows, persistence

### Widget Testing
- **Framework**: flutter_test
- **Scope**: Custom UI components, dialogs

## Security Architecture

### Data Protection
```
Bookmarks/History:
├─ Stored in SQLite (on disk)
├─ Encrypted at rest (FileVault)
└─ Synced via HTTPS + encryption

Download History:
├─ Stored locally
├─ Auto-cleared after 30 days
└─ User can manually clear

Passwords:
├─ Never stored locally (pass through)
├─ Keychain integration for autofill
└─ Biometric unlock support
```

### Network Security
```
HTTPS:
├─ Enforced for all API calls
├─ Certificate pinning for critical endpoints
└─ Certificate transparency verification

DNS:
├─ System DNS by default
├─ DoH support (future)
└─ Custom DNS option (future)
```

---

Last updated: December 29, 2025
