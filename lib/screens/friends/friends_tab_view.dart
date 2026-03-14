import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/friend_model.dart';
import '../../models/pact_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../utils/time_label.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/avatar.dart';
import '../messages/message_screen.dart';
import 'friend_profile_screen.dart';

class FriendsTabView extends StatefulWidget {
  const FriendsTabView({super.key});

  @override
  State<FriendsTabView> createState() => _FriendsTabViewState();
}

class _FriendsTabViewState extends State<FriendsTabView> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  bool _isAddMode = false;
  bool _isSearchingUsers = false;
  List<UserModel> _suggestedUsers = const [];
  final Set<String> _sendingFriendRequestIds = <String>{};
  final Set<String> _processingIncomingRequestIds = <String>{};
  Map<String, FriendRelationStatus> _suggestionStatuses =
      <String, FriendRelationStatus>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!_isAddMode) {
      setState(() {});
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _searchUsersToAdd);
  }

  Future<void> _searchUsersToAdd() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) {
      return;
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSearchingUsers = false;
        _suggestedUsers = const [];
        _suggestionStatuses = <String, FriendRelationStatus>{};
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearchingUsers = true;
    });

    try {
      final results = await _firestoreService.searchUsersByUsername(
        query,
        excludeUserId: currentUser.userId,
      );

      final statuses = <String, FriendRelationStatus>{};
      for (final user in results) {
        statuses[user.userId] = await _firestoreService.getFriendRelationStatus(
          currentUser.userId,
          user.userId,
        );
      }

      if (!mounted) return;
      setState(() {
        _suggestedUsers = results;
        _suggestionStatuses = statuses;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingUsers = false;
        });
      }
    }
  }

  Future<void> _sendFriendRequest(UserModel targetUser) async {
    final currentUserId = context.read<AuthProvider>().userModel?.userId;
    if (currentUserId == null) {
      return;
    }

    setState(() {
      _sendingFriendRequestIds.add(targetUser.userId);
    });

    try {
      await _firestoreService.sendFriendRequest(
        currentUserId,
        targetUser.userId,
      );
      if (!mounted) return;
      setState(() {
        _suggestionStatuses[targetUser.userId] =
            FriendRelationStatus.requestPending;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request sent to @${targetUser.username ?? ''}.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = _friendRequestErrorMessage(error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.primary),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingFriendRequestIds.remove(targetUser.userId);
        });
      }
    }
  }

  String _friendRequestErrorMessage(String raw) {
    if (raw.contains('ALREADY_FRIENDS')) {
      return 'You are already friends.';
    }
    if (raw.contains('REQUEST_PENDING')) {
      return 'A friend request is already pending.';
    }
    if (raw.contains('CANNOT_ADD_SELF')) {
      return 'You cannot add yourself.';
    }
    return 'Unable to send friend request right now.';
  }

  Future<void> _acceptIncomingRequest(FriendModel request) async {
    setState(() {
      _processingIncomingRequestIds.add(request.friendshipId);
    });

    try {
      await _firestoreService.acceptFriendRequest(request.friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to accept friend request right now.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIncomingRequestIds.remove(request.friendshipId);
        });
      }
    }
  }

  Future<void> _declineIncomingRequest(FriendModel request) async {
    setState(() {
      _processingIncomingRequestIds.add(request.friendshipId);
    });

    try {
      await _firestoreService.declineFriendRequest(request.friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to decline friend request right now.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIncomingRequestIds.remove(request.friendshipId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.userModel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (currentUser == null) {
      if (authProvider.isAuthenticated || authProvider.isLoading) {
        return Center(
          child: Text(
            'Syncing your account...',
            style: TextStyle(color: secondaryText),
          ),
        );
      }

      return Center(
        child: Text(
          'Sign in to view your friends.',
          style: TextStyle(color: onSurface),
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _isAddMode
                        ? 'Search username to add'
                        : 'Search friends',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: _isAddMode
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  tooltip: _isAddMode ? 'Exit add friend mode' : 'Add friend',
                  onPressed: () {
                    setState(() {
                      _isAddMode = !_isAddMode;
                      _searchController.clear();
                      _suggestedUsers = const [];
                      _suggestionStatuses = <String, FriendRelationStatus>{};
                    });
                  },
                  icon: Icon(
                    Icons.person_add_alt_1,
                    color: _isAddMode
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isAddMode
              ? _buildAddFriendSuggestions(currentUser)
              : _buildFriendList(currentUser, query),
        ),
      ],
    );
  }

  Widget _buildAddFriendSuggestions(UserModel currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Text(
          'Type a username to find users.',
          style: TextStyle(color: secondary),
        ),
      );
    }

    if (_isSearchingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_suggestedUsers.isEmpty) {
      return Center(
        child: Text(
          'No matching users found.',
          style: TextStyle(color: secondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      itemBuilder: (context, index) {
        final user = _suggestedUsers[index];
        final relationStatus =
            _suggestionStatuses[user.userId] ?? FriendRelationStatus.none;
        final isSending = _sendingFriendRequestIds.contains(user.userId);

        final canAdd =
            relationStatus == FriendRelationStatus.none && !isSending;
        final actionLabel = relationStatus == FriendRelationStatus.friends
            ? 'Friends'
            : relationStatus == FriendRelationStatus.requestPending
            ? 'Pending'
            : isSending
            ? 'Sending...'
            : 'Add';

        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AppAvatar(imageUrl: user.profilePictureUrl, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.username ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((user.username ?? '').isNotEmpty)
                      Text(
                        '@${user.username}',
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: canAdd ? () => _sendFriendRequest(user) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: _suggestedUsers.length,
    );
  }

  Widget _buildFriendList(UserModel currentUser, String query) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return StreamBuilder<List<FriendModel>>(
      stream: _firestoreService.streamPendingFriendRequests(currentUser.userId),
      builder: (context, pendingSnapshot) {
        final pendingRequests = pendingSnapshot.data ?? const <FriendModel>[];
        final requesterIds = pendingRequests
            .map((r) => r.userId)
            .toSet()
            .toList();

        return FutureBuilder<List<UserModel>>(
          future: _firestoreService.getUsersByIds(requesterIds),
          builder: (context, incomingUsersSnapshot) {
            final incomingUsers =
                incomingUsersSnapshot.data ?? const <UserModel>[];
            final incomingUsersById = <String, UserModel>{
              for (final user in incomingUsers) user.userId: user,
            };

            return FutureBuilder<List<String>>(
              future: _firestoreService.getAcceptedFriendUserIds(
                currentUser.userId,
              ),
              builder: (context, friendIdsSnapshot) {
                if (friendIdsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final friendIds =
                    friendIdsSnapshot.data ?? currentUser.friendIds;

                return FutureBuilder<List<UserModel>>(
                  future: _firestoreService.getUsersByIds(friendIds),
                  builder: (context, friendsSnapshot) {
                    if (friendsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final allFriends = friendsSnapshot.data ?? [];
                    final friends = query.isEmpty
                        ? allFriends
                        : allFriends.where((friend) {
                            final displayName = (friend.displayName ?? '')
                                .toLowerCase();
                            final username = (friend.username ?? '')
                                .toLowerCase();
                            return displayName.contains(query) ||
                                username.contains(query);
                          }).toList();

                    return StreamBuilder<List<PactModel>>(
                      stream: _firestoreService.streamPactsForVerifier(
                        currentUser.userId,
                      ),
                      builder: (context, pactSnapshot) {
                        final allVerifyingPacts =
                            pactSnapshot.data ?? const <PactModel>[];
                        final pactsByFriend = _groupPactsByFriend(
                          allVerifyingPacts,
                          friendIds.toSet(),
                        );

                        final children = <Widget>[];

                        if (pendingRequests.isNotEmpty) {
                          children.add(
                            Text(
                              'Incoming Friend Requests',
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                          children.add(const SizedBox(height: 10));

                          for (var i = 0; i < pendingRequests.length; i++) {
                            final request = pendingRequests[i];
                            final requester = incomingUsersById[request.userId];
                            final requesterName =
                                requester?.displayName ??
                                requester?.username ??
                                'User';
                            final requesterUsername =
                                (requester?.username ?? '').trim();
                            final isProcessing = _processingIncomingRequestIds
                                .contains(request.friendshipId);

                            children.add(
                              AppCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    AppAvatar(
                                      imageUrl: requester?.profilePictureUrl,
                                      radius: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            requesterName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: onSurface,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (requesterUsername.isNotEmpty)
                                            Text(
                                              '@$requesterUsername',
                                              style: TextStyle(
                                                color: secondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _declineIncomingRequest(
                                              request,
                                            ),
                                      child: const Text('Decline'),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () =>
                                                _acceptIncomingRequest(request),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        isProcessing ? '...' : 'Accept',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (i != pendingRequests.length - 1) {
                              children.add(const SizedBox(height: 10));
                            }
                          }

                          children.add(const SizedBox(height: 16));
                        }

                        if (friendIds.isEmpty) {
                          children.add(
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  'No friends yet.',
                                  style: TextStyle(
                                    color: secondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else if (friends.isEmpty) {
                          children.add(
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  'No friends match your search.',
                                  style: TextStyle(color: secondary),
                                ),
                              ),
                            ),
                          );
                        } else {
                          for (var i = 0; i < friends.length; i++) {
                            final friend = friends[i];
                            final status = _resolveFriendPactStatus(
                              pactsByFriend[friend.userId] ??
                                  const <PactModel>[],
                            );

                            children.add(
                              FriendPactCard(
                                friend: friend,
                                currentUserId: currentUser.userId,
                                status: status,
                                onCardTap: () =>
                                    _openFriendProfile(friend: friend),
                                onMessageTap: () =>
                                    _openMessageScreen(friend: friend),
                                onReviewTap:
                                    status.type ==
                                            FriendPactStatusType
                                                .evidenceSubmitted &&
                                        status.pact != null
                                    ? () => _openReviewSheet(
                                        context,
                                        pact: status.pact!,
                                        friend: friend,
                                      )
                                    : null,
                              ),
                            );

                            if (i != friends.length - 1) {
                              children.add(const SizedBox(height: 12));
                            }
                          }
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                          children: children,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Map<String, List<PactModel>> _groupPactsByFriend(
    List<PactModel> pacts,
    Set<String> friendIds,
  ) {
    final grouped = <String, List<PactModel>>{};
    for (final pact in pacts) {
      if (!friendIds.contains(pact.userId)) {
        continue;
      }
      grouped.putIfAbsent(pact.userId, () => []).add(pact);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.deadline.compareTo(b.deadline));
    }

    return grouped;
  }

  FriendPactStatus _resolveFriendPactStatus(List<PactModel> friendPacts) {
    final now = DateTime.now();

    PactModel? submitted;
    PactModel? waiting;
    PactModel? failed;

    for (final pact in friendPacts) {
      if (pact.status == PactStatus.verificationPending) {
        submitted ??= pact;
      } else if (pact.status == PactStatus.active) {
        waiting ??= pact;
      } else if (pact.status == PactStatus.failed &&
          pact.deadline.isBefore(now)) {
        failed ??= pact;
      }
    }

    if (submitted != null) {
      return FriendPactStatus(
        type: FriendPactStatusType.evidenceSubmitted,
        message: 'Evidence submitted',
        pact: submitted,
      );
    }

    if (waiting != null) {
      final dueIn = waiting.deadline.difference(now);
      return FriendPactStatus(
        type: FriendPactStatusType.waitingForEvidence,
        message: 'Waiting for evidence - Due in ${_formatDuration(dueIn)}',
        pact: waiting,
      );
    }

    if (failed != null) {
      final lateFor = now.difference(failed.deadline);
      return FriendPactStatus(
        type: FriendPactStatusType.failedSubmission,
        message: 'Failed submission - Late for ${_formatDuration(lateFor)}',
        pact: failed,
      );
    }

    return const FriendPactStatus(
      type: FriendPactStatusType.noPact,
      message: 'No current pact formed with you',
    );
  }

  String _formatDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;

    if (safeDuration.inDays > 0) {
      return '${safeDuration.inDays}d';
    }
    if (safeDuration.inHours > 0) {
      return '${safeDuration.inHours}h';
    }
    if (safeDuration.inMinutes > 0) {
      return '${safeDuration.inMinutes}m';
    }
    return '${safeDuration.inSeconds}s';
  }

  Future<void> _openMessageScreen({required UserModel friend}) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MessageScreen(currentUserId: currentUser.userId, friend: friend),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openFriendProfile({required UserModel friend}) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      return;
    }

    final unfriended = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FriendProfileScreen(
          currentUserId: currentUser.userId,
          friend: friend,
        ),
      ),
    );

    if (mounted && unfriended == true) {
      setState(() {});
    }
  }

  Future<void> _openReviewSheet(
    BuildContext context, {
    required PactModel pact,
    required UserModel friend,
  }) async {
    final pactProvider = context.read<PactProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review submission from ${friend.displayName ?? friend.username ?? 'Friend'}',
                  style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(pact.taskDescription, style: TextStyle(color: onSurface)),
                const SizedBox(height: 6),
                Text(
                  pact.evidenceUrl?.isNotEmpty == true
                      ? 'Evidence is attached and ready for review.'
                      : 'Evidence was submitted, but no media URL was found.',
                  style: TextStyle(color: secondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final ok = await pactProvider.verifyPact(pact, false);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Submission rejected.'
                                    : 'Unable to reject submission right now.',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final ok = await pactProvider.verifyPact(pact, true);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Submission approved.'
                                    : 'Unable to approve submission right now.',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum FriendPactStatusType {
  waitingForEvidence,
  failedSubmission,
  evidenceSubmitted,
  noPact,
}

class FriendPactStatus {
  const FriendPactStatus({
    required this.type,
    required this.message,
    this.pact,
  });

  final FriendPactStatusType type;
  final String message;
  final PactModel? pact;
}

class FriendPactCard extends StatelessWidget {
  const FriendPactCard({
    super.key,
    required this.friend,
    required this.currentUserId,
    required this.status,
    this.onCardTap,
    this.onMessageTap,
    this.onReviewTap,
  });

  static final FirestoreService _firestoreService = FirestoreService();

  final UserModel friend;
  final String currentUserId;
  final FriendPactStatus status;
  final VoidCallback? onCardTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onReviewTap;

  @override
  Widget build(BuildContext context) {
    final title = friend.displayName ?? friend.username ?? 'Friend';
    final username = (friend.username ?? '').trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(imageUrl: friend.profilePictureUrl, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: TextStyle(color: secondary, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                StreamBuilder<int>(
                  stream: _firestoreService.streamUnreadMessageCount(
                    currentUserId: currentUserId,
                    friendUserId: friend.userId,
                  ),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: onMessageTap,
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 18,
                                  color: secondary,
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<DateTime?>(
                          stream: _firestoreService.streamLastMessageAt(
                            currentUserId: currentUserId,
                            friendUserId: friend.userId,
                          ),
                          builder: (context, timeSnapshot) {
                            return Text(
                              TimeLabel.formatRelativeShort(timeSnapshot.data),
                              style: TextStyle(
                                color: secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _FriendStat(
                  label: 'Streak',
                  value: '${friend.stats.currentStreak}',
                ),
                const SizedBox(width: 24),
                _FriendStat(
                  label: 'Completed',
                  value: '${friend.stats.totalPactsCompleted}',
                ),
                const SizedBox(width: 24),
                _FriendStat(
                  label: 'Failed',
                  value: '${friend.stats.totalPactsFailed}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            FriendPactStatusLabel(status: status, onReviewTap: onReviewTap),
          ],
        ),
      ),
    );
  }
}

class _FriendStat extends StatelessWidget {
  const _FriendStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class FriendPactStatusLabel extends StatelessWidget {
  const FriendPactStatusLabel({
    super.key,
    required this.status,
    this.onReviewTap,
  });

  final FriendPactStatus status;
  final VoidCallback? onReviewTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _statusVisual(status.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.border),
      ),
      child: Row(
        children: [
          Icon(visual.icon, size: 18, color: visual.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(
                color: visual.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (status.type == FriendPactStatusType.evidenceSubmitted &&
              onReviewTap != null)
            TextButton(
              onPressed: onReviewTap,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                backgroundColor: isDark
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Review'),
            ),
        ],
      ),
    );
  }

  _StatusVisual _statusVisual(FriendPactStatusType type) {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final baseBg = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final baseBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    switch (type) {
      case FriendPactStatusType.waitingForEvidence:
        return _StatusVisual(
          foreground: AppColors.warning,
          background: AppColors.warning.withValues(alpha: 0.15),
          border: AppColors.warning.withValues(alpha: 0.35),
          icon: Icons.schedule,
        );
      case FriendPactStatusType.failedSubmission:
        return _StatusVisual(
          foreground: AppColors.primary,
          background: AppColors.primary.withValues(alpha: 0.12),
          border: AppColors.primary.withValues(alpha: 0.35),
          icon: Icons.error_outline,
        );
      case FriendPactStatusType.evidenceSubmitted:
        return _StatusVisual(
          foreground: AppColors.success,
          background: AppColors.success.withValues(alpha: 0.12),
          border: AppColors.success.withValues(alpha: 0.35),
          icon: Icons.check_circle_outline,
        );
      case FriendPactStatusType.noPact:
        return _StatusVisual(
          foreground: secondary,
          background: baseBg,
          border: baseBorder,
          icon: Icons.remove_circle_outline,
        );
    }
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.foreground,
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final Color border;
  final IconData icon;
}
