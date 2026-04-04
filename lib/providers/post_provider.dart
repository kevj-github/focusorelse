import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/post_comment_model.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../utils/error_message_mapper.dart';

class PostProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<PostModel>>? _userPostsSubscription;
  String? _loadedUserId;
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadUserPosts(String userId, {bool force = false}) {
    if (!force &&
        _loadedUserId == userId &&
        _userPostsSubscription != null &&
        _errorMessage == null) {
      return;
    }

    _loadedUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _userPostsSubscription?.cancel();
    _userPostsSubscription = _firestoreService
        .streamUserPosts(userId)
        .listen(
          (posts) {
            final sortedPosts = List<PostModel>.from(posts)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            _userPosts = sortedPosts;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _userPosts = [];
            _errorMessage = _mapError(error, fallback: 'Failed to load posts');
            _userPostsSubscription?.cancel();
            _userPostsSubscription = null;
            notifyListeners();
          },
        );
  }

  Future<bool> createPost({
    required String authorId,
    required String authorDisplayName,
    required String? authorUsername,
    required String? authorProfilePictureUrl,
    required String caption,
    required String imageUrl,
  }) async {
    try {
      final locked = await _firestoreService.userHasPendingConsequence(
        authorId,
      );
      if (locked) {
        _errorMessage =
            'Posting is locked until your pending consequence is approved.';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final post = PostModel(
        postId: '',
        authorId: authorId,
        authorDisplayName: authorDisplayName,
        authorUsername: authorUsername,
        authorProfilePictureUrl: authorProfilePictureUrl,
        caption: caption,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createPost(post);

      if (_loadedUserId == authorId || _loadedUserId == null) {
        loadUserPosts(authorId, force: true);
      } else {
        _isLoading = false;
        notifyListeners();
      }

      return true;
    } catch (error) {
      _isLoading = false;
      _errorMessage = _mapError(error, fallback: 'Failed to publish post');
      notifyListeners();
      return false;
    }
  }

  Stream<PostModel?> streamPost(String postId) {
    return _firestoreService.streamPost(postId);
  }

  Stream<bool> streamIsPostLiked({
    required String postId,
    required String userId,
  }) {
    return _firestoreService.streamIsPostLiked(postId: postId, userId: userId);
  }

  Stream<List<PostCommentModel>> streamPostComments(String postId) {
    return _firestoreService.streamPostComments(postId);
  }

  Future<bool> togglePostLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final locked = await _firestoreService.userHasPendingConsequence(userId);
      if (locked) {
        _errorMessage =
            'Likes are locked until your pending consequence is approved.';
        notifyListeners();
        return false;
      }
      await _firestoreService.togglePostLike(postId: postId, userId: userId);
      return true;
    } catch (error) {
      _errorMessage = _mapError(error, fallback: 'Failed to update like');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPostComment({
    required String postId,
    required String authorId,
    required String authorDisplayName,
    String? authorUsername,
    String? authorProfilePictureUrl,
    required String text,
  }) async {
    try {
      final locked = await _firestoreService.userHasPendingConsequence(
        authorId,
      );
      if (locked) {
        _errorMessage =
            'Comments are locked until your pending consequence is approved.';
        notifyListeners();
        return false;
      }
      await _firestoreService.addPostComment(
        postId: postId,
        authorId: authorId,
        authorDisplayName: authorDisplayName,
        authorUsername: authorUsername,
        authorProfilePictureUrl: authorProfilePictureUrl,
        text: text,
      );
      return true;
    } catch (error) {
      _errorMessage = _mapError(error, fallback: 'Failed to add comment');
      notifyListeners();
      return false;
    }
  }

  String _mapError(Object error, {required String fallback}) {
    return ErrorMessageMapper.map(error, fallback: fallback);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userPostsSubscription?.cancel();
    _loadedUserId = null;
    super.dispose();
  }
}
