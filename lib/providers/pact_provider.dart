import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/pact_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class PactProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<PactModel> _activePacts = [];
  List<PactModel> _completedPacts = [];
  List<PactModel> _pactsToVerify = [];
  StreamSubscription<List<PactModel>>? _activePactsSubscription;
  StreamSubscription<List<PactModel>>? _completedPactsSubscription;
  StreamSubscription<List<PactModel>>? _pactsToVerifySubscription;
  final Set<String> _autoFailingPactIds = <String>{};
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastCreatedPactId;

  // Getters
  List<PactModel> get activePacts => _activePacts;
  List<PactModel> get completedPacts => _completedPacts;
  List<PactModel> get pactsToVerify => _pactsToVerify;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastCreatedPactId => _lastCreatedPactId;

  // Load user's active pacts
  void loadActivePacts(String userId) {
    _activePactsSubscription?.cancel();
    _activePactsSubscription = _firestoreService
        .streamUserPacts(userId, status: PactStatus.active)
        .listen(
          (pacts) {
            final overduePacts = pacts
                .where(
                  (pact) =>
                      pact.isOverdue &&
                      !_autoFailingPactIds.contains(pact.pactId),
                )
                .toList();

            if (overduePacts.isNotEmpty) {
              unawaited(_autoFailOverduePacts(overduePacts));
            }

            _activePacts = pacts.where((pact) => !pact.isOverdue).toList();
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load active pacts';
            notifyListeners();
          },
        );
  }

  Future<void> _autoFailOverduePacts(List<PactModel> overduePacts) async {
    for (final pact in overduePacts) {
      _autoFailingPactIds.add(pact.pactId);
      try {
        final updatedPact = pact.copyWith(
          status: PactStatus.failed,
          completedAt: DateTime.now(),
        );
        await _firestoreService.updatePact(updatedPact);
      } catch (_) {
      } finally {
        _autoFailingPactIds.remove(pact.pactId);
      }
    }
  }

  // Load user's expired pacts (completed + failed)
  void loadCompletedPacts(String userId) {
    _completedPactsSubscription?.cancel();
    _completedPactsSubscription = _firestoreService
        .streamUserExpiredPacts(userId)
        .listen(
          (pacts) {
            _completedPacts = pacts;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load expired pacts';
            notifyListeners();
          },
        );
  }

  // Load pacts that need verification by user
  void loadPactsToVerify(String userId) {
    _pactsToVerifySubscription?.cancel();
    _pactsToVerifySubscription = _firestoreService
        .streamPactsToVerify(userId)
        .listen(
          (pacts) {
            _pactsToVerify = pacts;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load pacts to verify';
            notifyListeners();
          },
        );
  }

  // Create a new pact
  Future<String?> createPact({
    required String userId,
    required String taskDescription,
    required DateTime deadline,
    String? recurrence,
    required VerificationType verificationType,
    String? verifierId,
    required ConsequenceType consequenceType,
    required Map<String, dynamic> consequenceDetails,
    List<DateTime>? reminderTimes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastCreatedPactId = null;
      notifyListeners();

      final pact = PactModel(
        pactId: '',
        userId: userId,
        taskDescription: taskDescription,
        deadline: deadline,
        recurrence: recurrence,
        verificationType: verificationType,
        verifierId: verifierId,
        consequenceType: consequenceType,
        consequenceDetails: consequenceDetails,
        status: PactStatus.active,
        createdAt: DateTime.now(),
        reminders:
            reminderTimes
                ?.map((time) => PactReminder(reminderTime: time, sent: false))
                .toList() ??
            [],
      );

      final createdPactId = await _firestoreService.createPact(pact);
      final existsInDatabase = await _firestoreService.pactExists(
        createdPactId,
      );

      if (!existsInDatabase) {
        throw Exception('Pact was not persisted to Firestore.');
      }

      _lastCreatedPactId = createdPactId;

      _isLoading = false;
      notifyListeners();
      return createdPactId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create pact: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Submit pact evidence
  Future<bool> submitEvidence({
    required PactModel pact,
    File? photoFile,
    File? videoFile,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String? evidenceUrl;

      // Upload evidence if provided
      if (photoFile != null) {
        evidenceUrl = await _storageService.uploadPactPhoto(
          pact.pactId,
          photoFile,
        );
      } else if (videoFile != null) {
        evidenceUrl = await _storageService.uploadPactVideo(
          pact.pactId,
          videoFile,
        );
      }

      // Update pact with evidence
      final updatedPact = pact.copyWith(
        evidenceUrl: evidenceUrl,
        status: pact.verificationType == VerificationType.selfAttest
            ? PactStatus.completed
            : PactStatus.verificationPending,
      );

      await _firestoreService.updatePact(updatedPact);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to submit evidence';
      notifyListeners();
      return false;
    }
  }

  // Verify a pact (for friend verification)
  Future<bool> verifyPact(PactModel pact, bool approved) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedPact = pact.copyWith(
        verificationResult: approved,
        status: approved ? PactStatus.completed : PactStatus.failed,
        completedAt: approved ? DateTime.now() : null,
      );

      await _firestoreService.updatePact(updatedPact);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to verify pact';
      notifyListeners();
      return false;
    }
  }

  // Mark pact as failed
  Future<bool> markPactAsFailed(PactModel pact) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedPact = pact.copyWith(
        status: PactStatus.failed,
        completedAt: DateTime.now(),
      );

      await _firestoreService.updatePact(updatedPact);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update pact';
      notifyListeners();
      return false;
    }
  }

  // Delete a pact
  Future<bool> deletePact(String pactId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deletePact(pactId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete pact';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _activePactsSubscription?.cancel();
    _completedPactsSubscription?.cancel();
    _pactsToVerifySubscription?.cancel();
    super.dispose();
  }
}
