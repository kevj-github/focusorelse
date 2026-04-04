import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/storage_service.dart';

class ErrorMessageMapper {
  static String map(Object error, {required String fallback}) {
    if (error is FirebaseAuthException) {
      return _mapAuthError(error, fallback: fallback);
    }

    if (error is FirebaseException) {
      return _mapFirestoreError(error, fallback: fallback);
    }

    if (error is StorageServiceException) {
      return _mapStorageError(error, fallback: fallback);
    }

    final text = error.toString().trim();
    final mapped = _mapKnownCode(text);
    if (mapped != null) {
      return mapped;
    }

    return fallback;
  }

  static String _mapAuthError(
    FirebaseAuthException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account was found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'operation-not-allowed':
        return 'That sign-in method is not available right now.';
      case 'account-exists-with-different-credential':
        return 'That email is already linked to a different sign-in method.';
      case 'google-sign-in-failed':
        return 'Google sign-in failed. Check your device and try again.';
      case 'google-sign-in-unknown':
        return 'Google sign-in failed unexpectedly. Try again.';
      default:
        return fallback;
    }
  }

  static String _mapFirestoreError(
    FirebaseException error, {
    required String fallback,
  }) {
    final codeMessage = _mapKnownCode(error.code);
    if (codeMessage != null) {
      return codeMessage;
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!.trim();
    }

    return fallback;
  }

  static String _mapStorageError(
    StorageServiceException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'config-missing':
        return 'Image uploads are not configured yet.';
      case 'upload-failed':
        return 'Upload failed. Please try again.';
      case 'invalid-response':
        return 'Upload service returned an invalid response.';
      case 'missing-url':
        return 'Upload completed, but no file URL was returned.';
      case 'not-supported':
        return 'That action is not supported.';
      case 'invalid-url':
        return 'The file link is not valid.';
      default:
        return error.message.trim().isNotEmpty
            ? error.message.trim()
            : fallback;
    }
  }

  static String? _mapKnownCode(String raw) {
    final normalized = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^FirebaseException\([^)]*\):\s*'), '')
        .replaceFirst(RegExp(r'^StorageServiceException\([^)]*\):\s*'), '')
        .trim();

    switch (normalized) {
      case 'USERNAME_TAKEN':
        return 'That username is already taken.';
      case 'USER_NOT_FOUND':
        return 'The selected user could not be found.';
      case 'ALREADY_FRIENDS':
        return 'You are already friends.';
      case 'REQUEST_PENDING':
        return 'A friend request is already pending.';
      case 'CANNOT_ADD_SELF':
        return 'You cannot add yourself.';
      case 'FRIEND_REQUEST_NOT_FOUND':
        return 'That friend request could not be found.';
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'not-found':
        return 'The item could not be found.';
      case 'already-exists':
        return 'That item already exists.';
      case 'unavailable':
        return 'The service is temporarily unavailable. Try again later.';
      case 'deadline-exceeded':
        return 'The request took too long. Try again.';
      case 'aborted':
        return 'The request was interrupted. Please try again.';
      case 'unauthenticated':
        return 'Please sign in again.';
      case 'invalid-argument':
        return 'One or more values are not valid.';
      default:
        return null;
    }
  }
}
