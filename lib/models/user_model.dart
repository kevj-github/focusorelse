import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String? username;
  final String? displayName;
  final String? profilePictureUrl;
  final UserStats stats;
  final List<String> friendIds;
  final UserSettings settings;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.userId,
    required this.email,
    this.username,
    this.displayName,
    this.profilePictureUrl,
    required this.stats,
    required this.friendIds,
    required this.settings,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Factory constructor from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      username: data['username'],
      displayName: data['displayName'],
      profilePictureUrl: data['profilePictureUrl'],
      stats: UserStats.fromMap(data['stats'] ?? {}),
      friendIds: List<String>.from(data['friendIds'] ?? []),
      settings: UserSettings.fromMap(data['settings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'stats': stats.toMap(),
      'friendIds': friendIds,
      'settings': settings.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  // Create a new user with default values
  factory UserModel.create({
    required String userId,
    required String email,
    String? displayName,
  }) {
    return UserModel(
      userId: userId,
      email: email,
      displayName: displayName,
      stats: UserStats.empty(),
      friendIds: [],
      settings: UserSettings.defaults(),
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? username,
    String? displayName,
    String? profilePictureUrl,
    UserStats? stats,
    List<String>? friendIds,
    UserSettings? settings,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      userId: userId,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      stats: stats ?? this.stats,
      friendIds: friendIds ?? this.friendIds,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class UserStats {
  final int totalPactsCreated;
  final int totalPactsCompleted;
  final int totalPactsFailed;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;

  UserStats({
    required this.totalPactsCreated,
    required this.totalPactsCompleted,
    required this.totalPactsFailed,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
  });

  factory UserStats.empty() {
    return UserStats(
      totalPactsCreated: 0,
      totalPactsCompleted: 0,
      totalPactsFailed: 0,
      currentStreak: 0,
      longestStreak: 0,
      completionRate: 0.0,
    );
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalPactsCreated: map['totalPactsCreated'] ?? 0,
      totalPactsCompleted: map['totalPactsCompleted'] ?? 0,
      totalPactsFailed: map['totalPactsFailed'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      completionRate: (map['completionRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPactsCreated': totalPactsCreated,
      'totalPactsCompleted': totalPactsCompleted,
      'totalPactsFailed': totalPactsFailed,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'completionRate': completionRate,
    };
  }

  UserStats copyWith({
    int? totalPactsCreated,
    int? totalPactsCompleted,
    int? totalPactsFailed,
    int? currentStreak,
    int? longestStreak,
    double? completionRate,
  }) {
    return UserStats(
      totalPactsCreated: totalPactsCreated ?? this.totalPactsCreated,
      totalPactsCompleted: totalPactsCompleted ?? this.totalPactsCompleted,
      totalPactsFailed: totalPactsFailed ?? this.totalPactsFailed,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completionRate: completionRate ?? this.completionRate,
    );
  }
}

class UserSettings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String language;

  UserSettings({
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.language,
  });

  factory UserSettings.defaults() {
    return UserSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      language: 'en',
    );
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      language: map['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'language': language,
    };
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? language,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      language: language ?? this.language,
    );
  }
}
