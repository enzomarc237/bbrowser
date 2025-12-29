# Browser UI/UX Design Guidelines

## Design Philosophy

- **macOS Native**: Follow Apple HIG (Human Interface Guidelines) using `macos_ui` package
- **Content Focus**: Browser UI should be minimal and unobtrusive
- **Performance Focused**: Smooth interactions, instant feedback
- **Accessibility**: WCAG 2.1 AA compliant
- **Consistency**: Unified design system across all screens (native macOS components)
- **Safari Familiar**: Users expect Safari-like behavior
- **Native Styling**: Use `macos_ui` for authentic macOS appearance and interactions

## Color Palette

### Brand Colors
- **Primary Blue**: #0A84FF (accent, interactive elements)
- **Secondary Gray**: #8E8E93 (secondary UI elements)
- **Background**: #FFFFFF (light mode), #1C1C1E (dark mode)
- **Text Primary**: #000000 (light), #FFFFFF (dark)
- **Text Secondary**: #3C3C43 (light), #EBEBF5 (dark)

### Semantic Colors
- **Success**: #34C759 (positive actions, downloads complete)
- **Warning**: #FF9500 (alerts, warnings)
- **Error**: #FF3B30 (errors, failed loads)
- **Info**: #0A84FF (informational messages)
- **Bookmark**: #FFD60A (favorited items)

## Typography

### Font Family
- **Primary**: SF Pro Display (macOS system font)
- **Fallback**: Helvetica Neue
- **Monospace**: SF Mono (for URLs, code)

### Text Styles
```
Page Title: 28pt, 600 weight (page headings)
Section Header: 16pt, 600 weight (section titles)
Body Large: 14pt, 400 weight (primary content)
Body Regular: 13pt, 400 weight (secondary content)
Caption: 11pt, 400 weight (timestamps, hints)
Label: 12pt, 500 weight (button labels, tags)
Monospace: 11pt, 400 weight (URLs, code snippets)
```

## Layout & Spacing

### Grid System
- **Base unit**: 4px
- **Standard spacing**: 8px, 12px, 16px, 24px, 32px
- **Column width**: Responsive (full-width for browser)
- **Gutter**: 12px (between elements)

### macOS Window Sizes
- **Minimum**: 800x600 (minimum usable)
- **Recommended**: 1280x720 (standard)
- **Optimized**: 1920x1080 (Full HD)
- **Ultra-wide**: Up to 3440px

## Component Library

### Left Sidebar Tab Bar (Width: 280px, Resizable)
```
┌──────────────────┐
│ [+]  ⋯           │ Header
├──────────────────┤
│ 🔗 Google        │
│ 🔗 GitHub        │ Tab Items
│ 🔗 Hacker News   │
│ 🔗 Stack Overflow│
│                  │
│                  │
│                  │
└──────────────────┘
```

- **Sidebar width**: 280px (resizable, min 200px, max 400px)
- **Tab item height**: 36px
- **Favicon size**: 16x16px
- **Close button**: 14x14px (appears on hover)
- **New tab button**: 32x32px (in header)
- **Menu button**: 32x32px (in header)
- **Scrollable**: For tabs exceeding viewport
- **Drag & drop**: Reorder tabs by dragging

### Top Navigation Bar (Height: 52px)
```
┌────────────────────────────────────────────────────┐
│  ◄  ►  ⟲  │  URL Bar                  │  ⚙  ⋮  │
└────────────────────────────────────────────────────┘
```

- **Back/Forward buttons**: 32x32px, gray background on hover
- **Reload button**: 32x32px
- **URL bar**: Flex width, 32px height, 8px padding
- **Settings/Menu**: 32x32px buttons

### URL Bar
- **Height**: 32px
- **Padding**: 8px horizontal, 6px vertical
- **Border radius**: 4px
- **Background**: Secondary gray (light mode), dark gray (dark mode)
- **Text**: Monospace for URLs, 13pt
- **Icons**: 16x16px (search, lock, extensions)

### WebView Content
- **Full available space** (after tab bar and nav bar)
- **Minimum margins**: None (full bleed)
- **Scrollbar**: Auto-hide (show on hover)

### Context Menus
- **Font size**: 13pt
- **Item height**: 20px minimum
- **Padding**: 4px vertical, 6px horizontal
- **Icons**: 16x16px (if included)
- **Separators**: 1px dividers between sections

### Search Bar (Find in Page)
```
┌──────────────────────────────────────────┐
│  🔍 Search in page...    [1/5] ◀ ▶ ✕   │
└──────────────────────────────────────────┘
```

- **Height**: 36px
- **Position**: Top-right corner (floating)
- **Background**: White (light), dark gray (dark)
- **Border**: 1px subtle shadow
- **Rounded corners**: 6px
- **Padding**: 6px

### Status Bar
- **Height**: 20px
- **Position**: Bottom of window
- **Content**: URL preview on hover, security status
- **Font**: 11pt, secondary text color
- **Icons**: 12x12px

## Screen Layouts

### Main Browser Window
```
┌─────────────────────────────────────────────┐
│  ◄  ►  ⟲  │  https://example.com  │  ⚙  │ Navigation
├─────────────────────────────────────────────┤
│ ✕ [🔗] Site  ✕ [🔗] Site2  ✕ [+]         │ Tabs
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│              WEB PAGE CONTENT                │
│                                             │
│                                             │
│                                             │
├─────────────────────────────────────────────┤
│ https://example.com                         │ Status
└─────────────────────────────────────────────┘
```

