import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Create or update user in Firestore
      // Don't let Firestore errors prevent successful authentication
      if (userCredential.user != null) {
        try {
          await _createOrUpdateUser(userCredential.user!);
        } catch (firestoreError) {
          print(
            'Warning: Firestore operation failed, but user is authenticated: $firestoreError',
          );
          // Continue - user is still authenticated in Firebase Auth
        }
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Update last login time
      // Don't let Firestore errors prevent successful authentication
      if (userCredential.user != null) {
        try {
          await _createOrUpdateUser(userCredential.user!);
        } catch (firestoreError) {
          print(
            'Warning: Firestore operation failed, but user is authenticated: $firestoreError',
          );
          // Continue - user is still authenticated in Firebase Auth
        }
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
    String username,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      // Don't let Firestore errors prevent successful authentication
      if (userCredential.user != null) {
        try {
          await reserveUsernameForNewUser(
            userId: userCredential.user!.uid,
            email: userCredential.user!.email ?? email,
            username: username,
            displayName: displayName,
          );
        } catch (firestoreError) {
          print(
            'Warning: Firestore operation failed, but user is authenticated: $firestoreError',
          );
          // Continue - user is still authenticated in Firebase Auth
        }
      }

      return userCredential;
    } catch (e) {
      print('Error registering with email and password: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Create or update user in Firestore
  Future<void> _createOrUpdateUser(User firebaseUser) async {
    try {
      final existingUser = await _firestoreService.getUser(firebaseUser.uid);

      if (existingUser == null) {
        final preferredName =
            firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : firebaseUser.email?.split('@').first ?? 'focususer';
        final generatedUsername = await _firestoreService
            .generateUniqueUsername(preferredName);

        // Create new user
        final newUser = UserModel.create(
          userId: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: generatedUsername,
          displayName: firebaseUser.displayName,
        );
        await _firestoreService.createUser(newUser);
      } else {
        var ensuredUsername = existingUser.username;
        if ((ensuredUsername ?? '').trim().isEmpty) {
          final preferredName =
              firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!.trim()
              : firebaseUser.email?.split('@').first ?? 'focususer';
          ensuredUsername = await _firestoreService.generateUniqueUsername(
            preferredName,
            excludeUserId: existingUser.userId,
          );
        }

        // Update last login time and ensure username exists
        final updatedUser = existingUser.copyWith(lastLoginAt: DateTime.now());
        await _firestoreService.updateUser(
          updatedUser.copyWith(username: ensuredUsername),
        );
      }
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) {
    return _firestoreService.isUsernameAvailable(
      username,
      excludeUserId: excludeUserId,
    );
  }

  Future<void> reserveUsernameForNewUser({
    required String userId,
    required String email,
    required String username,
    String? displayName,
  }) async {
    final uniqueUsername = await _firestoreService.generateUniqueUsername(
      username,
      excludeUserId: userId,
    );

    final existingUser = await _firestoreService.getUser(userId);
    if (existingUser == null) {
      final newUser = UserModel.create(
        userId: userId,
        email: email,
        username: uniqueUsername,
        displayName: displayName,
      );
      await _firestoreService.createUser(newUser);
      return;
    }

    final updatedUser = existingUser.copyWith(
      username: uniqueUsername,
      displayName: displayName ?? existingUser.displayName,
      lastLoginAt: DateTime.now(),
    );
    await _firestoreService.updateUser(updatedUser);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestoreService.deleteUser(user.uid);

        // Delete Firebase Auth account
        await user.delete();
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
