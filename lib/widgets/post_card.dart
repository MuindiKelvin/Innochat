import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:innochat/models/post.dart';
import 'package:innochat/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;
  final bool showActions;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showActions = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final DatabaseService _databaseService = DatabaseService();
  final user = FirebaseAuth.instance.currentUser!;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLiked = false;
  final Set<String> _likedPosts = {};

  // Standard media dimensions for uniformity
  static const double _mediaHeight = 250.0;
  static const double _mediaAspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _checkIfLiked() {
    setState(() {
      _isLiked = _likedPosts.contains(widget.post.id);
    });
  }

  void _initializeVideo() {
    if (widget.post.videoUrl != null) {
      _videoController = VideoPlayerController.network(widget.post.videoUrl!);
      _videoController!.initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
      }).catchError((error) {
        print('Error initializing video: $error');
      });
    }
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
          padding: const EdgeInsets.all(2),
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

  Widget _buildMediaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display images
        if (widget.post.imageUrl != null &&
            widget.post.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImageGallery(),
        ],

        // Display video
        if (widget.post.videoUrl != null &&
            widget.post.videoUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildVideoPlayer(),
        ],

        // Display document
        if (widget.post.documentUrl != null &&
            widget.post.documentUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDocumentPreview(),
        ],
      ],
    );
  }

  Widget _buildImageGallery() {
    final imageUrls = widget.post.imageUrl!
        .split(',')
        .where((url) => url.isNotEmpty)
        .toList();

    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _mediaHeight,
      width: double.infinity,
      child: imageUrls.length == 1
          ? _buildSingleImage(imageUrls[0])
          : _buildMultipleImages(imageUrls),
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: _mediaHeight,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleImages(List<String> imageUrls) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: imageUrls.length >= 4 ? 2 : imageUrls.length,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: imageUrls.length == 2
              ? 1.0
              : imageUrls.length == 3
                  ? 0.8
                  : 1.0,
        ),
        itemCount: imageUrls.length > 4 ? 4 : imageUrls.length,
        itemBuilder: (context, index) {
          final isLastItem = index == 3 && imageUrls.length > 4;
          return Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),
              if (isLastItem)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '+${imageUrls.length - 3}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return SizedBox(
      height: _mediaHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: !_isVideoInitialized || _videoController == null
            ? Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Container(
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: Stack(
                      children: [
                        VideoPlayer(_videoController!),
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: AnimatedOpacity(
                                  opacity: _videoController!.value.isPlaying
                                      ? 0.0
                                      : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return GestureDetector(
      onTap: () async {
        final url = widget.post.documentUrl!;
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Could not open document', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.documentName ?? 'Document',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  Text(
                    'Tap to open',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new,
              color: Colors.blue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    widget.post.username[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserBadge(widget.post.username),
                      Text(
                        _formatTimestamp(widget.post.timestamp),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Post content
            if (widget.post.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.post.content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],

            // Media content
            _buildMediaContent(),

            // Actions
            if (widget.showActions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildActionButton(
                    icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    label: '${widget.post.likes}',
                    onPressed: _toggleLike,
                    isActive: _isLiked,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: '${widget.post.comments}',
                    onPressed: widget.onTap,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: '${widget.post.shares}',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.deepPurple : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isActive ? Colors.deepPurple : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
