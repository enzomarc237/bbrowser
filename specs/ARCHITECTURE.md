# Architecture - WebKit Browser for macOS

## System Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    Flutter Application Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Presentation│  │ Browser BLoC│  │ Data & Persistence     │  │
│  │   (Screens)  │→→│ (Tab, Hist, │→→│ (SQLite, Hive, Cache) │  │
│  └─────────────┘  │  Bookmarks)  │  └─────────────────────────┘  │
│                   └─────────────┘                                 │
└──────────────────────────────────────────────────────────────────┘
           ↓                      ↓                          ↓
┌──────────────────────────────────────────────────────────────────┐
│             Infrastructure & WebView Layer                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐│
│  │ WebView  │  │ Network  │  │ Storage  │  │ Search Engine    ││
│  │Controller│  │(Dio/HTTP)│  │(SQLite)  │  │ Integration      ││
│  └──────────┘  └──────────┘  └──────────┘  └──────────────────┘│
└──────────────────────────────────────────────────────────────────┘
           ↓                                          ↓
┌──────────────────────────────────────────────────────────────────┐
│              macOS Platform & External Services                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ WebKit   │  │ CloudKit │  │ Spotlight│  │ Analytics│        │
│  │ Engine   │  │ (Sync)   │  │ (Search) │  │(Telemetry│        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└──────────────────────────────────────────────────────────────────┘
```

## Layered Architecture

### 1. Presentation Layer
**Responsibility**: UI rendering, user interaction, navigation

**Screens**:
- Home (new tab page)
- Browser view (active tab)
- Settings & Preferences
- History browser
- Bookmarks manager
- Downloads page

**Components** (using `macos_ui`):
- Sidebar tab bar (left, resizable, 280px)
- URL bar with suggestions
- WebView container
- Navigation controls (back, forward, reload)
- Tab items (favicon + title + close button)
- Status bar

**Key Patterns**:
- Responsive layouts for various window sizes
- Material Design 3 + macOS conventions
- Dark/Light theme support
- Keyboard shortcuts

### 2. Browser BLoC Layer
**Responsibility**: Browser state management, business logic

**BLoCs**:

**BrowserBloc** (Main):
- Events: OpenUrl, NewTab, CloseTab, SelectTab, GoBack, GoForward, Reload
- State: BrowserLoaded(activeTab, tabs, currentUrl)
- Manages active tab and tab list

**TabBloc** (Per-tab):
- Events: NavigateTo, GoBack, GoForward, Reload, Stop
- State: TabState(url, title, icon, progress, canBack, canForward)
- Manages individual tab state

**HistoryBloc**:
- Events: AddHistoryEntry, GetHistory, SearchHistory
- State: HistoryLoaded(entries)
- Manages browsing history

**BookmarkBloc**:
- Events: AddBookmark, RemoveBookmark, UpdateBookmark, GetBookmarks
- State: BookmarksLoaded(bookmarks)
- Manages bookmarks/favorites

**SearchBloc**:
- Events: Search, GetSuggestions, ClearSearch
- State: SearchResults(results, suggestions)
- Manages search queries and suggestions

### 3. Data Layer
**Responsibility**: Data persistence, caching, retrieval

**Repositories**:
- `BrowserRepository`: Tab state, browser prefs
- `HistoryRepository`: Browse history with full-text search
- `BookmarkRepository`: Saved bookmarks/favorites
- `CacheRepository`: Page caching, offline content
- `SettingsRepository`: User preferences, sync settings
- `SearchRepository`: Search engine integration

**Data Sources**:
- **Remote**: Search engine APIs, sync servers
- **Local**: SQLite for structured data
- **Memory**: Hive for fast access
- **Disk**: Page cache, downloaded content

### 4. Infrastructure Layer
**Responsibility**: Technical concerns, external services

**Components**:
- **WebView Manager**: Controller lifecycle, tab isolation
- **HTTP Client**: Requests with interceptors
- **Cache Manager**: Multi-level caching strategy
- **Database**: SQLite schema and migrations
- **Analytics**: Event tracking, telemetry
- **Cloud Sync**: CloudKit or custom backend

## Core Design Patterns

### BLoC Pattern - Multi-level

```
BrowserBloc (main)
  ├── Manages tab list
  ├── Handles new/close tab
  └── Coordinates with TabBlocs

TabBloc[] (one per tab)
  ├── Manages individual tab state
  ├── Handles navigation
  └── Emits tab updates → BrowserBloc listens

HistoryBloc (shared)
  ├── Persists navigation
  └── Provides history UI

BookmarkBloc (shared)
  ├── Manages favorites
  └── Provides bookmark UI
```

### Tab Management Architecture

```
Tab Model:
├── id: String (unique)
├── title: String
├── url: String
├── favicon: Uint8List
├── webViewController: WebViewController
├── history: List<HistoryEntry>
├── state: TabState (active, background, pinned)
└── metadata: TabMetadata (loadTime, size, etc)

TabManager:
├── createTab()
├── closeTab(id)
├── selectTab(id)
├── restoreTab() // undo close
├── reorderTab(id, newIndex)
├── saveState() // persistence
└── loadState()

Left Sidebar Rendering (using macos_ui):
├── MacosSidebar container (280px, resizable)
├── Header section (new tab + menu buttons)
├── ScrollableColumn (for tabs list)
├── TabItem widgets (with favicon, title, close button)
└── Context menu on right-click
```

### Data Persistence Strategy

```
SQLite Schema:
├── tabs (id, title, url, pinned, order)
├── history (id, url, title, timestamp, favicon)
├── bookmarks (id, url, title, folder, created)
├── settings (key, value, user_id)
└── cache (url, content, headers, timestamp)

Hive Boxes:
├── app_state (current_tab, window_size)
├── preferences (theme, search_engine, etc)
└── sync_queue (pending sync operations)

Memory Cache:
├── favicon_cache (url → image)
├── page_cache (url → html)
└── suggestion_cache (query → suggestions)
```

## Feature Flows

### Opening a URL Flow

```
User types URL in address bar
   ↓
AddressBarWidget emits URL
   ↓
BrowserBloc.add(OpenUrl(url))
   ↓
BrowserBloc processes → selects active tab
   ↓
TabBloc.add(NavigateTo(url))
   ↓
TabBloc emits TabLoading state
   ↓
UI shows loading progress
   ↓
WebViewController.loadRequest(Uri.parse(url))
   ↓
onPageStarted → TabBloc.add(PageLoading)
   ↓
Page renders (WebView handles rendering)
   ↓
onPageFinished → TabBloc.add(PageFinished)
   ↓
Get page title, favicon
   ↓
HistoryBloc.add(AddEntry) → persists to DB
   ↓
Left sidebar updates with new tab title
   ↓
TabBloc emits TabLoaded state with metadata
   ↓
UI updates address bar, favicon in sidebar
```

### Tab Management Flow (Left Sidebar)

```
User clicks "+" button in sidebar header
   ↓
BrowserBloc.add(NewTab())
   ↓
Generate unique tab ID
   ↓
Create WebViewController
   ↓
Create new Tab model
   ↓
BrowserBloc emits state with new tab
   ↓
Sidebar updates: new TabItem appears
   ↓
TabBloc listeners created for new tab
   ↓
Load default new tab page
   ↓
User clicks tab in sidebar
   ↓
BrowserBloc.add(SelectTab(id))
   ↓
BrowserBloc emits active_tab = id
   ↓
Sidebar highlights selected tab (MacosListTile with isSelected)
   ↓
WebView content updates
   ↓
User hovers tab: close button appears
   ↓
User clicks close or Cmd+W
   ↓
BrowserBloc.add(CloseTab(id))
   ↓
Tab removed from sidebar
   ↓
Adjacent tab selected automatically
```

### Tab Reordering Flow

```
User drags tab in left sidebar
   ↓
ReorderableList detects drag
   ↓
Visual feedback: tab opacity changes
   ↓
BrowserBloc.add(ReorderTab(id, newIndex))
   ↓
Tab order updated in state
   ↓
Sidebar re-renders in new order
   ↓
TabManager.saveState() persists order
   ↓
On app restart: tabs load in saved order
```

### History/Bookmark Persistence

```
User navigates to URL
   ↓
PageFinished event
   ↓
HistoryBloc.add(AddEntry(url, title, favicon))
   ↓
HistoryRepository inserts to SQLite
   ↓
Success event emitted
   ↓
User bookmarks page
   ↓
BookmarkBloc.add(AddBookmark(url, title, folder))
   ↓
BookmarkRepository inserts to SQLite
   ↓
Sync notification queued (if sync enabled)
   ↓
Data synced to CloudKit in background
```

## Component Interaction Diagram

```
┌─ User Interactions
│
├─→ Left Sidebar (MacosSidebar + TabItems using macos_ui)
│   ├─→ NewTab button (header) → BrowserBloc.add(NewTab)
│   ├─→ Tab item click → BrowserBloc.add(SelectTab)
│   ├─→ Close button → BrowserBloc.add(CloseTab)
│   ├─→ Drag to reorder → BrowserBloc.add(ReorderTab)
│   └─→ Right-click context menu
│
├─→ AddressBar Widget (MacosTextField via macos_ui)
│   └─→ TextInputAction → BrowserBloc
│
├─→ NavigationButtons (MacosIconButton via macos_ui)
│   ├─→ Back → TabBloc.add(GoBack)
│   ├─→ Forward → TabBloc.add(GoForward)
│   └─→ Reload → TabBloc.add(Reload)
│
├─→ Settings Dialog (MacosAlertDialog via macos_ui)
│   └─→ Changes → SettingsBloc → SettingsRepository
│
└─→ Search Bar
    └─→ Query → SearchBloc → SearchRepository
        └─→ Display Suggestions

Listeners:
├─ BrowserBloc → updates sidebar UI (selected tab highlight)
├─ TabBloc → updates active WebView content
├─ HistoryBloc → persists history
├─ BookmarkBloc → persists bookmarks
└─ SettingsBloc → applies preferences
```

## macOS-Specific Integration

### Window Management
- Multi-window support (one per browser window)
- Restore windows on launch
- Command-key shortcuts (Cmd+N, Cmd+T, Cmd+W)
- Trackpad gestures (swipe back/forward)

### Native Features
- Spotlight search integration
- Handoff between devices
- Biometric authentication (Touch ID)
- System dark mode detection
- Notification center integration

### Performance
- Lazy load tabs (don't create WebView until selected)
- Memory management (unload background tabs)
- Disk cache with quota
- Background sync support

## Security Architecture

### Data Protection
```
Credentials:
├─ Stored in Keychain (flutter_secure_storage)
├─ Never logged or cached
└─ Cleared on logout

Cache:
├─ Encrypted on disk (at rest)
├─ HTTPS-only content
└─ Automatic cleanup (30 days)

Passwords:
├─ Biometric unlock
├─ AES-256 encryption
└─ Sync via encrypted channel
```

### Network Security
```
HTTPS:
├─ Certificate pinning (for API calls)
├─ Strict Transport Security
└─ Certificate transparency verification

DNS:
├─ DoH (DNS over HTTPS) support
├─ DNS blocking for ads/trackers
└─ Configurable DNS providers
```

## Testing Architecture

### Unit Tests
- BLoC logic (90% coverage)
- Repository queries (85% coverage)
- Model validation (95% coverage)

### Integration Tests
- Tab creation/switching
- Navigation flows
- History/Bookmark operations
- Settings persistence

### E2E Tests
- Full browser workflows
- Performance benchmarks
- Memory leak detection
- Network scenario testing

---

**Last updated**: December 29, 2025
