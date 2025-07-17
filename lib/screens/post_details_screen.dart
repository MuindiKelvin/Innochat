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
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
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
  final Set<String> _likedPosts = {};
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  PlatformFile? _selectedDocument;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _checkIfLiked() {
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

    int newLikeCount = _isLiked ? widget.post.likes + 1 : widget.post.likes - 1;
    await _databaseService.likePost(widget.post.id, newLikeCount);
  }

  Future<void> _sharePost() async {
    await _databaseService.sharePost(widget.post.id, widget.post.shares + 1);
    Share.share(widget.post.content);
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _pickVideo() async {
    final XFile? video =
        await _imagePicker.pickVideo(source: ImageSource.gallery);
    setState(() {
      _selectedVideo = video;
    });
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'],
    );

    if (result != null) {
      setState(() {
        _selectedDocument = result.files.first;
      });
    }
  }

  Future<void> _deletePost() async {
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
    final currentText = _commentController.text;
    final selection = _commentController.selection;

    final newText = currentText.substring(0, selection.start) +
        emoji +
        currentText.substring(selection.end);

    _commentController.text = newText;
    _commentController.selection = TextSelection.collapsed(
      offset: selection.start + emoji.length,
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty &&
        _selectedImages.isEmpty &&
        _selectedVideo == null &&
        _selectedDocument == null) {
      return;
    }

    try {
      // Upload media files if any
      String? imageUrl;
      String? videoUrl;
      String? documentUrl;

      if (_selectedImages.isNotEmpty) {
        imageUrl = await _databaseService.uploadImages(_selectedImages);
      }

      if (_selectedVideo != null) {
        videoUrl = await _databaseService.uploadVideo(_selectedVideo!);
      }

      if (_selectedDocument != null) {
        documentUrl = await _databaseService.uploadDocument(_selectedDocument!);
      }

      await _databaseService.addCommentWithMedia(
        widget.post.id,
        user.uid,
        user.email!.split('@')[0],
        _commentController.text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        documentUrl: documentUrl,
      );

      // Clear the input
      _commentController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedVideo = null;
        _selectedDocument = null;
        _isEmojiVisible = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Comment added successfully', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error adding comment: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUserBadge(String username) {
    return Row(
      children: [
        Text(
          username,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    if (_selectedImages.isEmpty &&
        _selectedVideo == null &&
        _selectedDocument == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImages.isNotEmpty) ...[
            Text('Selected Images:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(_selectedImages[index].path,
                                  width: 100, height: 100, fit: BoxFit.cover)
                              : Image.file(File(_selectedImages[index].path),
                                  width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (_selectedVideo != null) ...[
            Text('Selected Video:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_file, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedVideo!.name,
                      style: GoogleFonts.poppins(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedVideo = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedDocument != null) ...[
            Text('Selected Document:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDocument!.name,
                      style: GoogleFonts.poppins(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDocument = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentMedia(Map<String, dynamic> comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comment['imageUrl'] != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: comment['imageUrl'],
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.error)),
              ),
            ),
          ),
        ],
        if (comment['videoUrl'] != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: IconButton(
                onPressed: () {
                  // Implement video player
                },
                icon:
                    const Icon(Icons.play_arrow, color: Colors.white, size: 50),
              ),
            ),
          ),
        ],
        if (comment['documentUrl'] != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final url = comment['documentUrl'];
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['documentName'] ?? 'Document',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Tap to download',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.download, color: Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ],
    );
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
                          const Icon(Icons.edit, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Update', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
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

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                                    color: _isLiked
                                        ? Colors.white
                                        : Colors.deepPurple,
                                  ),
                                ),
                                label: Text(
                                  '${post.likes} Likes',
                                  style: GoogleFonts.poppins(
                                    color: _isLiked
                                        ? Colors.white
                                        : Colors.deepPurple,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLiked
                                      ? Colors.deepPurple
                                      : Colors.white,
                                  foregroundColor: _isLiked
                                      ? Colors.white
                                      : Colors.deepPurple,
                                  side: const BorderSide(
                                      color: Colors.deepPurple),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),

                            // Share Button
                            ElevatedButton.icon(
                              onPressed: _sharePost,
                              icon: const Icon(Icons.share,
                                  color: Colors.deepPurple),
                              label: Text(
                                '${post.shares} Shares',
                                style: GoogleFonts.poppins(
                                    color: Colors.deepPurple),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepPurple,
                                side:
                                    const BorderSide(color: Colors.deepPurple),
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
                            const Icon(Icons.comment, color: Colors.deepPurple),
                            const SizedBox(width: 8),
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.comment_outlined,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.deepPurple,
                                            child: Text(
                                              comment['username'][0]
                                                  .toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildUserBadge(
                                                    comment['username']),
                                                if (comment['content']
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    comment['content'],
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      _buildCommentMedia(comment),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Media Preview
              _buildMediaPreview(),

              // Enhanced Comment Input
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Media buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.image, color: Colors.green),
                          tooltip: 'Add Images',
                        ),
                        IconButton(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.video_library,
                              color: Colors.blue),
                          tooltip: 'Add Video',
                        ),
                        IconButton(
                          onPressed: _pickDocument,
                          icon: const Icon(Icons.attach_file,
                              color: Colors.orange),
                          tooltip: 'Add Document',
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _isEmojiVisible = !_isEmojiVisible);
                          },
                          icon: const Icon(Icons.emoji_emotions,
                              color: Colors.amber),
                          tooltip: 'Add Emoji',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Comment input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle:
                                  GoogleFonts.poppins(color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide:
                                    const BorderSide(color: Colors.deepPurple),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: GoogleFonts.poppins(),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: IconButton(
                            onPressed: _addComment,
                            icon: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
          );
        },
      ),
    );
  }
}