### Settings Dialog
```
┌──────────────────────────────────────┐
│ Browser Settings              ✕     │
├──────────────────────────────────────┤
│ ◀ General                             │
│   Search Engine                       │
│   ◆ Google                            │
│   ◇ DuckDuckGo                        │
│                                       │
│   Homepage                            │
│   [______________________]            │
│                                       │
│   ◉ Open last page                    │
│   ○ Open home page                    │
│   ○ Open blank page                   │
│                                       │
│                           [OK] [Cancel]│
└──────────────────────────────────────┘
```

### History Panel
```
┌────────────────────────────────────────┐
│ History              Search [________] │
├────────────────────────────────────────┤
│ ▼ Today                                │
│   • 2:45 PM - Site Title              │
│   • 1:20 PM - Another Page            │
│ ▼ Yesterday                            │
│   • 5:30 PM - Site Title              │
│ ▼ Last Week                            │
│   • Nov 28 - Page Title               │
└────────────────────────────────────────┘
```

### Bookmarks Panel
```
┌────────────────────────────────────────┐
│ Bookmarks         New Folder    Search │
├────────────────────────────────────────┤
│ ▼ Favorites                            │
│   • Apple                              │
│   • Google                             │
│ ▼ Work                                 │
│   • GitHub                             │
│   • GitLab                             │
│ ▼ News                                 │
│   • Hacker News                        │
└────────────────────────────────────────┘
```

## Animations & Transitions

### Tab Opening/Closing
- **Duration**: 200ms
- **Easing**: ease-out
- **Effect**: Smooth width change

### Page Load Progress
- **Duration**: Dynamic (until page loaded)
- **Style**: Top progress bar (2px height)
- **Color**: Primary blue

### Navigation Bar Hide/Show
- **Duration**: 150ms
- **Easing**: ease-in-out
- **Trigger**: Scroll down/up

### Hover Effects
- **Button hover**: Background color change (50ms)
- **Tab hover**: Slight scale + shadow
- **Card hover**: Light shadow

## Keyboard Navigation

### Global Shortcuts
```
Cmd+T         → New tab
Cmd+N         → New window
Cmd+W         → Close tab
Cmd+Q         → Quit
Cmd+L         → Focus URL bar
Cmd+Y         → Open history
Cmd+D         → Bookmark page
Cmd+,         → Settings
Cmd+F         → Find in page
Cmd+/         → Search help
```

### Navigation Shortcuts
```
Cmd+←         → Back
Cmd+→         → Forward
Cmd+R         → Reload
Cmd+Shift+R   → Hard reload
Cmd+0         → Reset zoom
Cmd++         → Zoom in
Cmd+-         → Zoom out
```

### Tab Management
```
Ctrl+Tab      → Next tab
Ctrl+Shift+Tab → Previous tab
Cmd+1..8      → Jump to tab 1-8
Cmd+9         → Jump to last tab
```

### Find in Page
```
Cmd+F         → Open find
Escape        → Close find
Enter         → Next match
Shift+Enter   → Previous match
```

## Dark Mode Support

### Light Mode (Default)
- **Background**: #FFFFFF
- **Text**: #000000
- **Secondary**: #8E8E93
- **UI Elements**: Light gray backgrounds

### Dark Mode
- **Background**: #1C1C1E
- **Text**: #FFFFFF
- **Secondary**: #8E8E93
- **UI Elements**: Dark gray backgrounds

### System Integration
- Respect macOS system appearance setting
- Toggle in settings for manual override
- Smooth transition between modes

## Accessibility

### WCAG 2.1 AA Compliance
- **Color Contrast**: Minimum 4.5:1 for text
- **Interactive Elements**: Minimum 48x48px (macOS standard)
- **Focus Indicators**: Visible 2px border with high contrast
- **Font Size**: Minimum 11pt base size
- **Line Height**: Minimum 1.5x font size

### Screen Reader Support
- **ARIA Labels**: All interactive elements labeled
- **Semantic Structure**: Proper widget hierarchy
- **Alternative Text**: All images have descriptions
- **Live Regions**: Status updates announced

### Keyboard Access
- **Full keyboard navigation**: All features accessible
- **Tab order**: Logical and intuitive
- **Keyboard shortcuts**: Standard macOS conventions
- **Focus visible**: Clear focus indicators

### Motion & Animation
- **Respects system preference**: Disable animations if requested
- **Reduced motion mode**: Support for accessibility
- **No auto-play**: Content doesn't auto-start
- **Pause controls**: Always available

## Responsive Design

### Tab Sidebar
- **Width**: 280px (default, resizable min 200px → max 400px)
- **Content**: Vertical list of open tabs
- **Position**: Left side (collapsible via toggle button)
- **Behavior**: 
  - Hover over tab shows close button
  - Drag tab to reorder
  - Right-click for context menu
  - Scroll when tabs exceed viewport height

### Fullscreen Mode
- **Controls**: Auto-hide after 3 seconds
- **Sidebar**: Hidden (but accessible via Cmd+Y or mouse move)
- **Status bar**: Hidden
- **Navigation**: Accessible via mouse move/keyboard

### Window Snapping
- **Half-width**: 50% screen width (sidebar + content split)
- **Full-width**: 100% screen width (sidebar resizes accordingly)
- **Minimum width**: 800px (sidebar at 280px + content at 520px)

### Sidebar Toggle
- **Keyboard shortcut**: Cmd+Shift+S
- **Smooth transition**: 200ms collapse/expand
- **Saves preference**: Remembers sidebar state

---

Last updated: December 29, 2025
