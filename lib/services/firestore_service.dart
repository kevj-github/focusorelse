import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/pact_model.dart';
import '../models/friend_model.dart';
import '../models/post_model.dart';
import '../models/post_comment_model.dart';
import '../models/chat_message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _db.collection('users');
  CollectionReference get _usernamesCollection => _db.collection('usernames');
  CollectionReference get _pactsCollection => _db.collection('pacts');
  CollectionReference get _friendsCollection => _db.collection('friends');
  CollectionReference get _postsCollection => _db.collection('posts');
  CollectionReference get _chatsCollection => _db.collection('chats');

  String normalizeUsername(String value) {
    final lower = value.trim().toLowerCase();
    final withoutPrefix = lower.startsWith('@') ? lower.substring(1) : lower;
    final cleaned = withoutPrefix.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return cleaned;
  }

  Future<bool> isUsernameAvailable(
    String username, {
    String? excludeUserId,
  }) async {
    final normalized = normalizeUsername(username);
    if (normalized.isEmpty) {
      return false;
    }

    final doc = await _usernamesCollection.doc(normalized).get();
    if (!doc.exists) {
      return true;
    }

    final data = doc.data() as Map<String, dynamic>?;
    final ownerUserId = (data?['userId'] ?? '').toString();
    return excludeUserId != null && ownerUserId == excludeUserId;
  }

  Future<String> generateUniqueUsername(
    String seed, {
    String? excludeUserId,
  }) async {
    final normalizedSeed = normalizeUsername(seed);
    final base = normalizedSeed.isEmpty ? 'focususer' : normalizedSeed;

    if (await isUsernameAvailable(base, excludeUserId: excludeUserId)) {
      return base;
    }

    var counter = 1;
    while (true) {
      final candidate = '$base$counter';
      if (await isUsernameAvailable(candidate, excludeUserId: excludeUserId)) {
        return candidate;
      }
      counter += 1;
    }
  }

  // USER OPERATIONS

  // Create user
  Future<void> createUser(UserModel user) async {
    try {
      final normalizedUsername = normalizeUsername(user.username ?? '');

      await _db.runTransaction((transaction) async {
        final userRef = _usersCollection.doc(user.userId);

        if (normalizedUsername.isNotEmpty) {
          final usernameRef = _usernamesCollection.doc(normalizedUsername);
          final usernameSnapshot = await transaction.get(usernameRef);
          if (usernameSnapshot.exists) {
            throw Exception('USERNAME_TAKEN');
          }

          transaction.set(usernameRef, {
            'userId': user.userId,
            'username': normalizedUsername,
            'createdAt': Timestamp.now(),
          });
        }

        final sanitizedUser = user.copyWith(
          username: normalizedUsername.isEmpty ? null : normalizedUsername,
        );
        transaction.set(userRef, sanitizedUser.toFirestore());
      });
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
      final normalizedUsername = normalizeUsername(user.username ?? '');

      await _db.runTransaction((transaction) async {
        final userRef = _usersCollection.doc(user.userId);
        final existingUserSnapshot = await transaction.get(userRef);

        if (!existingUserSnapshot.exists) {
          throw Exception('USER_NOT_FOUND');
        }

        final existingData =
            existingUserSnapshot.data() as Map<String, dynamic>? ?? {};
        final existingUsername = normalizeUsername(
          (existingData['username'] ?? '').toString(),
        );

        if (normalizedUsername != existingUsername) {
          if (normalizedUsername.isNotEmpty) {
            final newUsernameRef = _usernamesCollection.doc(normalizedUsername);
            final newUsernameSnapshot = await transaction.get(newUsernameRef);
            if (newUsernameSnapshot.exists) {
              final ownerData =
                  newUsernameSnapshot.data() as Map<String, dynamic>? ?? {};
              final ownerId = (ownerData['userId'] ?? '').toString();
              if (ownerId != user.userId) {
                throw Exception('USERNAME_TAKEN');
              }
            }

            transaction.set(newUsernameRef, {
              'userId': user.userId,
              'username': normalizedUsername,
              'createdAt': Timestamp.now(),
            });
          }

          if (existingUsername.isNotEmpty) {
            transaction.delete(_usernamesCollection.doc(existingUsername));
          }
        }

        final sanitizedUser = user.copyWith(
          username: normalizedUsername.isEmpty ? null : normalizedUsername,
        );
        transaction.set(userRef, sanitizedUser.toFirestore());
      });

      final authoredPosts = await _postsCollection
          .where('authorId', isEqualTo: user.userId)
          .get();

      if (authoredPosts.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in authoredPosts.docs) {
          batch.update(doc.reference, {
            'authorDisplayName': user.displayName ?? user.username ?? 'Unknown',
            'authorUsername': normalizeUsername(user.username ?? ''),
            'authorProfilePictureUrl': user.profilePictureUrl,
          });
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _db.runTransaction((transaction) async {
        final userRef = _usersCollection.doc(userId);
        final userSnapshot = await transaction.get(userRef);
        if (userSnapshot.exists) {
          final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
          final existingUsername = normalizeUsername(
            (userData['username'] ?? '').toString(),
          );
          if (existingUsername.isNotEmpty) {
            transaction.delete(_usernamesCollection.doc(existingUsername));
          }
        }
        transaction.delete(userRef);
      });
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
  Future<List<UserModel>> searchUsersByUsername(
    String username, {
    String? excludeUserId,
  }) async {
    try {
      final normalizedQuery = normalizeUsername(username);
      if (normalizedQuery.isEmpty) {
        return [];
      }

      final querySnapshot = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: normalizedQuery)
          .where('username', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
          .limit(20)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      if (excludeUserId == null || excludeUserId.isEmpty) {
        return users;
      }

      return users.where((user) => user.userId != excludeUserId).toList();
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

  // Stream pact by ID
  Stream<PactModel?> streamPact(String pactId) {
    return _pactsCollection.doc(pactId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      return PactModel.fromFirestore(doc);
    });
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
      if (userId == friendId) {
        throw Exception('CANNOT_ADD_SELF');
      }

      final relation = await getFriendRelationStatus(userId, friendId);
      if (relation == FriendRelationStatus.friends) {
        throw Exception('ALREADY_FRIENDS');
      }
      if (relation == FriendRelationStatus.requestPending) {
        throw Exception('REQUEST_PENDING');
      }

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
      await _db.runTransaction((transaction) async {
        final friendshipRef = _friendsCollection.doc(friendshipId);
        final friendshipSnapshot = await transaction.get(friendshipRef);
        if (!friendshipSnapshot.exists) {
          throw Exception('FRIEND_REQUEST_NOT_FOUND');
        }

        final friendshipData =
            friendshipSnapshot.data() as Map<String, dynamic>? ?? {};
        final requesterId = (friendshipData['userId'] ?? '').toString();
        final receiverId = (friendshipData['friendId'] ?? '').toString();

        transaction.update(friendshipRef, {
          'status': FriendRequestStatus.accepted.name,
          'acceptedAt': Timestamp.now(),
        });

        if (requesterId.isNotEmpty && receiverId.isNotEmpty) {
          transaction.update(_usersCollection.doc(requesterId), {
            'friendIds': FieldValue.arrayUnion([receiverId]),
          });
          transaction.update(_usersCollection.doc(receiverId), {
            'friendIds': FieldValue.arrayUnion([requesterId]),
          });
        }
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
      await _db.runTransaction((transaction) async {
        final friendshipRef = _friendsCollection.doc(friendshipId);
        final friendshipSnapshot = await transaction.get(friendshipRef);
        if (!friendshipSnapshot.exists) {
          return;
        }

        final friendshipData =
            friendshipSnapshot.data() as Map<String, dynamic>? ?? {};
        final requesterId = (friendshipData['userId'] ?? '').toString();
        final receiverId = (friendshipData['friendId'] ?? '').toString();

        if (requesterId.isNotEmpty && receiverId.isNotEmpty) {
          transaction.update(_usersCollection.doc(requesterId), {
            'friendIds': FieldValue.arrayRemove([receiverId]),
          });
          transaction.update(_usersCollection.doc(receiverId), {
            'friendIds': FieldValue.arrayRemove([requesterId]),
          });
        }

        transaction.delete(friendshipRef);
      });
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

  Future<FriendRelationStatus> getFriendRelationStatus(
    String userId,
    String otherUserId,
  ) async {
    try {
      final outgoing = await _friendsCollection
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: otherUserId)
          .where(
            'status',
            whereIn: [
              FriendRequestStatus.pending.name,
              FriendRequestStatus.accepted.name,
            ],
          )
          .limit(1)
          .get();

      if (outgoing.docs.isNotEmpty) {
        final data = outgoing.docs.first.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString();
        if (status == FriendRequestStatus.accepted.name) {
          return FriendRelationStatus.friends;
        }
        return FriendRelationStatus.requestPending;
      }

      final incoming = await _friendsCollection
          .where('userId', isEqualTo: otherUserId)
          .where('friendId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              FriendRequestStatus.pending.name,
              FriendRequestStatus.accepted.name,
            ],
          )
          .limit(1)
          .get();

      if (incoming.docs.isNotEmpty) {
        final data = incoming.docs.first.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString();
        if (status == FriendRequestStatus.accepted.name) {
          return FriendRelationStatus.friends;
        }
        return FriendRelationStatus.requestPending;
      }

      return FriendRelationStatus.none;
    } catch (e) {
      print('Error getting friend relation status: $e');
      rethrow;
    }
  }

  Future<String?> getFriendshipIdBetween(
    String userId,
    String otherUserId,
  ) async {
    try {
      final outgoing = await _friendsCollection
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: otherUserId)
          .where('status', isEqualTo: FriendRequestStatus.accepted.name)
          .limit(1)
          .get();

      if (outgoing.docs.isNotEmpty) {
        return outgoing.docs.first.id;
      }

      final incoming = await _friendsCollection
          .where('userId', isEqualTo: otherUserId)
          .where('friendId', isEqualTo: userId)
          .where('status', isEqualTo: FriendRequestStatus.accepted.name)
          .limit(1)
          .get();

      if (incoming.docs.isNotEmpty) {
        return incoming.docs.first.id;
      }

      return null;
    } catch (e) {
      print('Error getting friendship ID: $e');
      rethrow;
    }
  }

  // POST OPERATIONS

  Future<String> createPost(PostModel post) async {
    try {
      final docRef = await _postsCollection.add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  Stream<List<PostModel>> streamUserPosts(String userId) {
    return _postsCollection
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<PostModel>> streamPostsByAuthorIds(List<String> authorIds) {
    if (authorIds.isEmpty) {
      return Stream.value([]);
    }

    final limitedIds = authorIds.take(10).toList();

    return _postsCollection
        .where('authorId', whereIn: limitedIds)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<PostModel?> streamPost(String postId) {
    return _postsCollection.doc(postId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return PostModel.fromFirestore(doc);
    });
  }

  Future<void> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    final postRef = _postsCollection.doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _db.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);

      if (likeDoc.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        transaction.set(likeRef, {
          'userId': userId,
          'createdAt': Timestamp.now(),
        });
        transaction.update(postRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  Stream<bool> streamIsPostLiked({
    required String postId,
    required String userId,
  }) {
    return _postsCollection
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<PostCommentModel>> streamPostComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostCommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addPostComment({
    required String postId,
    required String authorId,
    required String authorDisplayName,
    String? authorUsername,
    String? authorProfilePictureUrl,
    required String text,
  }) async {
    final postRef = _postsCollection.doc(postId);
    final commentRef = postRef.collection('comments').doc();
    final comment = PostCommentModel(
      commentId: commentRef.id,
      postId: postId,
      authorId: authorId,
      authorDisplayName: authorDisplayName,
      authorUsername: authorUsername,
      authorProfilePictureUrl: authorProfilePictureUrl,
      text: text,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(commentRef, comment.toFirestore());
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
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

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }

    final uniqueIds = userIds.toSet().toList();
    final users = <UserModel>[];

    for (var i = 0; i < uniqueIds.length; i += 10) {
      final end = (i + 10 < uniqueIds.length) ? i + 10 : uniqueIds.length;
      final chunk = uniqueIds.sublist(i, end);
      final query = await _usersCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(query.docs.map((doc) => UserModel.fromFirestore(doc)));
    }

    return users;
  }

  Stream<List<PactModel>> streamPactsForVerifier(String verifierId) {
    return _pactsCollection
        .where('verifierId', isEqualTo: verifierId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PactModel.fromFirestore(doc)).toList(),
        );
  }

  // CHAT OPERATIONS

  String getChatId(String userIdA, String userIdB) {
    final sorted = [userIdA, userIdB]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Stream<List<ChatMessageModel>> streamChatMessages({
    required String currentUserId,
    required String friendUserId,
  }) {
    final chatId = getChatId(currentUserId, friendUserId);
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<int> streamUnreadMessageCount({
    required String currentUserId,
    required String friendUserId,
  }) {
    final chatId = getChatId(currentUserId, friendUserId);
    return _chatsCollection.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) {
        return 0;
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final unreadCounts = data['unreadCounts'] as Map<String, dynamic>?;
      if (unreadCounts == null) {
        return 0;
      }

      final rawCount = unreadCounts[currentUserId];
      if (rawCount is int) {
        return rawCount;
      }
      if (rawCount is num) {
        return rawCount.toInt();
      }
      return 0;
    });
  }

  Stream<DateTime?> streamLastMessageAt({
    required String currentUserId,
    required String friendUserId,
  }) {
    final chatId = getChatId(currentUserId, friendUserId);

    return _chatsCollection.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final timestamp = data['lastMessageAt'] as Timestamp?;
      return timestamp?.toDate();
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final chatId = getChatId(senderId, recipientId);
    final chatRef = _chatsCollection.doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final now = Timestamp.now();

    await _db.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);

      if (!chatSnapshot.exists) {
        transaction.set(chatRef, {
          'participants': [senderId, recipientId],
          'createdAt': now,
          'updatedAt': now,
          'lastMessage': trimmed,
          'lastMessageAt': now,
          'lastSenderId': senderId,
          'unreadCounts': {senderId: 0, recipientId: 1},
        });
      } else {
        transaction.update(chatRef, {
          'participants': [senderId, recipientId],
          'updatedAt': now,
          'lastMessage': trimmed,
          'lastMessageAt': now,
          'lastSenderId': senderId,
          'unreadCounts.$senderId': 0,
          'unreadCounts.$recipientId': FieldValue.increment(1),
        });
      }

      final message = ChatMessageModel(
        messageId: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        recipientId: recipientId,
        text: trimmed,
        createdAt: DateTime.now(),
        readBy: [senderId],
      );

      transaction.set(messageRef, message.toFirestore());
    });
  }

  Future<void> markConversationAsRead({
    required String currentUserId,
    required String friendUserId,
  }) async {
    final chatId = getChatId(currentUserId, friendUserId);
    final chatRef = _chatsCollection.doc(chatId);

    final recentMessages = await chatRef
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    final batch = _db.batch();

    for (final doc in recentMessages.docs) {
      final data = doc.data();
      final recipientId = (data['recipientId'] ?? '').toString();
      final readBy = List<String>.from(data['readBy'] ?? const <String>[]);

      if (recipientId == currentUserId && !readBy.contains(currentUserId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }

    batch.set(chatRef, {
      'participants': [currentUserId, friendUserId],
      'updatedAt': Timestamp.now(),
      'unreadCounts.$currentUserId': 0,
    }, SetOptions(merge: true));

    await batch.commit();
  }
}

enum FriendRelationStatus { none, requestPending, friends }
