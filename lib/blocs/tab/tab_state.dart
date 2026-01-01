import 'package:equatable/equatable.dart';
import '../../models/tab.dart';

/// Sentinel object for copyWith methods to distinguish between null and not provided
const Object _sentinel = Object();

/// Base class for all tab states
abstract class TabState extends Equatable {
  const TabState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no tabs are loaded
class TabInitial extends TabState {
  const TabInitial();
}

/// State when tabs are being loaded
class TabLoading extends TabState {
  const TabLoading();
}

/// State when tabs are successfully loaded and managed
class TabLoaded extends TabState {
  const TabLoaded({
    required this.tabs,
    required this.activeTabId,
    this.isSessionRestored = false,
  });

  final List<Tab> tabs;
  final String? activeTabId;
  final bool isSessionRestored;

  /// Get the currently active tab
  Tab? get activeTab {
    if (activeTabId == null) return null;
    try {
      return tabs.firstWhere((tab) => tab.id == activeTabId);
    } catch (e) {
      return null;
    }
  }

  /// Get the index of the active tab
  int get activeTabIndex {
    if (activeTabId == null) return -1;
    return tabs.indexWhere((tab) => tab.id == activeTabId);
  }

  /// Check if there are any tabs
  bool get hasTabs => tabs.isNotEmpty;

  /// Get the number of tabs
  int get tabCount => tabs.length;

  /// Check if a specific tab exists
  bool hasTab(String tabId) {
    return tabs.any((tab) => tab.id == tabId);
  }

  /// Get a tab by its ID
  Tab? getTab(String tabId) {
    try {
      return tabs.firstWhere((tab) => tab.id == tabId);
    } catch (e) {
      return null;
    }
  }

  /// Get the index of a tab by its ID
  int getTabIndex(String tabId) {
    return tabs.indexWhere((tab) => tab.id == tabId);
  }

  /// Create a copy of this state with updated values
  TabLoaded copyWith({
    List<Tab>? tabs,
    Object? activeTabId = _sentinel,
    bool? isSessionRestored,
  }) {
    return TabLoaded(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId == _sentinel ? this.activeTabId : activeTabId as String?,
      isSessionRestored: isSessionRestored ?? this.isSessionRestored,
    );
  }

  /// Create a copy with a new active tab ID
  TabLoaded withActiveTab(String? tabId) {
    return copyWith(activeTabId: tabId);
  }

  /// Create a copy with updated tabs list
  TabLoaded withTabs(List<Tab> newTabs) {
    return copyWith(tabs: newTabs);
  }

  /// Create a copy with an added tab
  TabLoaded withAddedTab(Tab tab, {bool makeActive = true}) {
    final newTabs = List<Tab>.from(tabs)..add(tab);
    return TabLoaded(
      tabs: newTabs,
      activeTabId: makeActive ? tab.id : activeTabId,
      isSessionRestored: isSessionRestored,
    );
  }

  /// Create a copy with a removed tab
  TabLoaded withRemovedTab(String tabId) {
    final newTabs = tabs.where((tab) => tab.id != tabId).toList();
    String? newActiveTabId = activeTabId;

    // If we're removing the active tab, select another one
    if (activeTabId == tabId && newTabs.isNotEmpty) {
      final removedIndex = tabs.indexWhere((tab) => tab.id == tabId);
      if (removedIndex > 0) {
        // Select the previous tab
        newActiveTabId = newTabs[removedIndex - 1].id;
      } else if (newTabs.isNotEmpty) {
        // Select the first tab
        newActiveTabId = newTabs[0].id;
      } else {
        newActiveTabId = null;
      }
    } else if (activeTabId == tabId) {
      newActiveTabId = null;
    }

    return TabLoaded(
      tabs: newTabs,
      activeTabId: newActiveTabId,
      isSessionRestored: isSessionRestored,
    );
  }

  /// Create a copy with an updated tab
  TabLoaded withUpdatedTab(String tabId, Tab updatedTab) {
    final newTabs = tabs.map((tab) {
      return tab.id == tabId ? updatedTab : tab;
    }).toList();

    return copyWith(tabs: newTabs);
  }

  /// Create a copy with reordered tabs
  TabLoaded withReorderedTabs(int oldIndex, int newIndex) {
    final newTabs = List<Tab>.from(tabs);
    final tab = newTabs.removeAt(oldIndex);
    newTabs.insert(newIndex, tab);

    return copyWith(tabs: newTabs);
  }

  @override
  List<Object?> get props => [tabs, activeTabId, isSessionRestored];

  @override
  String toString() {
    return 'TabLoaded(tabs: ${tabs.length}, activeTabId: $activeTabId, isSessionRestored: $isSessionRestored)';
  }
}

/// State when there's an error with tab management
class TabError extends TabState {
  const TabError({
    required this.message,
    this.tabs = const [],
    this.activeTabId,
  });

  final String message;
  final List<Tab> tabs;
  final String? activeTabId;

  @override
  List<Object?> get props => [message, tabs, activeTabId];

  @override
  String toString() {
    return 'TabError(message: $message, tabs: ${tabs.length})';
  }
}

/// State when a tab operation is in progress
class TabOperationInProgress extends TabState {
  const TabOperationInProgress({
    required this.operation,
    required this.tabs,
    required this.activeTabId,
  });

  final String operation;
  final List<Tab> tabs;
  final String? activeTabId;

  @override
  List<Object?> get props => [operation, tabs, activeTabId];

  @override
  String toString() {
    return 'TabOperationInProgress(operation: $operation, tabs: ${tabs.length})';
  }
}
