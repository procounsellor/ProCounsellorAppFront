class Comment {
  final String author;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.author,
    required this.content,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      author: json['author'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Post {
  final String postId;
  final String communityId;
  final String author;
  final String type; // 'text' or 'media'
  final String content; // for text posts
  final String? mediaUrl; // for media posts
  final String? caption;
  final DateTime timestamp;
  final List<Comment> comments;

  Post({
    required this.postId,
    required this.communityId,
    required this.author,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.caption,
    required this.timestamp,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'],
      communityId: json['communityId'],
      author: json['author'],
      type: json['type'],
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      caption: json['caption'],
      timestamp: DateTime.parse(json['timestamp']),
      comments: (json['comments'] as List<dynamic>)
          .map((c) => Comment.fromJson(c))
          .toList(),
    );
  }
}
