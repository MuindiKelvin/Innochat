import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentInput extends StatefulWidget {
  final Function(String) onComment;
  final VoidCallback onEmojiToggle;

  // Static method to access the state from parent widgets
  static CommentInputState? of(BuildContext context) =>
      context.findAncestorStateOfType<CommentInputState>();

  const CommentInput({
    super.key,
    required this.onComment,
    required this.onEmojiToggle,
  });

  @override
  CommentInputState createState() => CommentInputState();
}

class CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isEmojiMode = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onComment(text);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  void _toggleEmojiMode() {
    setState(() {
      _isEmojiMode = !_isEmojiMode;
    });
    widget.onEmojiToggle();

    // Handle focus based on emoji mode
    if (_isEmojiMode) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (text) {
                  setState(() {}); // Rebuild to show/hide clear button
                },
                onSubmitted: (value) => _submitComment(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Emoji Button
          Container(
            decoration: BoxDecoration(
              color: _isEmojiMode ? Colors.deepPurple : Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: Icon(
                Icons.emoji_emotions,
                color: _isEmojiMode ? Colors.white : Colors.deepPurple,
              ),
              onPressed: _toggleEmojiMode,
              tooltip: 'Add emoji',
            ),
          ),

          const SizedBox(width: 8),

          // Send Button
          Container(
            decoration: BoxDecoration(
              color: _controller.text.isNotEmpty
                  ? Colors.deepPurple
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: _controller.text.isNotEmpty
                    ? Colors.white
                    : Colors.grey[600],
              ),
              onPressed: _controller.text.isNotEmpty ? _submitComment : null,
              tooltip: 'Send comment',
            ),
          ),
        ],
      ),
    );
  }

  // Getter to access the controller from parent widgets
  TextEditingController get controller => _controller;

  // Getter to access the focus node
  FocusNode get focusNode => _focusNode;

  // Method to insert text at cursor position
  void insertText(String text) {
    final currentText = _controller.text;
    final selection = _controller.selection;

    if (selection.isValid) {
      final newText = currentText.substring(0, selection.start) +
          text +
          currentText.substring(selection.end);

      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + text.length,
      );
    } else {
      _controller.text = currentText + text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }

    setState(() {}); // Rebuild to update send button state
  }
}
