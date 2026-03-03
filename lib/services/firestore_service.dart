import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/pact_model.dart';
import '../models/friend_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _db.collection('users');
  CollectionReference get _pactsCollection => _db.collection('pacts');
  CollectionReference get _friendsCollection => _db.collection('friends');

  // USER OPERATIONS

  // Create user
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.userId).set(user.toFirestore());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.userId).update(user.toFirestore());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Stream user
  Stream<UserModel?> streamUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Search users by username
  Future<List<UserModel>> searchUsersByUsername(String username) async {
    try {
      final querySnapshot = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: username)
          .where('username', isLessThanOrEqualTo: '$username\uf8ff')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  // PACT OPERATIONS

  // Create pact
  Future<String> createPact(PactModel pact) async {
    try {
      final docRef = await _pactsCollection.add(pact.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating pact: $e');
      rethrow;
    }
  }

  // Check if pact exists by ID
  Future<bool> pactExists(String pactId) async {
    try {
      final doc = await _pactsCollection.doc(pactId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking pact existence: $e');
      rethrow;
    }
  }

  // Get pact by ID
  Future<PactModel?> getPact(String pactId) async {
    try {
      final doc = await _pactsCollection.doc(pactId).get();
      if (doc.exists) {
        return PactModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting pact: $e');
      rethrow;
    }
  }

  // Update pact
  Future<void> updatePact(PactModel pact) async {
    try {
      await _pactsCollection.doc(pact.pactId).update(pact.toFirestore());
    } catch (e) {
      print('Error updating pact: $e');
      rethrow;
    }
  }

  // Delete pact
  Future<void> deletePact(String pactId) async {
    try {
      await _pactsCollection.doc(pactId).delete();
    } catch (e) {
      print('Error deleting pact: $e');
      rethrow;
    }
  }

  // Get user's pacts
  Stream<List<PactModel>> streamUserPacts(String userId, {PactStatus? status}) {
    Query query = _pactsCollection.where('userId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query
        .orderBy('deadline', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PactModel.fromFirestore(doc)).toList(),
        );
  }

  // Get user's expired pacts (completed + failed)
  Stream<List<PactModel>> streamUserExpiredPacts(String userId) {
    return _pactsCollection
        .where('userId', isEqualTo: userId)
        .where(
          'status',
          whereIn: [PactStatus.completed.name, PactStatus.failed.name],
        )
        .orderBy('deadline', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PactModel.fromFirestore(doc)).toList(),
        );
  }

  // Get pacts requiring verification by user
  Stream<List<PactModel>> streamPactsToVerify(String userId) {
    return _pactsCollection
        .where('verifierId', isEqualTo: userId)
        .where('status', isEqualTo: PactStatus.verificationPending.name)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PactModel.fromFirestore(doc)).toList(),
        );
  }

  // FRIEND OPERATIONS

  // Send friend request
  Future<String> sendFriendRequest(String userId, String friendId) async {
    try {
      final friendRequest = FriendModel(
        friendshipId: '',
        userId: userId,
        friendId: friendId,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _friendsCollection.add(friendRequest.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      await _friendsCollection.doc(friendshipId).update({
        'status': FriendRequestStatus.accepted.name,
        'acceptedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Decline friend request
  Future<void> declineFriendRequest(String friendshipId) async {
    try {
      await _friendsCollection.doc(friendshipId).update({
        'status': FriendRequestStatus.declined.name,
      });
    } catch (e) {
      print('Error declining friend request: $e');
      rethrow;
    }
  }

  // Remove friend
  Future<void> removeFriend(String friendshipId) async {
    try {
      await _friendsCollection.doc(friendshipId).delete();
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  // Get user's friends
  Stream<List<FriendModel>> streamUserFriends(String userId) {
    return _friendsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get pending friend requests (received)
  Stream<List<FriendModel>> streamPendingFriendRequests(String userId) {
    return _friendsCollection
        .where('friendId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Check if friendship exists
  Future<bool> checkFriendshipExists(String userId, String friendId) async {
    try {
      final query = await _friendsCollection
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: friendId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking friendship: $e');
      rethrow;
    }
  }

  // Get accepted friend user IDs for a user (both outgoing and incoming)
  Future<List<String>> getAcceptedFriendUserIds(String userId) async {
    try {
      final outgoingQuery = await _friendsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: FriendRequestStatus.accepted.name)
          .get();

      final incomingQuery = await _friendsCollection
          .where('friendId', isEqualTo: userId)
          .where('status', isEqualTo: FriendRequestStatus.accepted.name)
          .get();

      final friendIds = <String>{};

      for (final doc in outgoingQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final friendId = (data['friendId'] ?? '').toString();
        if (friendId.isNotEmpty && friendId != userId) {
          friendIds.add(friendId);
        }
      }

      for (final doc in incomingQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final requesterId = (data['userId'] ?? '').toString();
        if (requesterId.isNotEmpty && requesterId != userId) {
          friendIds.add(requesterId);
        }
      }

      return friendIds.toList()..sort();
    } catch (e) {
      print('Error getting accepted friend IDs: $e');
      rethrow;
    }
  }
}
