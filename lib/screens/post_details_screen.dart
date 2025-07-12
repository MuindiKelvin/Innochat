import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:innochat/models/post.dart';
import 'package:innochat/services/database_service.dart';
import 'package:innochat/widgets/comment_input.dart';
import 'package:innochat/widgets/post_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostDetailsScreen extends StatefulWidget {
  final Post post;
  const PostDetailsScreen({super.key, required this.post});

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _databaseService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser!;
  bool _isEmojiVisible = false;
  bool _isLiked = false;
  final Set<String> _likedPosts = {}; // Track liked posts locally

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  void _checkIfLiked() {
    // Check if current user has already liked this post
    // You might want to store this in a user preference or database
    setState(() {
      _isLiked = _likedPosts.contains(widget.post.id);
    });
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likedPosts.add(widget.post.id);
      } else {
        _likedPosts.remove(widget.post.id);
      }
    });

    // Update the like count in the database
    int newLikeCount = _isLiked ? widget.post.likes + 1 : widget.post.likes - 1;
    await _databaseService.likePost(widget.post.id, newLikeCount);
  }

  Future<void> _sharePost() async {
    await _databaseService.sharePost(widget.post.id, widget.post.shares + 1);
    Share.share(widget.post.content);
  }

  Future<void> _deletePost() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post', style: GoogleFonts.poppins()),
        content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _databaseService.deletePost(widget.post.id);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Post deleted successfully', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error deleting post: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePost() async {
    final controller = TextEditingController(text: widget.post.content);

    final updatedContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Post', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Edit your post',
            hintStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (updatedContent != null &&
        updatedContent.isNotEmpty &&
        updatedContent != widget.post.content) {
      try {
        await _databaseService.updatePost(widget.post.id, updatedContent);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Post updated successfully', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error updating post: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onEmojiSelected(String emoji) {
    // Get the comment input widget and add emoji to it
    final commentInputState = CommentInput.of(context);
    if (commentInputState != null) {
      final controller = commentInputState.controller;
      final currentText = controller.text;
      final selection = controller.selection;

      // Insert emoji at cursor position
      final newText = currentText.substring(0, selection.start) +
          emoji +
          currentText.substring(selection.end);

      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: selection.start + emoji.length,
      );
    }
  }

  // Blue badge widget for verified users
  Widget _buildBlueBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: Icon(
        Icons.verified,
        color: Colors.blue,
        size: 16,
      ),
    );
  }

  // Media display widget - simplified version
  Widget _buildMediaDisplay(String? imagePath) {
    // For now, we'll just show a placeholder for media
    // You can enhance this later when you add media fields to your Post model
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details', style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: widget.post.userId == user.uid
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') _deletePost();
                    if (value == 'update') _updatePost();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'update',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Update', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : [],
      ),
      body: StreamBuilder<Post>(
        stream: _databaseService.getPost(widget.post.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) return const SizedBox.shrink();
          final post = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Enhanced Post Card with media support
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info with blue badge
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                post.username[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    post.username,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  _buildBlueBadge(), // Blue badge for all users
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Post content
                        Text(
                          post.content,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        // Post stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${post.likes} likes • ${post.shares} shares',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${post.comments} comments',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Enhanced Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Like Button with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          onPressed: _toggleLike,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _isLiked
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              key: ValueKey(_isLiked),
                              color:
                                  _isLiked ? Colors.white : Colors.deepPurple,
                            ),
                          ),
                          label: Text(
                            '${post.likes} Likes',
                            style: GoogleFonts.poppins(
                              color:
                                  _isLiked ? Colors.white : Colors.deepPurple,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isLiked ? Colors.deepPurple : Colors.white,
                            foregroundColor:
                                _isLiked ? Colors.white : Colors.deepPurple,
                            side: BorderSide(color: Colors.deepPurple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),

                      // Share Button
                      ElevatedButton.icon(
                        onPressed: _sharePost,
                        icon: const Icon(Icons.share, color: Colors.deepPurple),
                        label: Text(
                          '${post.shares} Shares',
                          style: GoogleFonts.poppins(color: Colors.deepPurple),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          side: BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.grey[300], thickness: 1),

                // Comments Section Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.comment, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'Comments',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Comments List
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _databaseService.getComments(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.comment_outlined,
                                  size: 48, color: Colors.grey[400]),
                              SizedBox(height: 8),
                              Text(
                                'No comments yet!',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Be the first to comment',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data![index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                comment['username'][0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  comment['username'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                _buildBlueBadge(), // Blue badge for commenters too
                              ],
                            ),
                            subtitle: Text(
                              comment['content'],
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Enhanced Comment Input with basic media support
                EnhancedCommentInput(
                  onComment: (comment) async {
                    if (comment.isNotEmpty) {
                      await _databaseService.addComment(
                        post.id,
                        user.uid,
                        user.email!.split('@')[0],
                        comment,
                      );
                    }
                  },
                  onEmojiToggle: () {
                    setState(() => _isEmojiVisible = !_isEmojiVisible);
                  },
                ),

                // Emoji Picker
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isEmojiVisible ? 250 : 0,
                  child: _isEmojiVisible
                      ? EmojiPicker(
                          onEmojiSelected: (category, emoji) {
                            _onEmojiSelected(emoji.emoji);
                          },
                          config: const Config(
                            height: 256,
                            checkPlatformCompatibility: true,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Enhanced Comment Input Widget with basic media support
class EnhancedCommentInput extends StatefulWidget {
  final Function(String comment) onComment;
  final VoidCallback onEmojiToggle;

  const EnhancedCommentInput({
    Key? key,
    required this.onComment,
    required this.onEmojiToggle,
  }) : super(key: key);

  @override
  _EnhancedCommentInputState createState() => _EnhancedCommentInputState();
}

class _EnhancedCommentInputState extends State<EnhancedCommentInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _showImageOptions = false;

  Future<void> _pickImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Photo from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        XFile? file;
        if (result == 'gallery') {
          file = await _imagePicker.pickImage(source: ImageSource.gallery);
        } else if (result == 'camera') {
          file = await _imagePicker.pickImage(source: ImageSource.camera);
        }

        if (file != null) {
          setState(() {
            _selectedImage = File(file!.path);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    String commentText = _controller.text;

    // If there's an image, you could upload it here and get a URL
    // For now, we'll just mention that an image was attached
    if (_selectedImage != null) {
      commentText += ' [Image attached]';
    }

    widget.onComment(commentText);

    setState(() {
      _controller.clear();
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImage = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _pickImage,
                icon: Icon(Icons.photo_camera, color: Colors.deepPurple),
              ),
              IconButton(
                onPressed: widget.onEmojiToggle,
                icon: Icon(Icons.emoji_emotions, color: Colors.deepPurple),
              ),
              IconButton(
                onPressed: _submitComment,
                icon: Icon(Icons.send, color: Colors.deepPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Simplified TextEditingController extension for emoji support
extension CommentInputController on TextEditingController {
  void insertEmoji(String emoji) {
    final currentText = text;
    final selection = this.selection;

    final newText = currentText.substring(0, selection.start) +
        emoji +
        currentText.substring(selection.end);

    text = newText;
    this.selection = TextSelection.collapsed(
      offset: selection.start + emoji.length,
    );
  }
}
