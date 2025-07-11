import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:innochat/models/post.dart';
import 'package:innochat/services/database_service.dart';
import 'package:innochat/widgets/comment_input.dart';
import 'package:innochat/widgets/post_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

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
  Set<String> _likedPosts = {}; // Track liked posts locally

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
                PostCard(post: post, onTap: () {}),

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
                            title: Text(
                              comment['username'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
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

                // Comment Input
                CommentInput(
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
