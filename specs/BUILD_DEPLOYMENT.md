# Build & Deployment Guide

## Build Process

### Preparation

#### Code Quality Checks
```bash
# Format code
dart format .

# Run analysis
flutter analyze

# Run tests
flutter test

# Check for issues
flutter doctor
```

#### Version Management
Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

### Building for Release

#### Debug Build
```bash
# Build debug binary
flutter build macos --debug

# Output: build/macos/Build/Products/Debug/webkit_browser.app
```

#### Release Build
```bash
# Build optimized release binary
flutter build macos --release

# Output: build/macos/Build/Products/Release/webkit_browser.app
```

#### Profile Build
```bash
# Build with profiling support
flutter build macos --profile

# Output: build/macos/Build/Products/Profile/webkit_browser.app
```

### Code Signing

#### Automatic Code Signing (Recommended)
1. Open `macos/Runner.xcworkspace` in Xcode
2. Select `Runner` project
3. Select `Runner` target
4. Go to "Signing & Capabilities"
5. Enable "Automatically manage signing"
6. Select your Apple ID team
7. Set provisioning profile

#### Manual Code Signing
```bash
# Export development certificate
security export-cert -p password cert.p12 ~/Desktop/dev-cert.p12

# Set code signing identity
codesign -s "Apple Development" \
  build/macos/Build/Products/Release/webkit_browser.app
```

### Notarization (macOS 10.15+)

#### Register with Apple
1. Sign up for Apple Developer Program
2. Create an App ID
3. Create App-specific password

#### Prepare App for Notarization
```bash
# Build release version
flutter build macos --release

# Create DMG for notarization
cd build/macos/Build/Products/Release/
ditto -c -k --sequesterRsrc \
  webkit_browser.app \
  webkit_browser.zip
```

#### Submit for Notarization
```bash
# Upload to Apple
xcrun notarytool submit webkit_browser.zip \
  --apple-id your-apple-id@example.com \
  --password app-specific-password \
  --team-id TEAMID

# Check status
xcrun notarytool log RequestID --apple-id your-apple-id
```

#### Staple Notarization
```bash
# After approval, staple ticket
xcrun stapler staple webkit_browser.app

# Verify
xcrun stapler validate webkit_browser.app
```

## Distribution Formats

### Standalone App Bundle
```bash
# Create from built app
cp -r build/macos/Build/Products/Release/webkit_browser.app \
  ~/Desktop/WebKit\ Browser.app

# Test
open ~/Desktop/WebKit\ Browser.app
```

### DMG Installer

#### Create DMG
```bash
# Navigate to build directory
cd build/macos/Build/Products/Release/

# Create DMG
hdiutil create -volname "WebKit Browser" \
  -srcfolder . \
  -ov \
  -format UDZO \
  webkit_browser.dmg
```

#### Create Branded DMG (Optional)
```bash
# Create DMG with custom icon and layout
# 1. Create temporary folder
mkdir -p dmg_tmp
cp -r webkit_browser.app dmg_tmp/

# 2. Create symlink to Applications
ln -s /Applications dmg_tmp/Applications

# 3. Create DMG
hdiutil create -volname "WebKit Browser" \
  -srcfolder dmg_tmp \
  -ov \
  -format UDZO \
  webkit_browser.dmg

# 4. Set custom icon (optional)
# Copy icon to dmg_tmp/.VolumeIcon.icns
# hdiutil seticon dmg_tmp/.VolumeIcon.icns webkit_browser.dmg
```

### Zip Archive
```bash
# Create zip for distribution
cd build/macos/Build/Products/Release/
zip -r webkit_browser.zip webkit_browser.app

# Verify
unzip -t webkit_browser.zip
```

## Continuous Integration / Deployment

### GitHub Actions Setup

#### Build Workflow (.github/workflows/build.yml)
```yaml
name: Build & Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build runner
        run: flutter pub run build_runner build
      
      - name: Run tests
        run: flutter test
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Build macOS
        run: flutter build macos --release
      
      - name: Create DMG
        run: |
          cd build/macos/Build/Products/Release/
          hdiutil create -volname "WebKit Browser" \
            -srcfolder . \
            -ov \
            -format UDZO \
            webkit_browser.dmg
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/macos/Build/Products/Release/webkit_browser.dmg
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Test Workflow (.github/workflows/test.yml)
```yaml
name: Tests & Analysis

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Format check
        run: dart format --set-exit-if-changed .
      
      - name: Analyze
        run: flutter analyze
      
      - name: Unit tests
        run: flutter test
      
      - name: Integration tests
        run: flutter test integration_test/
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

## Release Checklist

### Pre-Release
- [ ] Update `pubspec.yaml` version
- [ ] Update `CHANGELOG.md`
- [ ] Run full test suite
- [ ] Update documentation
- [ ] Test on macOS 11, 12, 13
- [ ] Test on Intel and Apple Silicon
- [ ] Verify all features working
- [ ] Performance check (< 500MB memory)

### Build
- [ ] Clean previous builds: `flutter clean`
- [ ] Generate code: `flutter pub run build_runner build`
- [ ] Build release: `flutter build macos --release`
- [ ] Code sign release build
- [ ] Create DMG installer
- [ ] Test DMG installation and uninstallation

### Testing
- [ ] Manual testing of fresh install
- [ ] Test all core features
- [ ] Test upgrade from previous version
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Check performance metrics

### Release
- [ ] Commit version bump
- [ ] Create git tag: `git tag v1.0.0`
- [ ] Push tag: `git push origin v1.0.0`
- [ ] Upload to GitHub Releases
- [ ] Announce release (blog, social media)
- [ ] Monitor for issues

### Post-Release
- [ ] Monitor crash reports
- [ ] Respond to feedback
- [ ] Plan next release
- [ ] Document any issues found

## Version Management

### Semantic Versioning
```
MAJOR.MINOR.PATCH+BUILD
1.0.0+1
```

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes
- **BUILD**: Build number (increment for each release)

### Version Update Script
```bash
#!/bin/bash
# update-version.sh

VERSION=$1
BUILD=$2

# Update pubspec.yaml
sed -i '' "s/^version: .*/version: ${VERSION}+${BUILD}/" pubspec.yaml

# Commit
git add pubspec.yaml
git commit -m "Release v${VERSION}"
git tag "v${VERSION}"

echo "Version updated to ${VERSION}+${BUILD}"
```

## Troubleshooting

### Common Build Issues

#### Pod Issues
```bash
cd macos
rm -rf Podfile.lock
rm -rf Pods/
pod install --repo-update
cd ..
flutter build macos --release
```

#### Code Signing Issues
```bash
# Check signing identity
security find-identity -v -p codesigning

# Re-sign manually
codesign -s "Apple Development" \
  --deep \
  build/macos/Build/Products/Release/webkit_browser.app
```

#### Notarization Failures
```bash
# Check notarization status
xcrun notarytool log REQUEST_ID --apple-id user@example.com --password password

# Common issue: Security frameworks
# Ensure all binary dependencies are notarized
```

#### Build Cache Issues
```bash
flutter clean
rm -rf build/
rm -rf pubspec.lock
flutter pub get
flutter build macos --release
```

## Release History

### v1.0.0 - Initial Release
- Basic browser functionality
- Tab management
- History and bookmarks
- Settings panel

### v1.1.0 - Improvements
- Performance optimizations
- Dark mode support
- Keyboard shortcuts

---

Last updated: December 29, 2025
