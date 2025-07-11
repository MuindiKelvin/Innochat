import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:innochat/models/post.dart';
import 'package:innochat/screens/post_details_screen.dart';
import 'package:innochat/services/auth_service.dart';
import 'package:innochat/services/database_service.dart';
import 'package:innochat/widgets/post_card.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  XFile? _imageFile;
  VideoPlayerController? _videoController;

  // Animation controllers for background icons
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;
  late List<BackgroundIcon> _backgroundIcons;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateBackgroundIcons();
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

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() => _imageFile = image);
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _videoController = VideoPlayerController.file(File(video.path))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.isNotEmpty ||
        _imageFile != null ||
        _videoController != null) {
      await _databaseService.createPost(
        FirebaseAuth.instance.currentUser!.uid,
        FirebaseAuth.instance.currentUser!.email!.split('@')[0],
        _postController.text.trim(),
        _imageFile?.path,
        _videoController?.dataSource,
      );
      _postController.clear();
      setState(() {
        _imageFile = null;
        _videoController?.dispose();
        _videoController = null;
      });
      Fluttertoast.showToast(msg: '✅ Post shared!');
    } else {
      Fluttertoast.showToast(msg: '⚠️ Please write or attach something!');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
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
                            onPressed: _pickImage,
                          ),
                          _buildActionButton(
                            icon: Icons.videocam,
                            label: '🎥',
                            color: Colors.red,
                            onPressed: _pickVideo,
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
                      if (_imageFile != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_imageFile!.path),
                            height: 120,
                            fit: BoxFit.cover,
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
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Posts Section with transparent background
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
                              Text(
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
                          return PostCard(
                            post: post,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailsScreen(post: post),
                              ),
                            ),
                          );
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
