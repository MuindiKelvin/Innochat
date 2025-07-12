import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentInput extends StatefulWidget {
  final Function(String) onComment;
  final VoidCallback? onEmojiToggle;
  final VoidCallback? onMediaAttach;

  const CommentInput({
    Key? key,
    required this.onComment,
    this.onEmojiToggle,
    this.onMediaAttach,
  }) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();

  // Static method to access the controller from parent widgets
  static _CommentInputState? of(BuildContext context) {
    return context.findAncestorStateOfType<_CommentInputState>();
  }
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  List<String> _attachedMedia = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isExpanded = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendComment() {
    final comment = controller.text.trim();
    if (comment.isNotEmpty) {
      widget.onComment(comment);
      controller.clear();
      _attachedMedia.clear();
      _focusNode.unfocus();
      setState(() {
        _isExpanded = false;
      });
    }
  }

  void _removeMediaAttachment(String mediaUrl) {
    setState(() {
      _attachedMedia.remove(mediaUrl);
      // Remove from controller text as well
      final text = controller.text;
      final patterns = [
        '\n[IMAGE]$mediaUrl',
        '\n[VIDEO]$mediaUrl',
        '\n[GIF]$mediaUrl',
        '\n[FILE]$mediaUrl',
      ];

      String newText = text;
      for (String pattern in patterns) {
        newText = newText.replaceAll(pattern, '');
      }
      controller.text = newText;
    });
  }

  List<Widget> _buildMediaPreviews() {
    List<Widget> previews = [];
    final text = controller.text;

    // Extract media URLs from text
    final imagePattern = RegExp(r'\[IMAGE\](.*?)(?=\n|$)');
    final videoPattern = RegExp(r'\[VIDEO\](.*?)(?=\n|$)');
    final gifPattern = RegExp(r'\[GIF\](.*?)(?=\n|$)');
    final filePattern = RegExp(r'\[FILE\](.*?)(?=\n|$)');

    // Find all media matches
    final allMatches = <Match>[];
    allMatches.addAll(imagePattern.allMatches(text));
    allMatches.addAll(videoPattern.allMatches(text));
    allMatches.addAll(gifPattern.allMatches(text));
    allMatches.addAll(filePattern.allMatches(text));

    for (Match match in allMatches) {
      final fullMatch = match.group(0)!;
      final url = match.group(1)!;
      final type = fullMatch.contains('[IMAGE]')
          ? 'image'
          : fullMatch.contains('[VIDEO]')
              ? 'video'
              : fullMatch.contains('[GIF]')
                  ? 'gif'
                  : 'file';

      previews.add(_buildMediaPreview(url, type));
    }

    return previews;
  }

  Widget _buildMediaPreview(String url, String type) {
    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'image':
        icon = Icons.image;
        color = Colors.green;
        label = 'Image';
        break;
      case 'video':
        icon = Icons.video_file;
        color = Colors.blue;
        label = 'Video';
        break;
      case 'gif':
        icon = Icons.gif;
        color = Colors.orange;
        label = 'GIF';
        break;
      default:
        icon = Icons.attach_file;
        color = Colors.grey;
        label = 'File';
    }

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeMediaAttachment(url),
            child: Icon(
              Icons.close,
              size: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaPreviews = _buildMediaPreviews();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media previews
          if (mediaPreviews.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                children: mediaPreviews,
              ),
            ),

          // Comment input row
          Row(
            children: [
              // Emoji button
              if (widget.onEmojiToggle != null)
                IconButton(
                  onPressed: widget.onEmojiToggle,
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  color: Colors.deepPurple,
                ),

              // Text input
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: _focusNode,
                  maxLines: _isExpanded ? 4 : 1,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: _sendComment,
                  icon: Icon(
                    Icons.send,
                    color: controller.text.trim().isNotEmpty
                        ? Colors.deepPurple
                        : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),

          // Expanded controls
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Add to your comment',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (widget.onMediaAttach != null)
                    IconButton(
                      onPressed: widget.onMediaAttach,
                      icon: const Icon(Icons.add_photo_alternate),
                      color: Colors.deepPurple,
                      iconSize: 20,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
