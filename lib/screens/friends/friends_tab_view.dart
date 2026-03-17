import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/friend_model.dart';
import '../../models/pact_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/time_label.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/avatar.dart';
import '../messages/message_screen.dart';
import 'friend_profile_screen.dart';
import 'verifier_pacts_screen.dart';

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
          backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.success,
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
            style: AppTypography.bodyMedium.copyWith(color: secondaryText),
          ),
        );
      }

      return Center(
        child: Text(
          'Sign in to view your friends.',
          style: AppTypography.bodyMedium.copyWith(color: onSurface),
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
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
              const SizedBox(width: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: _isAddMode
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    AppElevation.radiusMedium,
                  ),
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
          style: AppTypography.bodyMedium.copyWith(color: secondary),
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
          style: AppTypography.bodyMedium.copyWith(color: secondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              AppAvatar(imageUrl: user.profilePictureUrl, radius: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.username ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((user.username ?? '').isNotEmpty)
                      Text(
                        '@${user.username}',
                        style: AppTypography.caption.copyWith(color: secondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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
                              style: AppTypography.titleMedium.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                          children.add(const SizedBox(height: AppSpacing.sm));

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
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    AppAvatar(
                                      imageUrl: requester?.profilePictureUrl,
                                      radius: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            requesterName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodyLarge
                                                .copyWith(
                                                  color: onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (requesterUsername.isNotEmpty)
                                            Text(
                                              '@$requesterUsername',
                                              style: AppTypography.labelSmall
                                                  .copyWith(color: secondary),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    OutlinedButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _declineIncomingRequest(
                                              request,
                                            ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        minimumSize: const Size(0, 34),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      child: const Text('Decline'),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    ElevatedButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () =>
                                                _acceptIncomingRequest(request),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
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
                              children.add(
                                const SizedBox(height: AppSpacing.sm),
                              );
                            }
                          }

                          children.add(const SizedBox(height: AppSpacing.lg));
                        }

                        if (friendIds.isEmpty) {
                          children.add(
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xl,
                                ),
                                child: Text(
                                  'No friends yet.',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: secondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else if (friends.isEmpty) {
                          children.add(
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xl,
                                ),
                                child: Text(
                                  'No friends match your search.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: secondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          final friendEntries = friends
                              .map(
                                (friend) => _FriendStatusEntry(
                                  friend: friend,
                                  status: _resolveFriendPactStatus(
                                    pactsByFriend[friend.userId] ??
                                        const <PactModel>[],
                                  ),
                                ),
                              )
                              .toList();

                          friendEntries.sort((a, b) {
                            final priorityCompare = _friendStatusPriority(
                              a.status.type,
                            ).compareTo(_friendStatusPriority(b.status.type));
                            if (priorityCompare != 0) {
                              return priorityCompare;
                            }

                            final nameA =
                                (a.friend.displayName ??
                                        a.friend.username ??
                                        '')
                                    .trim()
                                    .toLowerCase();
                            final nameB =
                                (b.friend.displayName ??
                                        b.friend.username ??
                                        '')
                                    .trim()
                                    .toLowerCase();
                            return nameA.compareTo(nameB);
                          });

                          for (var i = 0; i < friendEntries.length; i++) {
                            final entry = friendEntries[i];
                            final friend = entry.friend;
                            final status = entry.status;

                            children.add(
                              StreamBuilder<UserModel?>(
                                stream: _firestoreService.streamUser(
                                  friend.userId,
                                ),
                                initialData: friend,
                                builder: (context, friendSnapshot) {
                                  final liveFriend = friendSnapshot.data;
                                  if (liveFriend == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return FriendPactCard(
                                    friend: liveFriend,
                                    currentUserId: currentUser.userId,
                                    status: status,
                                    onCardTap: () =>
                                        _openFriendProfile(friend: liveFriend),
                                    onMessageTap: () =>
                                        _openMessageScreen(friend: liveFriend),
                                    onStatusTap: () => _openVerifierPacts(
                                      friend: liveFriend,
                                      currentUserId: currentUser.userId,
                                    ),
                                  );
                                },
                              ),
                            );

                            if (i != friendEntries.length - 1) {
                              children.add(const SizedBox(height: 12));
                            }
                          }
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
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

    PactModel? waitingApproval;
    PactModel? waitingPactEvidence;
    PactModel? waitingConsequenceEvidence;
    PactModel? failedDue;

    for (final pact in friendPacts) {
      if (pact.status == PactStatus.verificationPending ||
          (pact.status == PactStatus.failed &&
              pact.consequenceStatus == ConsequenceStatus.pendingApproval)) {
        waitingApproval ??= pact;
      } else if (pact.status == PactStatus.active) {
        waitingPactEvidence ??= pact;
      } else if (pact.status == PactStatus.failed &&
          pact.deadline.isBefore(now) &&
          (pact.consequenceStatus == ConsequenceStatus.pendingSubmission ||
              pact.consequenceStatus == ConsequenceStatus.rejected ||
              pact.consequenceStatus == ConsequenceStatus.none)) {
        waitingConsequenceEvidence ??= pact;
      } else if (pact.status == PactStatus.failed &&
          pact.deadline.isBefore(now)) {
        failedDue ??= pact;
      }
    }

    if (waitingApproval != null) {
      return FriendPactStatus(
        type: FriendPactStatusType.waitingForApproval,
        message: 'Waiting for your approval',
        pact: waitingApproval,
      );
    }

    if (waitingPactEvidence != null) {
      return FriendPactStatus(
        type: FriendPactStatusType.waitingForPactEvidence,
        message: 'Waiting for completion evidence',
        pact: waitingPactEvidence,
      );
    }

    if (waitingConsequenceEvidence != null) {
      return FriendPactStatus(
        type: FriendPactStatusType.waitingForConsequenceEvidence,
        message: 'Waiting for consequence evidence',
        pact: waitingConsequenceEvidence,
      );
    }

    if (failedDue != null) {
      return FriendPactStatus(
        type: FriendPactStatusType.noPact,
        message: 'Currently no pact formed with you',
        pact: failedDue,
      );
    }

    return const FriendPactStatus(
      type: FriendPactStatusType.noPact,
      message: 'Currently no pact formed with you',
    );
  }

  int _friendStatusPriority(FriendPactStatusType type) {
    switch (type) {
      case FriendPactStatusType.waitingForApproval:
        return 0;
      case FriendPactStatusType.waitingForPactEvidence:
        return 1;
      case FriendPactStatusType.waitingForConsequenceEvidence:
        return 2;
      case FriendPactStatusType.failedToComplete:
      case FriendPactStatusType.noPact:
        return 3;
    }
  }

  Future<void> _openVerifierPacts({
    required UserModel friend,
    required String currentUserId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            VerifierPactsScreen(currentUserId: currentUserId, friend: friend),
      ),
    );
  }

  Future<void> _openMessageScreen({required UserModel friend}) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      return;
    }

    if (currentUser.hasPendingConsequence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chat is locked until your pending consequence is approved.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
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
}

enum FriendPactStatusType {
  waitingForPactEvidence,
  waitingForConsequenceEvidence,
  waitingForApproval,
  failedToComplete,
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

class _FriendStatusEntry {
  const _FriendStatusEntry({required this.friend, required this.status});

  final UserModel friend;
  final FriendPactStatus status;
}

class FriendPactCard extends StatelessWidget {
  const FriendPactCard({
    super.key,
    required this.friend,
    required this.currentUserId,
    required this.status,
    this.onCardTap,
    this.onMessageTap,
    this.onStatusTap,
  });

  static final FirestoreService _firestoreService = FirestoreService();

  final UserModel friend;
  final String currentUserId;
  final FriendPactStatus status;
  final VoidCallback? onCardTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onStatusTap;

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
      borderRadius: BorderRadius.circular(AppElevation.radiusMedium),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(imageUrl: friend.profilePictureUrl, radius: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSmall.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          style: AppTypography.bodySmall.copyWith(
                            color: secondary,
                          ),
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
            StreamBuilder<List<PactModel>>(
              stream: _firestoreService.streamUserPacts(friend.userId),
              builder: (context, pactSnapshot) {
                final pactStats = _derivePactStats(
                  pactSnapshot.data ?? const <PactModel>[],
                );
                return Row(
                  children: [
                    _FriendStat(label: 'Streak', value: '${pactStats.streak}'),
                    const SizedBox(width: 24),
                    _FriendStat(
                      label: 'Completed',
                      value: '${pactStats.completed}',
                    ),
                    const SizedBox(width: 24),
                    _FriendStat(label: 'Failed', value: '${pactStats.failed}'),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            FriendPactStatusLabel(status: status, onTap: onStatusTap),
          ],
        ),
      ),
    );
  }

  _FriendPactStats _derivePactStats(List<PactModel> pacts) {
    final completed = pacts
        .where((pact) => pact.status == PactStatus.completed)
        .length;
    final failed = pacts
        .where((pact) => pact.status == PactStatus.failed)
        .length;

    final finished =
        pacts
            .where(
              (pact) =>
                  pact.status == PactStatus.completed ||
                  pact.status == PactStatus.failed,
            )
            .toList()
          ..sort((a, b) => b.deadline.compareTo(a.deadline));

    var streak = 0;
    for (final pact in finished) {
      if (pact.status == PactStatus.completed) {
        streak += 1;
      } else {
        break;
      }
    }

    return _FriendPactStats(
      streak: streak,
      completed: completed,
      failed: failed,
    );
  }
}

class _FriendPactStats {
  const _FriendPactStats({
    required this.streak,
    required this.completed,
    required this.failed,
  });

  final int streak;
  final int completed;
  final int failed;
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
  const FriendPactStatusLabel({super.key, required this.status, this.onTap});

  final FriendPactStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(status.type);

    return InkWell(
      borderRadius: BorderRadius.circular(AppElevation.radiusMedium),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(AppElevation.radiusMedium),
          border: Border.all(color: visual.border),
        ),
        child: Row(
          children: [
            Icon(visual.icon, size: 18, color: visual.foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                status.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: visual.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: visual.foreground),
          ],
        ),
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
      case FriendPactStatusType.waitingForPactEvidence:
        return _StatusVisual(
          foreground: AppColors.warning,
          background: AppColors.warning.withValues(alpha: 0.15),
          border: AppColors.warning.withValues(alpha: 0.35),
          icon: Icons.schedule,
        );
      case FriendPactStatusType.waitingForConsequenceEvidence:
        return _StatusVisual(
          foreground: AppColors.primary,
          background: AppColors.primary.withValues(alpha: 0.14),
          border: AppColors.primary.withValues(alpha: 0.35),
          icon: Icons.warning_amber_rounded,
        );
      case FriendPactStatusType.waitingForApproval:
        return _StatusVisual(
          foreground: Colors.blue,
          background: Colors.blue.withValues(alpha: 0.12),
          border: Colors.blue.withValues(alpha: 0.35),
          icon: Icons.verified_outlined,
        );
      case FriendPactStatusType.failedToComplete:
        return _StatusVisual(
          foreground: AppColors.primary,
          background: AppColors.primary.withValues(alpha: 0.12),
          border: AppColors.primary.withValues(alpha: 0.35),
          icon: Icons.error_outline,
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
