import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:innochat/models/post.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(
                        'https://via.placeholder.com/150', // Placeholder profile image
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.username,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (post.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                if (post.videoUrl != null)
                  const SizedBox(
                    height: 200,
                    child:
                        Placeholder(), // Replace with VideoPlayer if videoUrl is a valid path
                  ),
                Text(post.content),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thumb_up,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post.likes}'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.comment, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post.comments}'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.share, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${post.shares}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
