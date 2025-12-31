import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

/// Navigation controls widget with back, forward, and reload buttons
class NavigationControls extends StatelessWidget {
  const NavigationControls({
    super.key,
    required this.canGoBack,
    required this.canGoForward,
    required this.isLoading,
    required this.onBack,
    required this.onForward,
    required this.onReload,
  });

  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back button
        MacosIconButton(
          icon: const MacosIcon(
            Icons.arrow_back_ios,
            size: 16.0,
          ),
          onPressed: canGoBack ? onBack : null,
          semanticLabel: 'Go back',
        ),
        
        const SizedBox(width: 2.0),
        
        // Forward button
        MacosIconButton(
          icon: const MacosIcon(
            Icons.arrow_forward_ios,
            size: 16.0,
          ),
          onPressed: canGoForward ? onForward : null,
          semanticLabel: 'Go forward',
        ),
        
        const SizedBox(width: 2.0),
        
        // Reload/Stop button
        MacosIconButton(
          icon: MacosIcon(
            isLoading ? Icons.close : Icons.refresh,
            size: 16.0,
          ),
          onPressed: onReload,
          semanticLabel: isLoading ? 'Stop loading' : 'Reload page',
        ),
      ],
    );
  }
}
