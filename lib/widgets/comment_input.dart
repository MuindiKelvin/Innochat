import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentInput extends StatefulWidget {
  final Function(String) onComment;
  final VoidCallback onEmojiToggle;
  final TextEditingController? controller;

  const CommentInput({
    super.key,
    required this.onComment,
    required this.onEmojiToggle,
    this.controller,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();

  // Static method to access the state from parent widgets
  static _CommentInputState? of(BuildContext context) {
    return context.findAncestorStateOfType<_CommentInputState>();
  }
}

class _CommentInputState extends State<CommentInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  // Getter for the controller to be accessed from parent
  TextEditingController get controller => _controller;

  void _submitComment() {
    final comment = _controller.text.trim();
    if (comment.isNotEmpty) {
      widget.onComment(comment);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji button
            IconButton(
              onPressed: widget.onEmojiToggle,
              icon: const Icon(
                Icons.emoji_emotions_outlined,
                color: Colors.deepPurple,
              ),
              tooltip: 'Add emoji',
            ),

            // Comment input field
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _submitComment,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Send comment',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
