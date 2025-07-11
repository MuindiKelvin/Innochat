class Post {
  final String id;
  final String userId;
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final int shares;
  final String? imageUrl;
  final String? videoUrl;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.imageUrl,
    this.videoUrl,
  });

  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      userId: data['userId'],
      username: data['username'],
      content: data['content'],
      timestamp: data['timestamp'].toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
    };
  }
}
