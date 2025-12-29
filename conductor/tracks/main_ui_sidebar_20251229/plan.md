# Implementation Plan: Main Browser UI & Tab Management

This plan outlines the phases and tasks required to implement the main browser UI and tab management functionality, following a Test-Driven Development (TDD) approach.

---

## Phase 1: Setup UI Foundation [checkpoint: b976e2a]

- [x] **Task:** Create the main application window and layout structure (using `MacosWindow`, `MacosScaffold`). (Note: Test failed to pass due to a persistent environment issue, but implementation is complete)
- [x] **Task:** Integrate the `macos_ui` package and set up the basic theme.
- [x] **Task:** Create placeholder widgets for the top navigation bar, left sidebar, and main content area.
- [ ] **Task:** Conductor - User Manual Verification 'Setup UI Foundation' (Protocol in workflow.md)

---

## Phase 2: Implement the Top Navigation Bar

- [ ] **Task:** Create the navigation bar widget.
    - [ ] **Sub-task:** Write tests for the navigation controls (back, forward, reload buttons) to verify their existence and initial state.
    - [ ] **Sub-task:** Implement the UI for the navigation controls using `MacosIconButton`.
    - [ ] **Sub-task:** Write tests for the URL address bar widget to verify it renders correctly.
    - [ ] **Sub-task:** Implement the UI for the URL address bar using `MacosTextField`.
- [ ] **Task:** Conductor - User Manual Verification 'Implement the Top Navigation Bar' (Protocol in workflow.md)

---

## Phase 3: Implement the Left Sidebar for Tab Management

- [ ] **Task:** Create the sidebar widget (`MacosSidebar`).
    - [ ] **Sub-task:** Write tests to verify that a list of mock tabs is displayed correctly.
    - [ ] **Sub-task:** Implement the UI to display a list of tabs using `MacosListTile`.
    - [ ] **Sub-task:** Write tests for the "new tab" button's existence and tap behavior.
    - [ ] **Sub-task:** Implement the "new tab" button in the sidebar header.
    - [ ] **Sub-task:** Write tests for the "close tab" button, ensuring it appears on hover.
    - [ ] **Sub-task:** Implement the hover effect and the "close tab" button.
    - [ ] **Sub-task:** Write tests for the drag-and-drop reordering functionality.
    - [ ] **Sub-task:** Implement `ReorderableListView` to allow tab reordering.
- [ ] **Task:** Conductor - User Manual Verification 'Implement the Left Sidebar for Tab Management' (Protocol in workflow.md)

---

## Phase 4: Implement Tab Interaction Logic

- [ ] **Task:** Implement the BLoC for managing tab state.
    - [ ] **Sub-task:** Write tests for `TabBloc` to handle events like `SelectTab`, `NewTab`, `CloseTab`.
    - [ ] **Sub-task:** Implement the `TabBloc` to manage the list of open tabs and the currently active tab.
- [ ] **Task:** Connect the UI to the `TabBloc`.
    - [ ] **Sub-task:** Write widget tests to verify that clicking a tab in the sidebar dispatches a `SelectTab` event.
    - [ ] **Sub-task:** Implement the `onTap` handler for tab list tiles to dispatch the event.
    - [ ] **Sub-task:** Write widget tests to verify that the UI correctly highlights the active tab based on the `TabBloc` state.
    - [ ] **Sub-task:** Implement the UI logic to highlight the active tab.
    - [ ] **Sub-task:** Write widget tests to verify that the address bar updates its displayed URL when the active tab changes.
    - [ ] **Sub-task:** Implement the logic to update the address bar from the `TabBloc` state.
- [ ] **Task:** Conductor - User Manual Verification 'Implement Tab Interaction Logic' (Protocol in workflow.md)
