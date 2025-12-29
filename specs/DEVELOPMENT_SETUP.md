# Browser Development Setup Guide

## Prerequisites

### System Requirements
```bash
# Check macOS version
sw_vers
# Minimum: 11.0

# Check available disk space (need 10GB)
df -h
```

### Required Software
1. **Xcode** (14.2 or later)
   ```bash
   # Install from App Store or
   xcode-select --install
   
   # Verify
   xcodebuild -version
   ```

2. **Flutter SDK** (3.16.0 or later)
   ```bash
   # Download from https://flutter.dev/docs/get-started/install/macos
   # Or via Homebrew
   brew install flutter
   
   # Verify
   flutter --version
   ```

3. **Dart** (included with Flutter)
   ```bash
   dart --version
   ```

4. **Git**
   ```bash
   git --version
   # If not installed: brew install git
   ```

## Initial Setup

### 1. Flutter Environment Configuration
```bash
# Set up Flutter
flutter doctor

# Check for issues
flutter doctor -v

# Enable macOS support
flutter config --enable-macos-desktop
```

### 2. Clone Repository
```bash
git clone https://github.com/yourorg/webkit-browser.git
cd webkit-browser
```

### 3. Install Dependencies
```bash
# Get Flutter packages
flutter pub get

# Generate code (freezed, json_serializable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# For macOS specifically
cd macos
pod install
cd ..
```

### 4. Configure Environment Variables
Create `.env` file in project root:
```bash
cp .env.example .env
```

Edit `.env`:
```
ENVIRONMENT=development
LOG_LEVEL=debug
SEARCH_ENGINE=google
HOMEPAGE_URL=about:blank
```

For **production**, use:
```bash
cp .env.production.example .env.production
```

## IDE Setup

### VS Code
1. Install extensions:
   - Flutter (official)
   - Dart (official)
   - Pubspec Assist
   - Error Lens
   - Better Comments

2. Create `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "Dart-Code.dart-code",
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true
  }
}
```

3. Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Browser macOS",
      "request": "launch",
      "type": "dart",
      "args": [
        "-d",
        "macos"
      ]
    }
  ]
}
```

### Android Studio / IntelliJ IDEA
1. Install plugins:
   - Flutter
   - Dart
   - Flutter Intl

2. Configure SDK paths:
   - Preferences → Languages & Frameworks → Flutter
   - Set Flutter SDK path
   - Set Dart SDK path (auto-detected)

### Xcode
1. Open project:
   ```bash
   open macos/Runner.xcworkspace
   ```

2. Select scheme: `Runner` or `Runner (Profile)`
3. Select device: `My Mac`

## Development Commands

### Running the App

#### Debug Mode (with hot reload)
```bash
# Run on macOS
flutter run -d macos

# Run with verbose logging
flutter run -d macos -v

# Run with specific configuration
flutter run -d macos --dart-define-from-file=.env
```

#### Release Mode
```bash
flutter run -d macos --release
```

#### Profile Mode (for performance analysis)
```bash
flutter run -d macos --profile
```

### Code Generation

#### Generate models & serialization
```bash
# Generate all code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes (auto-generate on save)
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

### Testing

#### Run all tests
```bash
flutter test

# With coverage
flutter test --coverage

# Generate coverage report
lcov --list coverage/lcov.info
```

#### Run specific test file
```bash
flutter test test/features/browser/browser_bloc_test.dart
```

#### Integration tests
```bash
flutter test integration_test/
```

### Linting & Analysis

#### Analyze code
```bash
flutter analyze

# In strict mode
dart analyze --fatal-infos
```

#### Format code
```bash
# Format all files
dart format .

# Format specific directory
dart format lib/
```

### Build

#### Build macOS app (debug)
```bash
flutter build macos --debug
```

#### Build macOS app (release)
```bash
flutter build macos --release
```

#### Build DMG installer
```bash
# After building release
cd build/macos/Build/Products/Release/
hdiutil create -volname "WebKit Browser" -srcfolder . -ov -format UDZO browser.dmg
```

## Project Structure

```
webkit-browser/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   ├── environment/          # Environment configuration
│   │   ├── router/               # App routing
│   │   ├── theme/                # Theme configuration
│   │   └── di/                   # Dependency injection
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── network/              # HTTP client, interceptors
│   │   └── utils/
│   ├── features/
│   │   ├── browser/              # Main browser feature
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── pages/
│   │   │       └── widgets/
│   │   ├── history/              # History management
│   │   ├── bookmarks/            # Bookmarks management
│   │   ├── settings/             # Settings feature
│   │   └── search/               # Search integration
│   └── shared/                   # Shared widgets, models
├── test/
│   ├── features/
│   │   ├── browser/
│   │   ├── history/
│   │   └── ...
│   └── core/
├── integration_test/
│   ├── app_test.dart
│   ├── navigation_test.dart
│   └── webview_test.dart
├── macos/
│   ├── Runner.xcworkspace/
│   ├── Runner/
│   ├── Podfile
│   └── ...
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── pubspec.yaml
├── .env.example
├── .github/
│   └── workflows/                # CI/CD pipelines
├── analysis_options.yaml         # Lint rules
└── README.md
```

## Build Flavors

### Debug Flavor (Development)
```bash
flutter run --flavor dev -d macos
```

Configuration: Development settings, verbose logging

### Production Flavor
```bash
flutter run --flavor prod -d macos
```

Configuration: Production settings, minimal logging

### Flavor Configuration (pubspec.yaml)
```yaml
flutter:
  build-flavor: dev
```

### Accessing Flavor in Code
```dart
const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
```

## Performance Profiling

### Frame Rate Analysis
```bash
flutter run -d macos --trace-startup
```

Then analyze with DevTools:
```bash
flutter pub global run devtools
```

Access at `localhost:9100`

### Memory Profiling
1. Run app with profiling:
   ```bash
   flutter run -d macos --profile
   ```

2. Open DevTools Memory tab
3. Take heap snapshots and analyze

### Network Profiling
Use the Network tab in DevTools to monitor WebView requests

## CI/CD Setup

### GitHub Actions Workflow (.github/workflows/test.yml)
```yaml
name: Test & Build

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test
      - run: flutter build macos --release
```

## Troubleshooting

### Common Issues

**1. Pod dependency issues**
```bash
cd macos
rm -rf Podfile.lock
rm -rf Pods/
pod install --repo-update
cd ..
```

**2. Build cache issues**
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build
```

**3. Hot reload not working**
- Restart the app: `R` in terminal
- Full restart: `Shift+R`

**4. WebView not loading**
- Check entitlements in macos/Runner/DebugProfile.entitlements
- Verify network access is enabled
- Check console logs for specific errors

**5. Xcode build issues**
```bash
open macos/Runner.xcworkspace
# Build → Clean Build Folder (Cmd+Shift+K)
# Build → Build (Cmd+B)
```

## Debugging

### Debug Mode
- Use `debugPrint()` for app-specific logging
- Use `print()` for quick debugging
- VS Code: Press `F5` to attach debugger

### DevTools
```bash
flutter pub global run devtools

# Specify custom port
devtools --port 9100
```

Access at `localhost:9100`

### WebView Debugging
- Enable WebKit debugging in macOS settings
- Use Safari Web Inspector for WebView content
- Check JavaScript console via WebView controller

### Breakpoints
- Click line number in editor to set breakpoint
- Hover over variables to inspect values
- Step through code with F10 (step over), F11 (step into)

---

Last updated: December 29, 2025
