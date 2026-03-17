import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/pact_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class PactProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

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
  bool _hasPendingConsequence = false;
  String? _currentUserId;
  bool _notificationsReady = false;
  int _lastVerifyCount = 0;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _boundNotificationUserId;

  PactProvider() {
    unawaited(_initializeNotifications());
  }

  List<PactModel> get activePacts => _activePacts;
  List<PactModel> get completedPacts => _completedPacts;
  List<PactModel> get pactsToVerify => _pactsToVerify;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastCreatedPactId => _lastCreatedPactId;
  bool get hasPendingConsequence => _hasPendingConsequence;
  PactModel? get pendingConsequencePact {
    final candidates =
        _completedPacts.where((pact) => pact.hasPendingConsequence).toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first;
  }

  void loadActivePacts(String userId) {
    _currentUserId = userId;
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
          consequenceStatus: ConsequenceStatus.pendingSubmission,
          consequenceVerificationResult: null,
        );
        await _firestoreService.updatePact(updatedPact);
        await _syncPendingConsequenceLockFlag(userId: pact.userId);
      } catch (_) {
      } finally {
        _autoFailingPactIds.remove(pact.pactId);
      }
    }
  }

  void loadCompletedPacts(String userId) {
    _currentUserId = userId;
    _completedPactsSubscription?.cancel();
    _completedPactsSubscription = _firestoreService
        .streamUserExpiredPacts(userId)
        .listen(
          (pacts) {
            unawaited(_repairLegacyAiVerificationStates(pacts));
            _completedPacts = pacts;
            _hasPendingConsequence = _completedPacts.any(
              (pact) => pact.hasPendingConsequence,
            );
            _errorMessage = null;
            unawaited(_syncPendingConsequenceLockFlag());
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load expired pacts';
            notifyListeners();
          },
        );
  }

  void loadPactsToVerify(String userId) {
    _currentUserId = userId;
    _pactsToVerifySubscription?.cancel();
    _pactsToVerifySubscription = _firestoreService
        .streamPactsForVerifier(userId)
        .listen(
          (pacts) {
            unawaited(_repairLegacyAiVerificationStates(pacts));
            final needsReview = pacts
                .where(
                  (pact) =>
                      pact.status == PactStatus.verificationPending ||
                      (pact.status == PactStatus.failed &&
                          pact.consequenceStatus ==
                              ConsequenceStatus.pendingApproval),
                )
                .toList();

            if (_notificationsReady && needsReview.length > _lastVerifyCount) {
              final latest = needsReview.first;
              unawaited(
                _notificationService.showLocalNotification(
                  id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
                  title: 'Verifier Action Needed',
                  body: latest.taskDescription,
                  payload: latest.pactId,
                ),
              );
            }
            _lastVerifyCount = needsReview.length;
            _pactsToVerify = needsReview;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Failed to load pacts to verify';
            notifyListeners();
          },
        );
  }

  Future<void> _repairLegacyAiVerificationStates(List<PactModel> pacts) async {
    for (final pact in pacts) {
      if (pact.verificationType != VerificationType.aiVerify) {
        continue;
      }

      PactModel? repaired;

      if (pact.status == PactStatus.verificationPending) {
        repaired = pact.copyWith(
          status: PactStatus.completed,
          verificationResult: true,
          completedAt: pact.completedAt ?? DateTime.now(),
          consequenceStatus: ConsequenceStatus.none,
        );
      } else if (pact.status == PactStatus.failed &&
          pact.consequenceStatus == ConsequenceStatus.pendingApproval) {
        repaired = pact.copyWith(
          consequenceStatus: ConsequenceStatus.approved,
          consequenceVerificationResult: true,
          consequenceReviewedAt: pact.consequenceReviewedAt ?? DateTime.now(),
        );
      }

      if (repaired == null) {
        continue;
      }

      try {
        await _firestoreService.updatePact(repaired);
        if (repaired.status == PactStatus.failed) {
          await _syncPendingConsequenceLockFlag(userId: repaired.userId);
        }
      } catch (_) {
        // Best-effort repair for legacy AI pacts. Keep UI responsive even if this fails.
      }
    }
  }

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
        consequenceStatus: ConsequenceStatus.none,
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

      if (verifierId != null && verifierId.isNotEmpty && verifierId != userId) {
        try {
          await _firestoreService.createAppNotification(
            recipientUserId: verifierId,
            actorUserId: userId,
            type: 'verifier-assigned',
            title: 'New pact to verify',
            body: taskDescription,
            pactId: createdPactId,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Failed to create verifier-assigned notification: $e');
          }
        }
      }

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

  Future<bool> submitEvidence({
    required PactModel pact,
    File? photoFile,
    File? videoFile,
    String? submissionNote,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String? evidenceUrl;

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

      final updatedConsequenceDetails = Map<String, dynamic>.from(
        pact.consequenceDetails,
      );
      final trimmedNote = submissionNote?.trim();
      if (trimmedNote != null && trimmedNote.isNotEmpty) {
        updatedConsequenceDetails['submissionNote'] = trimmedNote;
      }

      final submittingConsequence = pact.status == PactStatus.failed;
      final aiAutoApprove = pact.verificationType == VerificationType.aiVerify;
      final verifierId = pact.verifierId;

      final updatedPact = submittingConsequence
          ? pact.copyWith(
              consequenceEvidenceUrl: evidenceUrl,
              consequenceDetails: updatedConsequenceDetails,
              consequenceStatus: aiAutoApprove
                  ? ConsequenceStatus.approved
                  : ConsequenceStatus.pendingApproval,
              consequenceVerificationResult: aiAutoApprove ? true : null,
              consequenceSubmittedAt: DateTime.now(),
              consequenceReviewedAt: aiAutoApprove ? DateTime.now() : null,
            )
          : pact.copyWith(
              evidenceUrl: evidenceUrl,
              consequenceDetails: updatedConsequenceDetails,
              status:
                  (pact.verificationType == VerificationType.selfAttest ||
                      aiAutoApprove)
                  ? PactStatus.completed
                  : PactStatus.verificationPending,
              verificationResult: aiAutoApprove
                  ? true
                  : pact.verificationResult,
              completedAt:
                  (pact.verificationType == VerificationType.selfAttest ||
                      aiAutoApprove)
                  ? DateTime.now()
                  : null,
            );

      await _firestoreService.updatePact(updatedPact);

      if (!aiAutoApprove && verifierId != null && verifierId.isNotEmpty) {
        try {
          final title = submittingConsequence
              ? 'Consequence evidence submitted'
              : 'Pact evidence submitted';
          await _firestoreService.createAppNotification(
            recipientUserId: verifierId,
            actorUserId: pact.userId,
            type: submittingConsequence
                ? 'consequence-review-required'
                : 'pact-review-required',
            title: title,
            body: pact.taskDescription,
            pactId: pact.pactId,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Failed to create submission notification: $e');
          }
        }
      }

      if (submittingConsequence) {
        await _syncPendingConsequenceLockFlag(userId: pact.userId);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to submit evidence: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPact(PactModel pact, bool approved) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedPact = pact.copyWith(
        verificationResult: approved,
        status: approved ? PactStatus.completed : PactStatus.failed,
        completedAt: approved ? DateTime.now() : null,
        consequenceStatus: approved
            ? ConsequenceStatus.none
            : ConsequenceStatus.pendingSubmission,
      );

      await _firestoreService.updatePact(updatedPact);
      await _syncPendingConsequenceLockFlag(userId: pact.userId);

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

  Future<bool> verifyConsequence(PactModel pact, bool approved) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedPact = pact.copyWith(
        consequenceStatus: approved
            ? ConsequenceStatus.approved
            : ConsequenceStatus.rejected,
        consequenceVerificationResult: approved,
        consequenceReviewedAt: DateTime.now(),
      );

      await _firestoreService.updatePact(updatedPact);
      await _syncPendingConsequenceLockFlag(userId: pact.userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to verify consequence evidence';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markPactAsFailed(PactModel pact) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedPact = pact.copyWith(
        status: PactStatus.failed,
        completedAt: DateTime.now(),
        consequenceStatus: ConsequenceStatus.pendingSubmission,
      );

      await _firestoreService.updatePact(updatedPact);
      await _syncPendingConsequenceLockFlag(userId: pact.userId);

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _syncPendingConsequenceLockFlag({String? userId}) async {
    final resolvedUserId = userId ?? _currentUserId;
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return;
    }

    // Verifiers can update pact docs but cannot update another user's profile lock.
    // Skip cross-user lock sync to avoid false failure after successful review.
    if (_currentUserId != null && resolvedUserId != _currentUserId) {
      return;
    }

    final shouldLock = _completedPacts.any(
      (pact) => pact.hasPendingConsequence,
    );
    _hasPendingConsequence = shouldLock;
    await _firestoreService.updateUserConsequenceLock(
      userId: resolvedUserId,
      hasPendingConsequence: shouldLock,
    );
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      _notificationsReady = true;
    } catch (_) {
      _notificationsReady = false;
    }
  }

  Future<void> registerNotificationUser(String userId) async {
    if (!_notificationsReady || userId.isEmpty) {
      return;
    }

    if (_boundNotificationUserId == userId &&
        _tokenRefreshSubscription != null) {
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _boundNotificationUserId = userId;

    final token = await _notificationService.getToken();
    if (token != null && token.isNotEmpty) {
      await _firestoreService.updateUserFcmToken(userId: userId, token: token);
    }

    _tokenRefreshSubscription = _notificationService.onTokenRefresh.listen((
      newToken,
    ) {
      if (newToken.isEmpty) {
        return;
      }
      unawaited(
        _firestoreService.updateUserFcmToken(userId: userId, token: newToken),
      );
    });
  }

  @override
  void dispose() {
    _activePactsSubscription?.cancel();
    _completedPactsSubscription?.cancel();
    _pactsToVerifySubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}
