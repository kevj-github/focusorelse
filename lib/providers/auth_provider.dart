import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state
  void _initializeAuth() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        // Load user model from Firestore
        await _loadUserModel(user.uid);
      } else {
        _userModel = null;
      }

      notifyListeners();
    });
  }

  // Load user model from Firestore
  Future<void> _loadUserModel(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      _userModel = user;

      // If user doesn't exist in Firestore yet, create it
      if (user == null && _firebaseUser != null) {
        print('User not found in Firestore, creating new user document...');
        final newUser = UserModel.create(
          userId: userId,
          email: _firebaseUser!.email ?? '',
          displayName: _firebaseUser!.displayName,
        );
        await _firestoreService.createUser(newUser);
        _userModel = newUser;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading user model: $e');
      // Don't set error message here - user is still authenticated
      // Just notify listeners so UI can update
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();

      _isLoading = false;
      notifyListeners();

      return userCredential != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.signInWithEmailPassword(email, password);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.registerWithEmailPassword(
        email,
        password,
        displayName,
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      _firebaseUser = null;
      _userModel = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _firestoreService.updateUser(updatedUser);
      _userModel = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
