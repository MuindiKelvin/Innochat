import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:innochat/models/post.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPost(String userId, String username, String content,
      String? imageUrl, String? videoUrl) async {
    await _firestore.collection('posts').add({
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
    });
  }

  Stream<Post> getPost(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) => Post.fromMap(doc.data()!, doc.id));
  }

  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> likePost(String postId, int currentLikes) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': currentLikes + 1,
    });
  }

  Future<void> sharePost(String postId, int currentShares) async {
    await _firestore.collection('posts').doc(postId).update({
      'shares': currentShares + 1,
    });
  }

  Future<void> addComment(
      String postId, String userId, String username, String content) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.increment(1),
    });
  }

  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> updatePost(String postId, String newContent) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': newContent,
    });
  }
}
