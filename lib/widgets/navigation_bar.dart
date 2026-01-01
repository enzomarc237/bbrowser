import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import '../blocs/tab/tab_bloc.dart';
import '../blocs/tab/tab_event.dart';
import '../blocs/tab/tab_state.dart';
import 'navigation_controls.dart';
import 'address_bar.dart';

/// Navigation bar widget containing navigation controls and address bar
class BrowserNavigationBar extends StatelessWidget {
  const BrowserNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabBloc, TabState>(
      builder: (context, state) {
        final activeTab = state is TabLoaded ? state.activeTab : null;
        
        return ToolBar(
          height: 52.0,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).canvasColor,
            border: Border(
              bottom: BorderSide(
                color: MacosTheme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          title: Row(
            children: [
              // Navigation controls (back, forward, reload)
              NavigationControls(
                canGoBack: activeTab?.canGoBack ?? false,
                canGoForward: activeTab?.canGoForward ?? false,
                isLoading: activeTab?.isLoading ?? false,
                onBack: () => _onNavigateBack(context),
                onForward: () => _onNavigateForward(context),
                onReload: () => _onReload(context),
              ),
              
              const SizedBox(width: 8.0),
              
              // Address bar
              Expanded(
                child: AddressBar(
                  url: activeTab?.url ?? '',
                  isSecure: activeTab?.isSecure ?? false,
                  isLoading: activeTab?.isLoading ?? false,
                  loadingProgress: activeTab?.loadingProgress ?? 0.0,
                  onUrlSubmitted: (url) => _onUrlSubmitted(context, url),
                ),
              ),
              
              const SizedBox(width: 8.0),
              
              // Additional controls (bookmark, settings, etc.)
              _buildAdditionalControls(context),
            ],
          ),
        );
      },
    );
  }

  /// Builds additional controls like bookmark and settings buttons
  Widget _buildAdditionalControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacosIconButton(
          icon: const MacosIcon(
            Icons.bookmark_border,
            size: 18.0,
          ),
          onPressed: () => _onBookmark(context),
          semanticLabel: 'Bookmark this page',
        ),
        const SizedBox(width: 4.0),
        MacosIconButton(
          icon: const MacosIcon(
            Icons.more_horiz,
            size: 18.0,
          ),
          onPressed: () => _onShowMenu(context),
          semanticLabel: 'More options',
        ),
      ],
    );
  }

  /// Handles navigation back
  void _onNavigateBack(BuildContext context) {
    context.read<TabBloc>().add(const TabNavigateBack());
  }

  /// Handles navigation forward
  void _onNavigateForward(BuildContext context) {
    context.read<TabBloc>().add(const TabNavigateForward());
  }

  /// Handles page reload
  void _onReload(BuildContext context) {
    context.read<TabBloc>().add(const TabReload());
  }

  /// Handles URL submission
  void _onUrlSubmitted(BuildContext context, String url) {
    context.read<TabBloc>().add(TabNavigateToUrl(url));
  }

  /// Handles bookmark action
  void _onBookmark(BuildContext context) {
    // TODO: Implement bookmark functionality
    debugPrint('Bookmark action triggered');
  }

  /// Handles showing more options menu
  void _onShowMenu(BuildContext context) {
    // TODO: Implement more options menu
    debugPrint('More options menu triggered');
  }
}
