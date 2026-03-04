import 'package:cloud_firestore/cloud_firestore.dart';

class PostCommentModel {
  final String commentId;
  final String postId;
  final String authorId;
  final String authorDisplayName;
  final String? authorUsername;
  final String? authorProfilePictureUrl;
  final String text;
  final DateTime createdAt;

  PostCommentModel({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorDisplayName,
    this.authorUsername,
    this.authorProfilePictureUrl,
    required this.text,
    required this.createdAt,
  });

  factory PostCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostCommentModel(
      commentId: doc.id,
      postId: (data['postId'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      authorDisplayName: (data['authorDisplayName'] ?? 'Unknown').toString(),
      authorUsername: data['authorUsername']?.toString(),
      authorProfilePictureUrl: data['authorProfilePictureUrl']?.toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorDisplayName': authorDisplayName,
      'authorUsername': authorUsername,
      'authorProfilePictureUrl': authorProfilePictureUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
