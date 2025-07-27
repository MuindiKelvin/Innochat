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

  // Stream: Get a single post
  Stream<Post> getPost(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) => Post.fromMap(doc.data()!, doc.id));
  }

  // Stream: Get all posts
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Like a post
  Future<void> likePost(String postId, int newLikeCount) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': newLikeCount,
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // Share a post
  Future<void> sharePost(String postId, int newShareCount) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'shares': newShareCount,
      });
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  // Delete a post and its comments
  Future<void> deletePost(String postId) async {
    try {
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Update a post
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
        final fileName =
            'images/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child(fileName);

        if (kIsWeb) {
          final bytes = await images[i].readAsBytes();
          await ref.putData(bytes);
        } else {
          final file = File(images[i].path);
          await ref.putFile(file);
        }

        final downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls.join(',');
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Upload a single video
  Future<String> uploadVideo(XFile video) async {
    try {
      final fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child(fileName);

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

  // Upload a document
  Future<String> uploadDocument(PlatformFile document) async {
    try {
      final fileName =
          'documents/${DateTime.now().millisecondsSinceEpoch}_${document.name}';
      final ref = _storage.ref().child(fileName);

      if (kIsWeb && document.bytes != null) {
        await ref.putData(document.bytes!);
      } else if (document.path != null) {
        final file = File(document.path!);
        await ref.putFile(file);
      } else {
        throw Exception('Invalid document data');
      }

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Add a comment with optional media
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

      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Create a post with optional media
  Future<void> createPostWithMedia(
    String userId,
    String username,
    String content, {
    String? imageUrl,
    String? videoUrl,
    String? documentUrl,
    String? documentName,
    String? documentHash,
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
        'documentHash': documentHash,
      };

      await _firestore.collection('posts').add(post);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Create a post (basic fallback)
  Future<void> createPost(
      String userId, String username, String content) async {
    await createPostWithMedia(userId, username, content);
  }

  // Stream: Get comments for a post
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

  // Fetch comments once (no stream)
  Future<List<Map<String, dynamic>>> getCommentsOnce(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  // Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get a file's download URL
  Future<String> getFileDownloadUrl(String filePath) async {
    try {
      final ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Delete a file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Add a comment (simple fallback)
  Future<void> addComment(
      String postId, String userId, String username, String content) async {
    await addCommentWithMedia(postId, userId, username, content);
  }

  // Stream: Get posts for a specific user
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

  // Stream: Search posts by content
  Stream<List<Post>> searchPosts(String query) {
    return _firestore
        .collection('posts')
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream: Get trending posts
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

  // Create a user profile
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

  // Fetch a user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update a user profile
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get verification status of a user
  Future<bool> isUserVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['isVerified'] ?? true;
    } catch (e) {
      return true;
    }
  }

  // Set verification status
  Future<void> setUserVerification(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
      });
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }
}
