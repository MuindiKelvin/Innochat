import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:innochat/models/post.dart';
import 'package:innochat/screens/post_details_screen.dart';
import 'package:innochat/services/auth_service.dart';
import 'package:innochat/services/database_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _postController = TextEditingController();
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles = [];
  XFile? _videoFile;
  PlatformFile? _documentFile;
  VideoPlayerController? _videoController;
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ValueNotifier<bool>> _videoPlayingNotifiers = {};

  // Like tracking
  final Set<String> _likedPosts = {};

  // Animation controllers for background icons
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;
  late List<BackgroundIcon> _backgroundIcons;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateBackgroundIcons();
    _initializeVideoControllers();
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _generateBackgroundIcons() {
    final icons = [
      '💬',
      '🎉',
      '✨',
      '🌟',
      '💫',
      '🎊',
      '🎈',
      '🎁',
      '🔥',
      '💖',
      '👍',
      '😊',
      '🎵',
      '📱',
      '💭',
      '🌈',
      '🎯',
      '💡',
      '🎪',
      '🎨',
      '🎭',
      '🎪',
      '🎊',
      '🎉'
    ];

    _backgroundIcons = List.generate(15, (index) {
      return BackgroundIcon(
        icon: icons[Random().nextInt(icons.length)],
        x: Random().nextDouble(),
        y: Random().nextDouble(),
        size: 20 + Random().nextDouble() * 30,
        opacity: 0.1 + Random().nextDouble() * 0.2,
        rotationSpeed: 0.5 + Random().nextDouble() * 2,
        floatSpeed: 0.3 + Random().nextDouble() * 0.7,
      );
    });
  }

  Future<void> _initializeVideoControllers() async {
    _databaseService.getPosts().listen((posts) async {
      // Remove controllers for posts that no longer exist
      final currentPostIds = posts.map((post) => post.id).toSet();
      _videoControllers.removeWhere((id, controller) {
        if (!currentPostIds.contains(id)) {
          controller.dispose();
          _videoPlayingNotifiers[id]?.dispose();
          _videoPlayingNotifiers.remove(id);
          return true;
        }
        return false;
      });

      for (final post in posts) {
        if (post.videoUrl != null &&
            post.videoUrl!.isNotEmpty &&
            !_videoControllers.containsKey(post.id)) {
          final controller = VideoPlayerController.network(post.videoUrl!);
          try {
            await controller.initialize();
            if (mounted) {
              _videoControllers[post.id] = controller;
              _videoPlayingNotifiers[post.id] = ValueNotifier<bool>(
                  false); // Changed from true to false - no auto-play
              controller.setLooping(true);
              // REMOVED: controller.play(); - Videos will not auto-play
              controller.addListener(() {
                final isPlaying = controller.value.isPlaying;
                if (_videoPlayingNotifiers[post.id]?.value != isPlaying) {
                  _videoPlayingNotifiers[post.id]?.value = isPlaying;
                }
              });
              setState(() {}); // Only call setState for new controller
            } else {
              await controller.dispose();
            }
          } catch (error) {
            await controller.dispose();
            Fluttertoast.showToast(
                msg: '⚠️ Failed to load video for post ${post.id}: $error');
          }
        }
      }
    });
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    setState(() => _imageFiles = images);
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _videoFile = video);
      _videoController = VideoPlayerController.file(File(video.path))
        ..initialize().then((_) {
          setState(() {});
          // Don't auto-play preview video either
        });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'txt',
        'xlsx',
        'xls',
        'ppt',
        'pptx'
      ],
    );
    if (result != null) {
      setState(() => _documentFile = result.files.first);
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.isNotEmpty ||
        _imageFiles!.isNotEmpty ||
        _videoFile != null ||
        _documentFile != null) {
      try {
        String? imageUrl;
        String? videoUrl;
        String? documentUrl;
        String? documentName;

        // Upload images if any
        if (_imageFiles!.isNotEmpty) {
          imageUrl = await _databaseService.uploadImages(_imageFiles!);
        }

        // Upload video if any
        if (_videoFile != null) {
          videoUrl = await _databaseService.uploadVideo(_videoFile!);
        }

        // Upload document if any
        if (_documentFile != null) {
          documentUrl = await _databaseService.uploadDocument(_documentFile!);
          documentName = _documentFile!.name;
        }

        await _databaseService.createPostWithMedia(
          FirebaseAuth.instance.currentUser!.uid,
          FirebaseAuth.instance.currentUser!.email!.split('@')[0],
          _postController.text.trim(),
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          documentUrl: documentUrl,
          documentName: documentName,
        );

        _postController.clear();
        setState(() {
          _imageFiles = [];
          _videoFile = null;
          _documentFile = null;
          _videoController?.dispose();
          _videoController = null;
        });
        Fluttertoast.showToast(msg: '✅ Post shared!');
      } catch (e) {
        Fluttertoast.showToast(msg: '⚠️ Failed to create post: $e');
      }
    } else {
      Fluttertoast.showToast(msg: '⚠️ Please write or attach something!');
    }
  }

  Future<void> _toggleLike(Post post) async {
    final isLiked = _likedPosts.contains(post.id);
    setState(() {
      if (isLiked) {
        _likedPosts.remove(post.id);
      } else {
        _likedPosts.add(post.id);
      }
    });

    // Update the like count in the database
    int newLikeCount = !isLiked ? post.likes + 1 : post.likes - 1;
    await _databaseService.likePost(post.id, newLikeCount);
  }

  Future<void> _sharePost(Post post) async {
    await _databaseService.sharePost(post.id, post.shares + 1);
    // Generate a deep link and fallback web URL for the post
    final deepLink = 'innochat://post/${post.id}';
    final fallbackUrl =
        'https://yourapp.com/post/${post.id}'; // Replace with your actual web URL
    final shareText =
        '${post.content}\n\nView post: $deepLink\nOr visit: $fallbackUrl';
    await Share.share(shareText, subject: 'Check out this post on InnoChat!');
  }

  Future<void> _deletePost(Post post) async {
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
        await _databaseService.deletePost(post.id);
        if (_videoControllers.containsKey(post.id)) {
          await _videoControllers[post.id]?.dispose();
          _videoControllers.remove(post.id);
          _videoPlayingNotifiers[post.id]?.dispose();
          _videoPlayingNotifiers.remove(post.id);
        }
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

  Future<void> _updatePost(Post post) async {
    final controller = TextEditingController(text: post.content);

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
        updatedContent != post.content) {
      try {
        await _databaseService.updatePost(post.id, updatedContent);
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

  Future<bool> _getVerificationStatus(String userId) async {
    return await _databaseService.isUserVerified(userId);
  }

  Widget _buildBlueBadge(String userId) {
    return FutureBuilder<bool>(
      future: _getVerificationStatus(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasData && snapshot.data == true) {
          return Container(
            margin: const EdgeInsets.only(left: 4),
            child: const Icon(
              Icons.verified,
              color: Colors.blue,
              size: 16,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const Center(
                  child: SpinKitFadingCircle(color: Colors.deepPurple)),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 48),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenVideo(
      BuildContext context, VideoPlayerController controller) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: FullScreenVideoPlayer(controller: controller),
      ),
    );
  }

  // Enhanced document opening with in-app viewer
  Future<void> _openDocument(String documentUrl, String documentName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: SpinKitFadingCircle(color: Colors.deepPurple),
        ),
      );

      // Check if it's a PDF document
      if (documentName.toLowerCase().endsWith('.pdf')) {
        // Download and cache the PDF
        final response = await http.get(Uri.parse(documentUrl));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/$documentName');
          await file.writeAsBytes(bytes);

          // Close loading dialog
          Navigator.pop(context);

          // Open PDF viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                filePath: file.path,
                title: documentName,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
          throw Exception('Failed to download PDF');
        }
      } else if (documentName.toLowerCase().endsWith('.txt')) {
        // Handle text files
        final response = await http.get(Uri.parse(documentUrl));
        if (response.statusCode == 200) {
          final content = response.body;
          Navigator.pop(context);

          // Show text content in a dialog
          showDialog(
            context: context,
            builder: (context) => TextDocumentViewer(
              content: content,
              title: documentName,
            ),
          );
        } else {
          Navigator.pop(context);
          throw Exception('Failed to load text file');
        }
      } else {
        // For other document types, fall back to external launch
        Navigator.pop(context);
        final url = Uri.parse(documentUrl);
        final isLaunching = await canLaunchUrl(url);
        if (isLaunching) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Opening document...', style: GoogleFonts.poppins()),
              duration: const Duration(seconds: 2),
            ),
          );
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          Fluttertoast.showToast(msg: '⚠️ Cannot open document: Invalid URL');
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Fluttertoast.showToast(msg: '⚠️ Error opening document: $e');
    }
  }

  Widget _buildEnhancedPostCard(Post post) {
    final user = FirebaseAuth.instance.currentUser!;
    final isLiked = _likedPosts.contains(post.id);
    final isOwnPost = post.userId == user.uid;
    final videoController = _videoControllers[post.id];
    final isPlayingNotifier = _videoPlayingNotifiers[post.id];

    return Container(
      key: ValueKey(post.id), // Ensure stable widget identity
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and menu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                      _buildBlueBadge(post.userId),
                    ],
                  ),
                ),
                if (isOwnPost)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') _deletePost(post);
                      if (value == 'update') _updatePost(post);
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
              ],
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),

          // Media content
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: post.imageUrl!.split(',').length,
                itemBuilder: (context, index) {
                  final imageUrl = post.imageUrl!.split(',')[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const SpinKitFadingCircle(
                                  color: Colors.deepPurple),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (post.videoUrl != null &&
              post.videoUrl!.isNotEmpty &&
              videoController != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    videoController.value.isInitialized
                        ? GestureDetector(
                            onTap: () =>
                                _showFullScreenVideo(context, videoController),
                            child: AspectRatio(
                              aspectRatio: videoController.value.aspectRatio,
                              child: VideoPlayer(videoController),
                            ),
                          )
                        : const Center(
                            child:
                                SpinKitFadingCircle(color: Colors.deepPurple),
                          ),
                    // Enhanced video controls with better UI
                    if (videoController.value.isInitialized &&
                        isPlayingNotifier != null)
                      ValueListenableBuilder<bool>(
                        valueListenable: isPlayingNotifier,
                        builder: (context, isPlaying, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (videoController.value.isPlaying) {
                                    videoController.pause();
                                  } else {
                                    videoController.play();
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              // Show play button when video is not playing
                              if (!isPlaying)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      videoController.value.position ==
                                              videoController.value.duration
                                          ? Icons.replay
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    onPressed: () {
                                      if (videoController.value.position ==
                                          videoController.value.duration) {
                                        videoController.seekTo(Duration.zero);
                                      }
                                      videoController.play();
                                    },
                                  ),
                                ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: VideoProgressIndicator(
                                  videoController,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.deepPurple,
                                    bufferedColor: Colors.grey,
                                    backgroundColor: Colors.white30,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
          // Enhanced document display with preview and better styling
          if (post.documentUrl != null && post.documentUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: InkWell(
                  onTap: () => _openDocument(
                      post.documentUrl!, post.documentName ?? 'Document'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getDocumentColor(post.documentName ?? ''),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getDocumentIcon(post.documentName ?? ''),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.documentName ?? 'Document',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to open',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Post stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
          ),

          const SizedBox(height: 12),

          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like button
                InkWell(
                  onTap: () => _toggleLike(post),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiked ? Colors.deepPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: isLiked ? Colors.white : Colors.deepPurple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Like',
                          style: GoogleFonts.poppins(
                            color: isLiked ? Colors.white : Colors.deepPurple,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Share button
                InkWell(
                  onTap: () => _sharePost(post),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.share,
                          color: Colors.deepPurple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Share',
                          style: GoogleFonts.poppins(
                            color: Colors.deepPurple,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Comment button
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailsScreen(post: post),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          color: Colors.deepPurple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Comment',
                          style: GoogleFonts.poppins(
                            color: Colors.deepPurple,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for document icons and colors
  IconData _getDocumentIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'txt':
        return Colors.grey;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    for (final notifier in _videoPlayingNotifiers.values) {
      notifier.dispose();
    }
    _videoControllers.clear();
    _videoPlayingNotifiers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseAnimationController.value * 0.1),
                  child: const Icon(Icons.chat_bubble_rounded,
                      color: Colors.white),
                );
              },
            ),
            const SizedBox(width: 8),
            Text('InnoChat 💬', style: GoogleFonts.poppins(fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async => await _authService.logout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated Background Icons
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundIconsPainter(
                  icons: _backgroundIcons,
                  animation: _backgroundAnimationController,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Main Content
          Column(
            children: [
              // Post Creation Section with subtle background
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 22,
                              backgroundImage: CachedNetworkImageProvider(
                                'https://via.placeholder.com/150',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade50,
                                    Colors.white,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: TextField(
                                controller: _postController,
                                decoration: InputDecoration(
                                  hintText: 'What\'s on your mind? ✨',
                                  hintStyle: GoogleFonts.poppins(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                maxLines: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.image,
                            label: '🖼️',
                            color: Colors.indigo,
                            onPressed: _pickImages,
                          ),
                          _buildActionButton(
                            icon: Icons.videocam,
                            label: '🎥',
                            color: Colors.red,
                            onPressed: _pickVideo,
                          ),
                          _buildActionButton(
                            icon: Icons.description,
                            label: '📄',
                            color: Colors.green,
                            onPressed: _pickDocument,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: const LinearGradient(
                                colors: [Colors.deepPurple, Colors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Post'),
                              onPressed: _createPost,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_imageFiles!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageFiles!.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_imageFiles![index].path),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (_videoController != null &&
                          _videoController!.value.isInitialized) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullScreenVideo(
                                      context, _videoController!),
                                  child: AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (_videoController!.value.isPlaying) {
                                      _videoController!.pause();
                                    } else {
                                      _videoController!.play();
                                    }
                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                // Enhanced preview video controls
                                if (!_videoController!.value.isPlaying)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _videoController!.value.position ==
                                                _videoController!.value.duration
                                            ? Icons.replay
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: () {
                                        if (_videoController!.value.position ==
                                            _videoController!.value.duration) {
                                          _videoController!
                                              .seekTo(Duration.zero);
                                        }
                                        _videoController!.play();
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: VideoProgressIndicator(
                                    _videoController!,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.deepPurple,
                                      bufferedColor: Colors.grey,
                                      backgroundColor: Colors.white30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_documentFile != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _getDocumentIcon(_documentFile!.name),
                                color: _getDocumentColor(_documentFile!.name),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _documentFile!.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Posts Section with enhanced post cards
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                  ),
                  child: StreamBuilder<List<Post>>(
                    stream: _databaseService.getPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SpinKitFadingCircle(color: Colors.deepPurple),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '📭',
                                style: TextStyle(fontSize: 60),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet. Be the first!',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final post = snapshot.data![index];
                          return _buildEnhancedPostCard(post);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        tooltip: 'Add $label',
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// PDF Viewer Screen
class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int? totalPages = 0;
  int currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([XFile(widget.filePath)]);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                totalPages = pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // PDF controller can be used for additional controls
            },
            onLinkHandler: (String? uri) {
              // Handle link clicks in PDF
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page ?? 0;
              });
            },
          ),
          if (errorMessage.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading PDF',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          if (!isReady && errorMessage.isEmpty)
            const Center(
              child: SpinKitFadingCircle(color: Colors.deepPurple),
            ),
        ],
      ),
      bottomNavigationBar: isReady
          ? Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

// Text Document Viewer Dialog
class TextDocumentViewer extends StatelessWidget {
  final String content;
  final String title;

  const TextDocumentViewer({
    super.key,
    required this.content,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.text_snippet, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // Footer with actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Share.share(content, subject: title);
                    },
                    icon: const Icon(Icons.share),
                    label: Text('Share', style: GoogleFonts.poppins()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Close', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({super.key, required this.controller});

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late ValueNotifier<bool> _isPlayingNotifier;

  @override
  void initState() {
    super.initState();
    _isPlayingNotifier = ValueNotifier<bool>(widget.controller.value.isPlaying);
    widget.controller.addListener(() {
      final isPlaying = widget.controller.value.isPlaying;
      if (_isPlayingNotifier.value != isPlaying) {
        _isPlayingNotifier.value = isPlaying;
      }
    });
  }

  @override
  void dispose() {
    _isPlayingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: VideoPlayer(widget.controller),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isPlayingNotifier,
          builder: (context, isPlaying, child) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.controller.value.isPlaying) {
                      widget.controller.pause();
                    } else {
                      widget.controller.play();
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (!isPlaying &&
                    widget.controller.value.position ==
                        widget.controller.value.duration)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.replay,
                          color: Colors.white,
                          size: 64,
                        ),
                        onPressed: () {
                          widget.controller.seekTo(Duration.zero);
                          widget.controller.play();
                        },
                      ),
                    ),
                  ),
                if (!isPlaying &&
                    widget.controller.value.position !=
                        widget.controller.value.duration)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 64,
                        ),
                        onPressed: () {
                          widget.controller.play();
                        },
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: VideoProgressIndicator(
                    widget.controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.deepPurple,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white30,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class BackgroundIcon {
  final String icon;
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double rotationSpeed;
  final double floatSpeed;

  BackgroundIcon({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.rotationSpeed,
    required this.floatSpeed,
  });
}

class BackgroundIconsPainter extends CustomPainter {
  final List<BackgroundIcon> icons;
  final Animation<double> animation;

  BackgroundIconsPainter({
    required this.icons,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final icon in icons) {
      final animationValue = animation.value;

      // Calculate floating position
      final x = (icon.x * size.width) +
          (sin(animationValue * 2 * pi * icon.floatSpeed) * 20);
      final y = (icon.y * size.height) +
          (cos(animationValue * 2 * pi * icon.floatSpeed) * 15);

      // Calculate rotation
      final rotation = animationValue * 2 * pi * icon.rotationSpeed;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw the emoji/icon
      final textPainter = TextPainter(
        text: TextSpan(
          text: icon.icon,
          style: TextStyle(
            fontSize: icon.size,
            color: Colors.deepPurple.withOpacity(icon.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
