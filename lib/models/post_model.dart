import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String authorId;
  final String authorDisplayName;
  final String? authorUsername;
  final String? authorProfilePictureUrl;
  final String caption;
  final String imageUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorDisplayName,
    this.authorUsername,
    this.authorProfilePictureUrl,
    required this.caption,
    required this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
      postId: doc.id,
      authorId: data['authorId'] ?? '',
      authorDisplayName: data['authorDisplayName'] ?? 'Unknown',
      authorUsername: data['authorUsername'],
      authorProfilePictureUrl: data['authorProfilePictureUrl'],
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: (data['likeCount'] ?? 0) as int,
      commentCount: (data['commentCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorDisplayName': authorDisplayName,
      'authorUsername': authorUsername,
      'authorProfilePictureUrl': authorProfilePictureUrl,
      'caption': caption,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }

  PostModel copyWith({
    String? postId,
    String? authorId,
    String? authorDisplayName,
    String? authorUsername,
    String? authorProfilePictureUrl,
    String? caption,
    String? imageUrl,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorProfilePictureUrl:
          authorProfilePictureUrl ?? this.authorProfilePictureUrl,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}
