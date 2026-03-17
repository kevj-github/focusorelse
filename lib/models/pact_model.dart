import 'package:cloud_firestore/cloud_firestore.dart';

enum PactStatus { active, completed, failed, verificationPending }

enum VerificationType {
  selfAttest,
  friendVerify,
  aiVerify,
  photoProof,
  videoProof,
}

enum ConsequenceType { socialSharing, donationChallenge, funnyPenalty }

enum ConsequenceStatus {
  none,
  pendingSubmission,
  pendingApproval,
  rejected,
  approved,
}

class PactModel {
  final String pactId;
  final String userId;
  final String taskDescription;
  final DateTime deadline;
  final String? recurrence; // null for one-time, 'daily', 'weekly', etc.
  final VerificationType verificationType;
  final String? verifierId; // Friend's userId if friendVerify
  final ConsequenceType consequenceType;
  final Map<String, dynamic> consequenceDetails;
  final PactStatus status;
  final String? evidenceUrl; // Photo/video URL if applicable
  final bool?
  verificationResult; // null if pending, true/false after verification
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<PactReminder> reminders;
  final ConsequenceStatus consequenceStatus;
  final String? consequenceEvidenceUrl;
  final bool? consequenceVerificationResult;
  final DateTime? consequenceSubmittedAt;
  final DateTime? consequenceReviewedAt;

  PactModel({
    required this.pactId,
    required this.userId,
    required this.taskDescription,
    required this.deadline,
    this.recurrence,
    required this.verificationType,
    this.verifierId,
    required this.consequenceType,
    required this.consequenceDetails,
    required this.status,
    this.evidenceUrl,
    this.verificationResult,
    required this.createdAt,
    this.completedAt,
    required this.reminders,
    this.consequenceStatus = ConsequenceStatus.none,
    this.consequenceEvidenceUrl,
    this.consequenceVerificationResult,
    this.consequenceSubmittedAt,
    this.consequenceReviewedAt,
  });

