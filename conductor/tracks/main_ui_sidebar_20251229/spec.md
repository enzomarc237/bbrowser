# Specification: Main Browser UI & Tab Management

## 1. Overview

This track focuses on building the foundational user interface for the browser. This includes the main window layout, the top navigation bar, the web content view, and a left sidebar for managing tabs. The goal is to create a simple, intuitive, and native-feeling UI that aligns with the project's design guidelines.

## 2. Functional Requirements

### FR1: Main UI Layout
- The main browser window shall be divided into three primary regions:
    - A top navigation bar.
    - A left sidebar for tab management.
    - A main content area for displaying web pages.

### FR2: Top Navigation Bar
- The navigation bar shall contain the following controls:
    - Back button
    - Forward button
    - Reload button
- The navigation bar shall include a URL address bar for entering web addresses.

### FR3: Left Sidebar for Tab Management
- The sidebar shall display a vertical list of all open tabs.
- Each item in the list shall display the tab's favicon and page title.
- A "close" button shall appear on a tab item when the user hovers over it.
- The sidebar shall have a header section containing a "+" button to open a new, blank tab.
- Users shall be able to reorder tabs within the sidebar by dragging and dropping them.

### FR4: Tab Interaction
- Clicking on a tab in the sidebar shall make it the active tab.
- When a tab becomes active:
    - The main content area shall display the web page associated with that tab.
    - The selected tab item in the sidebar shall be visually highlighted.
    - The URL in the top address bar shall update to reflect the URL of the active tab.

## 3. Non-Functional Requirements

- **NFR1: Performance:** The UI must be responsive and fluid, with no noticeable lag when switching tabs or resizing the window.
- **NFR2: Design Adherence:** All UI components must adhere to the `macos_ui` design system and the project's visual guidelines to ensure a native look and feel.

## 4. Acceptance Criteria

- A user can open the browser and see the main UI with the navigation bar, sidebar, and content area.
- A user can open a new tab using the "+" button in the sidebar.
- A user can click on different tabs in the sidebar and see the corresponding content and URL update correctly.
- A user can close a tab using the close button that appears on hover.
- A user can successfully drag and drop a tab to a new position in the sidebar list.

## 5. Out of Scope

- The actual rendering of web content within the WebView.
- The logic for back/forward/reload navigation.
- URL suggestions or search functionality in the address bar.
- Persistence of tabs across sessions.
