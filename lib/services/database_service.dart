import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:innochat/models/post.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get single post stream
  Stream<Post> getPost(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) => Post.fromMap(doc.data()!, doc.id));
  }

  // Get all posts stream
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Like post
  Future<void> likePost(String postId, int newLikeCount) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': newLikeCount,
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // Share post
  Future<void> sharePost(String postId, int newShareCount) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'shares': newShareCount,
      });
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      // First, delete all comments
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the post
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Update post
  Future<void> updatePost(String postId, String newContent) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // Upload multiple images
  Future<String> uploadImages(List<XFile> images) async {
    try {
      List<String> imageUrls = [];

      for (int i = 0; i < images.length; i++) {
        final String fileName =
            'images/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Reference ref = _storage.ref().child(fileName);

        if (kIsWeb) {
          // For web
          final bytes = await images[i].readAsBytes();
          await ref.putData(bytes);
        } else {
          // For mobile
          final file = File(images[i].path);
          await ref.putFile(file);
        }

        final String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls.join(','); // Store as comma-separated string
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Upload single video
  Future<String> uploadVideo(XFile video) async {
    try {
      final String fileName =
          'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final Reference ref = _storage.ref().child(fileName);

      if (kIsWeb) {
        final bytes = await video.readAsBytes();
        await ref.putData(bytes);
      } else {
        final file = File(video.path);
        await ref.putFile(file);
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  // Upload document
  Future<String> uploadDocument(PlatformFile document) async {
    try {
      final String fileName =
          'documents/${DateTime.now().millisecondsSinceEpoch}_${document.name}';
      final Reference ref = _storage.ref().child(fileName);

      if (kIsWeb) {
        if (document.bytes != null) {
          await ref.putData(document.bytes!);
        } else {
          throw Exception('Document bytes are null');
        }
      } else {
        if (document.path != null) {
          final file = File(document.path!);
          await ref.putFile(file);
        } else {
          throw Exception('Document path is null');
        }
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Enhanced add comment method with media support
  Future<void> addCommentWithMedia(
    String postId,
    String userId,
    String username,
    String content, {
    String? imageUrl,
    String? videoUrl,
    String? documentUrl,
    String? documentName,
  }) async {
    try {
      final comment = {
        'userId': userId,
        'username': username,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'documentUrl': documentUrl,
        'documentName': documentName,
      };

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(comment);

      // Update comment count
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Create post with media support
  Future<void> createPostWithMedia(
    String userId,
    String username,
    String content, {
    String? imageUrl,
    String? videoUrl,
    String? documentUrl,
    String? documentName,
  }) async {
    try {
      final post = {
        'userId': userId,
        'username': username,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'documentUrl': documentUrl,
        'documentName': documentName,
      };

      await _firestore.collection('posts').add(post);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Basic create post method (backward compatibility)
  Future<void> createPost(
      String userId, String username, String content) async {
    await createPostWithMedia(userId, username, content);
  }

  // Get user verification status (for blue badge)
  Future<bool> isUserVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['isVerified'] ?? true; // Default to true for all users
    } catch (e) {
      return true; // Default to verified
    }
  }

  // Set user verification status
  Future<void> setUserVerification(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
      });
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }

  // Enhanced get comments method
  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Delete comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update comment count
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get file download URL
  Future<String> getFileDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Add comment (simple version for backward compatibility)
  Future<void> addComment(
      String postId, String userId, String username, String content) async {
    await addCommentWithMedia(postId, userId, username, content);
  }

  // Get user posts
  Stream<List<Post>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Search posts
  Stream<List<Post>> searchPosts(String query) {
    return _firestore
        .collection('posts')
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get trending posts (most liked)
  Stream<List<Post>> getTrendingPosts() {
    return _firestore
        .collection('posts')
        .orderBy('likes', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create or update user profile
  Future<void> createUserProfile(
      String userId, String username, String email) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
