import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined }

class FriendModel {
  final String friendshipId;
  final String userId;
  final String friendId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  FriendModel({
    required this.friendshipId,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  // Factory constructor from Firestore
  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      friendshipId: doc.id,
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendId': friendId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }

  FriendModel copyWith({FriendRequestStatus? status, DateTime? acceptedAt}) {
    return FriendModel(
      friendshipId: friendshipId,
      userId: userId,
      friendId: friendId,
      status: status ?? this.status,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
