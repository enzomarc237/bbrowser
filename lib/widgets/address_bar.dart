import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import '../services/url_validator.dart';

/// Address bar widget for URL input and display
class AddressBar extends StatefulWidget {
  const AddressBar({
    super.key,
    required this.url,
    required this.isSecure,
    required this.isLoading,
    required this.loadingProgress,
    required this.onUrlSubmitted,
  });

  final String url;
  final bool isSecure;
  final bool isLoading;
  final double loadingProgress;
  final ValueChanged<String> onUrlSubmitted;

  @override
  State<AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<AddressBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
    _focusNode = FocusNode();
    
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {
      _isEditing = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(AddressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controller text only if not currently editing
    if (!_isEditing && widget.url != oldWidget.url) {
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border.all(
          color: _focusNode.hasFocus
              ? MacosTheme.of(context).primaryColor
              : MacosTheme.of(context).dividerColor,
          width: _focusNode.hasFocus ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Stack(
        children: [
          // Loading progress indicator
          if (widget.isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.0),
                ),
                child: LinearProgressIndicator(
                  value: widget.loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MacosTheme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          
          // Address bar content
          Row(
            children: [
              // Security indicator
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildSecurityIndicator(),
              ),
              
              // URL text field
              Expanded(
                child: MacosTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  placeholder: 'Enter URL or search...',
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  onSubmitted: (value) {
                    _onSubmitted(value);
                  },
                  onTap: () {
                    // Select all text when tapping the address bar
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                  },
                ),
              ),
              
              // Additional actions
              if (_isEditing) ...[
                MacosIconButton(
                  icon: const MacosIcon(
                    Icons.clear,
                    size: 16.0,
                  ),
                  onPressed: () {
                    _controller.clear();
                  },
                  semanticLabel: 'Clear URL',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the security indicator icon
  Widget _buildSecurityIndicator() {
    if (widget.url.isEmpty || widget.url == 'about:blank') {
      return const SizedBox(width: 20.0);
    }

    IconData icon;
    Color color;

    if (widget.isSecure) {
      icon = Icons.lock;
      color = Colors.green;
    } else if (widget.url.startsWith('http://')) {
      icon = Icons.info_outline;
      color = Colors.orange;
    } else {
      icon = Icons.language;
      color = MacosTheme.of(context).primaryColor;
    }

    return MacosIcon(
      icon,
      size: 16.0,
      color: color,
    );
  }

  /// Handles URL submission
  void _onSubmitted(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return;

    // Use URL validator to process the input
    final validationResult = UrlValidator.validate(trimmedValue);
    
    if (validationResult.isValid) {
      widget.onUrlSubmitted(validationResult.normalizedUrl);
    } else {
      // Show error or fallback to search
      final searchResult = UrlValidator.validate('search: $trimmedValue');
      widget.onUrlSubmitted(searchResult.normalizedUrl);
    }

    _focusNode.unfocus();
  }
}