  // Factory constructor from Firestore
  factory PactModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PactModel(
      pactId: doc.id,
      userId: data['userId'] ?? '',
      taskDescription: data['taskDescription'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      recurrence: data['recurrence'],
      verificationType: VerificationType.values.firstWhere(
        (e) => e.name == (data['verificationType'] ?? 'selfAttest'),
        orElse: () => VerificationType.selfAttest,
      ),
      verifierId: data['verifierId'],
      consequenceType: ConsequenceType.values.firstWhere(
        (e) => e.name == (data['consequenceType'] ?? 'socialSharing'),
        orElse: () => ConsequenceType.socialSharing,
      ),
      consequenceDetails: Map<String, dynamic>.from(
        data['consequenceDetails'] ?? {},
      ),
      status: PactStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => PactStatus.active,
      ),
      evidenceUrl: data['evidenceUrl'],
      verificationResult: data['verificationResult'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      consequenceStatus: ConsequenceStatus.values.firstWhere(
        (e) => e.name == (data['consequenceStatus'] ?? 'none'),
        orElse: () => ConsequenceStatus.none,
      ),
      consequenceEvidenceUrl: data['consequenceEvidenceUrl'],
      consequenceVerificationResult: data['consequenceVerificationResult'],
      consequenceSubmittedAt: data['consequenceSubmittedAt'] != null
          ? (data['consequenceSubmittedAt'] as Timestamp).toDate()
          : null,
      consequenceReviewedAt: data['consequenceReviewedAt'] != null
          ? (data['consequenceReviewedAt'] as Timestamp).toDate()
          : null,
      reminders:
          (data['reminders'] as List<dynamic>?)
              ?.map((r) => PactReminder.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'taskDescription': taskDescription,
      'deadline': Timestamp.fromDate(deadline),
      'recurrence': recurrence,
      'verificationType': verificationType.name,
      'verifierId': verifierId,
      'consequenceType': consequenceType.name,
      'consequenceDetails': consequenceDetails,
      'status': status.name,
      'evidenceUrl': evidenceUrl,
      'verificationResult': verificationResult,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'consequenceStatus': consequenceStatus.name,
      'consequenceEvidenceUrl': consequenceEvidenceUrl,
      'consequenceVerificationResult': consequenceVerificationResult,
      'consequenceSubmittedAt': consequenceSubmittedAt != null
          ? Timestamp.fromDate(consequenceSubmittedAt!)
          : null,
      'consequenceReviewedAt': consequenceReviewedAt != null
          ? Timestamp.fromDate(consequenceReviewedAt!)
          : null,
    };
  }

  // Helper to check if pact is overdue
  bool get isOverdue =>
      DateTime.now().isAfter(deadline) && status == PactStatus.active;

  bool get hasPendingConsequence =>
      status == PactStatus.failed &&
      consequenceStatus != ConsequenceStatus.approved;

  // Helper to get time remaining
  Duration get timeRemaining => deadline.difference(DateTime.now());

  // Helper to format time remaining as string
  String get timeRemainingFormatted {
    if (status == PactStatus.failed) {
      return '${_formatCompactDuration(DateTime.now().difference(completedAt ?? deadline))} ago';
    }

    if (status == PactStatus.completed) {
      return '${_formatCompactDuration(DateTime.now().difference(completedAt ?? deadline))} ago';
    }

    if (isOverdue) {
      return 'Failed';
    }

    return _formatCompactDuration(timeRemaining);
  }

  String _formatCompactDuration(Duration duration) {
    final absolute = duration.isNegative ? duration.abs() : duration;

    final days = absolute.inDays;
    final hours = absolute.inHours % 24;
    final minutes = absolute.inMinutes % 60;
    final seconds = absolute.inSeconds % 60;

    if (days > 0) {
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }

    if (minutes > 0) {
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    }

    return '${seconds}s';
  }

  PactModel copyWith({
    String? taskDescription,
    DateTime? deadline,
    String? recurrence,
    VerificationType? verificationType,
    String? verifierId,
    ConsequenceType? consequenceType,
    Map<String, dynamic>? consequenceDetails,
    PactStatus? status,
    String? evidenceUrl,
    bool? verificationResult,
    DateTime? completedAt,
    List<PactReminder>? reminders,
    ConsequenceStatus? consequenceStatus,
    String? consequenceEvidenceUrl,
    bool? consequenceVerificationResult,
    DateTime? consequenceSubmittedAt,
    DateTime? consequenceReviewedAt,
  }) {
    return PactModel(
      pactId: pactId,
      userId: userId,
      taskDescription: taskDescription ?? this.taskDescription,
      deadline: deadline ?? this.deadline,
      recurrence: recurrence ?? this.recurrence,
      verificationType: verificationType ?? this.verificationType,
      verifierId: verifierId ?? this.verifierId,
      consequenceType: consequenceType ?? this.consequenceType,
      consequenceDetails: consequenceDetails ?? this.consequenceDetails,
      status: status ?? this.status,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      verificationResult: verificationResult ?? this.verificationResult,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      reminders: reminders ?? this.reminders,
      consequenceStatus: consequenceStatus ?? this.consequenceStatus,
      consequenceEvidenceUrl:
          consequenceEvidenceUrl ?? this.consequenceEvidenceUrl,
      consequenceVerificationResult:
          consequenceVerificationResult ?? this.consequenceVerificationResult,
      consequenceSubmittedAt:
          consequenceSubmittedAt ?? this.consequenceSubmittedAt,
      consequenceReviewedAt:
          consequenceReviewedAt ?? this.consequenceReviewedAt,
    );
  }
}

class PactReminder {
  final DateTime reminderTime;
  final bool sent;

  PactReminder({required this.reminderTime, required this.sent});

  factory PactReminder.fromMap(Map<String, dynamic> map) {
    return PactReminder(
      reminderTime: (map['reminderTime'] as Timestamp).toDate(),
      sent: map['sent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'reminderTime': Timestamp.fromDate(reminderTime), 'sent': sent};
  }
}
