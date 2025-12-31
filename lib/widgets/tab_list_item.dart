import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import '../models/tab.dart' as browser_tab;

/// Individual tab item in the sidebar list
class TabListItem extends StatefulWidget {
  const TabListItem({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onDuplicate,
  });

  final browser_tab.Tab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onDuplicate;

  @override
  State<TabListItem> createState() => _TabListItemState();
}

class _TabListItemState extends State<TabListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        // onSecondaryTap: () => _showContextMenu(context), // TODO: Implement context menu
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: BorderRadius.circular(6.0),
            border: widget.isActive
                ? Border.all(
                    color: MacosTheme.of(context).primaryColor,
                    width: 1.0,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Favicon or loading indicator
                _buildFavicon(),
                
                const SizedBox(width: 8.0),
                
                // Tab title and URL
                Expanded(
                  child: _buildTabInfo(),
                ),
                
                // Close button (shown on hover or if active)
                if (_isHovered || widget.isActive) ...[
                  const SizedBox(width: 4.0),
                  _buildCloseButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gets the background color based on state
  Color _getBackgroundColor(BuildContext context) {
    if (widget.isActive) {
      return MacosTheme.of(context).primaryColor.withValues(alpha: 0.1);
    } else if (_isHovered) {
      return MacosTheme.of(context).canvasColor;
    } else {
      return Colors.transparent;
    }
  }

  /// Builds the favicon or loading indicator
  Widget _buildFavicon() {
    if (widget.tab.isLoading) {
      return const SizedBox(
        width: 16.0,
        height: 16.0,
        child: ProgressCircle(
          radius: 8.0,
        ),
      );
    }

    if (widget.tab.hasError) {
      return const MacosIcon(
        Icons.error_outline,
        size: 16.0,
        color: Colors.red,
      );
    }

    if (widget.tab.favicon != null && widget.tab.favicon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(2.0),
        child: Image.network(
          widget.tab.favicon!,
          width: 16.0,
          height: 16.0,
          errorBuilder: (context, error, stackTrace) => _buildDefaultFavicon(),
        ),
      );
    }

    return _buildDefaultFavicon();
  }

  /// Builds the default favicon
  Widget _buildDefaultFavicon() {
    IconData icon;
    
    if (widget.tab.url.startsWith('https://')) {
      icon = Icons.lock;
    } else if (widget.tab.url.startsWith('http://')) {
      icon = Icons.language;
    } else {
      icon = Icons.tab;
    }

    return MacosIcon(
      icon,
      size: 16.0,
      color: MacosTheme.of(context).primaryColor,
    );
  }

  /// Builds the tab title and URL information
  Widget _buildTabInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab title
        Text(
          widget.tab.title.isNotEmpty ? widget.tab.title : 'Untitled',
          style: MacosTheme.of(context).typography.body.copyWith(
            fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
            color: widget.isActive
                ? MacosTheme.of(context).primaryColor
                : MacosColors.labelColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // URL (if different from title and not too long)
        if (_shouldShowUrl()) ...[
          const SizedBox(height: 2.0),
          Text(
            _getDisplayUrl(),
            style: MacosTheme.of(context).typography.caption1.copyWith(
              color: MacosColors.secondaryLabelColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Loading progress indicator
        if (widget.tab.isLoading && widget.tab.loadingProgress > 0) ...[
          const SizedBox(height: 4.0),
          LinearProgressIndicator(
            value: widget.tab.loadingProgress,
            backgroundColor: MacosTheme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              MacosTheme.of(context).primaryColor,
            ),
            minHeight: 2.0,
          ),
        ],
      ],
    );
  }

  /// Builds the close button
  Widget _buildCloseButton() {
    return MacosIconButton(
      icon: const MacosIcon(
        Icons.close,
        size: 14.0,
      ),
      onPressed: widget.onClose,
      semanticLabel: 'Close tab',
    );
  }

  /// Determines if URL should be shown
  bool _shouldShowUrl() {
    if (widget.tab.url.isEmpty || widget.tab.url == 'about:blank') {
      return false;
    }
    
    // Don't show URL if it's the same as the title
    if (widget.tab.title.toLowerCase().contains(widget.tab.url.toLowerCase()) ||
        widget.tab.url.toLowerCase().contains(widget.tab.title.toLowerCase())) {
      return false;
    }
    
    return true;
  }

  /// Gets the display URL (shortened)
  String _getDisplayUrl() {
    String url = widget.tab.url;
    
    // Remove protocol
    url = url.replaceFirst(RegExp(r'^https?://'), '');
    
    // Remove www.
    url = url.replaceFirst(RegExp(r'^www\.'), '');
    
    // Limit length
    if (url.length > 30) {
      url = '${url.substring(0, 27)}...';
    }
    
    return url;
  }

  // TODO: Implement context menu functionality
  // /// Shows context menu for tab actions
  // void _showContextMenu(BuildContext context) {
  //   // Context menu implementation will be added later
  // }

  // TODO: Implement clipboard functionality when context menu is added
  // void _copyUrl(BuildContext context) {
  //   debugPrint('Copy URL: ${widget.tab.url}');
  // }
}
