import 'package:flutter/material.dart';

class SuggestionTextField extends StatefulWidget {
  final List<String> suggestions;
  final String? hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSuggestionSelected;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final double maxSuggestionHeight;
  final int maxSuggestions;

  const SuggestionTextField({
    Key? key,
    required this.suggestions,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSuggestionSelected,
    this.decoration,
    this.textStyle,
    this.maxSuggestionHeight = 200,
    this.maxSuggestions = 5,
  }) : super(key: key);

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _filteredSuggestions = widget.suggestions;
    
    // Listen to focus changes to hide suggestions when focus is lost
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  // Public method to hide suggestions and close keyboard from outside
  void hideSuggestionsAndCloseKeyboard() {
    _focusNode.unfocus(); // This will close the keyboard
    _hideSuggestions();
  }

  // Public method to hide suggestions from outside
  void hideSuggestions() {
    _hideSuggestions();
  }

  void _createOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    // _filteredSuggestions = widget.suggestions;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 6.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(14.0),
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: widget.maxSuggestionHeight,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: Colors.pink.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _filteredSuggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.pink[300], size: 20),
                          SizedBox(width: 10),
                          Text(
                            'No suggestions found',
                            style: TextStyle(color: Colors.pink[400], fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredSuggestions.length > widget.maxSuggestions
                          ? widget.maxSuggestions
                          : _filteredSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _filteredSuggestions[index];
                        return InkWell(
                          borderRadius: index == 0
                              ? const BorderRadius.vertical(top: Radius.circular(14.0))
                              : index == (_filteredSuggestions.length - 1) ||
                                      index == (widget.maxSuggestions - 1)
                                  ? const BorderRadius.vertical(bottom: Radius.circular(14.0))
                                  : BorderRadius.zero,
                          onTap: () {
                            _controller.text = suggestion;
                            widget.onSuggestionSelected?.call(suggestion);
                            _hideSuggestions();
                            _focusNode.unfocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 14.0,
                            ),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.pink.withOpacity(0.03)
                                  : Colors.transparent,
                              border: (index < _filteredSuggestions.length - 1 &&
                                      index < widget.maxSuggestions - 1)
                                  ? Border(
                                      bottom: BorderSide(
                                        color: Colors.pink.shade100,
                                        width: 0.7,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Removed search icon here
                                // const SizedBox(width: 14), // Remove extra spacing if not needed
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionOverlay() {
     _filteredSuggestions = widget.suggestions;
    if (!_showSuggestions) {
      setState(() {
        _showSuggestions = true;
      });
      _createOverlay();
    }
  }

  void _hideSuggestions() {
    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
      });
      _removeOverlay();
    }
  }

  void _filterSuggestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestions = widget.suggestions;
      } else {
        _filteredSuggestions = widget.suggestions
            .where((suggestion) =>
                suggestion.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
    
    if (_showSuggestions) {
      _removeOverlay();
      _createOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        style: widget.textStyle ?? TextStyle(color: Colors.grey[700]),
        onTap: () {
          _showSuggestionOverlay();
        },
        onChanged: (value) {
          _filterSuggestions(value);
          widget.onChanged?.call(value);
        },
        decoration: (widget.decoration ??
        InputDecoration(
          hintText: widget.hintText ?? 'Type to search...',
          hintStyle: TextStyle(color: Colors.pink[300]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.pink[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.pink[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.pink[400]!, width: 2),
          ),
        )).copyWith(
          suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.text.isNotEmpty)
            IconButton(
          icon: Icon(Icons.clear, color: Colors.pink[400]),
          onPressed: () {
            setState(() {
              _controller.clear();
              _filterSuggestions('');
              widget.onChanged?.call('');
            });
          },
            ),
          // _showSuggestions
          // ? IconButton(
          //     icon: const Icon(Icons.keyboard_arrow_up),
          //     onPressed: () {
          //   _hideSuggestions();
          //   _focusNode.unfocus(); // Close keyboard when arrow is pressed
          //     },
          //   )
          // : const Icon(Icons.search),
        ],
          ),
        ),
      ),);
  }
}