import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pact_model.dart';
import '../../models/post_comment_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/avatar.dart';
import '../messages/message_screen.dart';

enum _FriendStatsInterval { week, month, threeMonths }

enum _FriendChartMode { completed, failed, both }

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({
    super.key,
    required this.currentUserId,
    required this.friend,
  });

  final String currentUserId;
  final UserModel friend;

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  void _openFriendPostDetails(PostModel post) {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load your user session.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FriendPostViewerScreen(
          friend: widget.friend,
          post: post,
          currentUser: currentUser,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    Future<void> openMessage() async {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MessageScreen(
            currentUserId: widget.currentUserId,
            friend: widget.friend,
          ),
        ),
      );
    }

    Future<void> unfriend() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Unfriend?'),
            content: Text(
              'Remove ${widget.friend.displayName ?? widget.friend.username ?? 'this friend'} from your friend list?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Unfriend'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      try {
        final friendshipId = await firestoreService.getFriendshipIdBetween(
          widget.currentUserId,
          widget.friend.userId,
        );

        if (friendshipId == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friendship could not be found.'),
              backgroundColor: AppColors.primary,
            ),
          );
          return;
        }

        await firestoreService.removeFriend(friendshipId);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to unfriend right now.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: _FriendProfileHeaderCard(
                friend: widget.friend,
                onMessage: openMessage,
                onUnfriend: unfriend,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: onSurface,
                unselectedLabelColor: secondary,
                labelStyle: AppTypography.labelLarge,
                unselectedLabelStyle: AppTypography.labelLarge,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.primary, width: 3),
                  insets: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                ),
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Stats'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StreamBuilder<List<PostModel>>(
                    stream: firestoreService.streamUserPosts(
                      widget.friend.userId,
                    ),
                    builder: (context, snapshot) {
                      final posts = snapshot.data ?? const <PostModel>[];
                      if (posts.isEmpty) {
                        return Center(
                          child: Text(
                            'No posts yet.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: secondary,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        itemCount: posts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return InkWell(
                            onTap: () => _openFriendPostDetails(post),
                            child: _FriendPostGridTile(post: post),
                          );
                        },
                      );
                    },
                  ),
                  StreamBuilder<List<PactModel>>(
                    stream: firestoreService.streamUserPacts(
                      widget.friend.userId,
                    ),
                    builder: (context, snapshot) {
                      final pacts = snapshot.data ?? const <PactModel>[];

                      return _FriendProfileStatsTab(
                        user: widget.friend,
                        pacts: pacts,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendPostGridTile extends StatelessWidget {
  const _FriendPostGridTile({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'friend-post-${post.postId.isEmpty ? post.imageUrl : post.postId}',
      child: ColoredBox(
        color: Colors.black,
        child: Image.network(
          post.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: _friendSecondaryTextColor(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendPostViewerScreen extends StatefulWidget {
  const _FriendPostViewerScreen({
    required this.friend,
    required this.post,
    required this.currentUser,
  });

  final UserModel friend;
  final PostModel post;

  final UserModel currentUser;

  @override
  State<_FriendPostViewerScreen> createState() =>
      _FriendPostViewerScreenState();
}

class _FriendPostViewerScreenState extends State<_FriendPostViewerScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.read<PostProvider>();

    return StreamBuilder<PostModel?>(
      stream: postProvider.streamPost(widget.post.postId),
      initialData: widget.post,
      builder: (context, postSnapshot) {
        final currentPost = postSnapshot.data ?? widget.post;
        final username = _resolvedUsername(currentPost);
        final avatarUrl = _resolvedAvatarUrl(currentPost);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            titleSpacing: 0,
            title: Text(
              username,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(Icons.more_horiz),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            AppAvatar(imageUrl: avatarUrl, radius: 16),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                username,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.more_horiz,
                              color: _friendSecondaryTextColor(context),
                            ),
                          ],
                        ),
                      ),
                      Hero(
                        tag:
                            'friend-post-${currentPost.postId.isEmpty ? currentPost.imageUrl : currentPost.postId}',
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            currentPost.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: _friendSecondaryTextColor(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: Row(
                          children: [
                            StreamBuilder<bool>(
                              stream: postProvider.streamIsPostLiked(
                                postId: currentPost.postId,
                                userId: widget.currentUser.userId,
                              ),
                              initialData: false,
                              builder: (context, likedSnapshot) {
                                final isLiked = likedSnapshot.data ?? false;
                                return IconButton(
                                  onPressed:
                                      widget.currentUser.hasPendingConsequence
                                      ? null
                                      : _isTogglingLike
                                      ? null
                                      : () async {
                                          if (currentPost.postId.isEmpty) {
                                            return;
                                          }

                                          postProvider.clearError();
                                          setState(() {
                                            _isTogglingLike = true;
                                          });

                                          final success = await postProvider
                                              .togglePostLike(
                                                postId: currentPost.postId,
                                                userId:
                                                    widget.currentUser.userId,
                                              );

                                          if (!mounted) {
                                            return;
                                          }

                                          setState(() {
                                            _isTogglingLike = false;
                                          });

                                          if (success) {
                                            return;
                                          }

                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                postProvider.errorMessage ??
                                                    'Failed to update like. Please try again.',
                                              ),
                                              backgroundColor:
                                                  AppColors.primary,
                                            ),
                                          );
                                        },
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                    minWidth: 44,
                                  ),
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked
                                        ? AppColors.primary
                                        : (_isTogglingLike
                                              ? _friendSecondaryTextColor(
                                                  context,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface),
                                    size: 26,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              onPressed:
                                  widget.currentUser.hasPendingConsequence
                                  ? null
                                  : () => _commentFocusNode.requestFocus(),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minHeight: 44,
                                minWidth: 44,
                              ),
                              icon: Icon(
                                Icons.mode_comment_outlined,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          0,
                        ),
                        child: Text(
                          '${currentPost.likeCount} likes',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          0,
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: '$username ',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: currentPost.caption),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          0,
                        ),
                        child: Text(
                          _formatPostAge(currentPost.createdAt),
                          style: AppTypography.labelSmall.copyWith(
                            color: _friendSecondaryTextColor(context),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                        color: _friendBorderColor(context),
                        height: 1,
                        thickness: 1,
                      ),
                      StreamBuilder<List<PostCommentModel>>(
                        stream: postProvider.streamPostComments(
                          currentPost.postId,
                        ),
                        builder: (context, commentSnapshot) {
                          final comments = commentSnapshot.data ?? const [];

                          if (comments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.md,
                                AppSpacing.xs,
                              ),
                              child: Text(
                                'No comments yet. Start the conversation.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: _friendSecondaryTextColor(context),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final commentUsername =
                                  (comment.authorUsername?.trim().isNotEmpty ??
                                      false)
                                  ? comment.authorUsername!.trim()
                                  : comment.authorDisplayName
                                        .trim()
                                        .toLowerCase()
                                        .replaceAll(' ', '_');

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppAvatar(
                                    imageUrl: comment.authorProfilePictureUrl,
                                    radius: 14,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$commentUsername ',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          TextSpan(text: comment.text),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: Border(
                      top: BorderSide(color: _friendBorderColor(context)),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: widget.currentUser.hasPendingConsequence
                      ? Text(
                          'Comments are locked until your pending consequence is approved.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Row(
                          children: [
                            AppAvatar(
                              imageUrl: widget.currentUser.profilePictureUrl,
                              radius: 14,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocusNode,
                                minLines: 1,
                                maxLines: 3,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: AppTypography.bodyMedium.copyWith(
                                    color: _friendSecondaryTextColor(context),
                                  ),
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _isSubmittingComment
                                  ? null
                                  : () => _submitComment(currentPost.postId),
                              child: Text(
                                _isSubmittingComment ? 'Posting...' : 'Post',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolvedUsername(PostModel currentPost) {
    return (currentPost.authorUsername?.trim().isNotEmpty ?? false)
        ? currentPost.authorUsername!.trim()
        : currentPost.authorDisplayName.trim().toLowerCase().replaceAll(
            ' ',
            '_',
          );
  }

  String? _resolvedAvatarUrl(PostModel currentPost) {
    return currentPost.authorProfilePictureUrl;
  }

  Future<void> _submitComment(String postId) async {
    final postProvider = context.read<PostProvider>();
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    postProvider.clearError();

    setState(() {
      _isSubmittingComment = true;
    });

    final success = await postProvider.addPostComment(
      postId: postId,
      authorId: widget.currentUser.userId,
      authorDisplayName:
          widget.currentUser.displayName ??
          widget.currentUser.username ??
          'Focus User',
      authorUsername: widget.currentUser.username,
      authorProfilePictureUrl: widget.currentUser.profilePictureUrl,
      text: text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmittingComment = false;
    });

    if (success) {
      _commentController.clear();
      _commentFocusNode.unfocus();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          postProvider.errorMessage ??
              'Failed to post comment. Please try again.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _formatPostAge(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'JUST NOW';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}M AGO';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}H AGO';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}D AGO';
    }
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 5) {
      return '${weeks}W AGO';
    }
    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return '${months}MO AGO';
    }
    final years = (difference.inDays / 365).floor();
    return '${years}Y AGO';
  }
}

class _FriendProfileHeaderCard extends StatelessWidget {
  const _FriendProfileHeaderCard({
    required this.friend,
    required this.onMessage,
    required this.onUnfriend,
  });

  final UserModel friend;
  final Future<void> Function() onMessage;
  final Future<void> Function() onUnfriend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            AppAvatar(imageUrl: friend.profilePictureUrl, radius: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friend.displayName ?? friend.username ?? 'Friend',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((friend.username ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '@${friend.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    (friend.bio ?? '').trim().isEmpty
                        ? 'No bio yet.'
                        : friend.bio!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(color: secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'message') {
                  onMessage();
                }
                if (value == 'unfriend') {
                  onUnfriend();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'message', child: Text('Message')),
                PopupMenuItem(value: 'unfriend', child: Text('Unfriend')),
              ],
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                foregroundColor: onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -1,
                  vertical: -1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendProfileStatsTab extends StatefulWidget {
  const _FriendProfileStatsTab({required this.user, required this.pacts});

  final UserModel user;
  final List<PactModel> pacts;

  @override
  State<_FriendProfileStatsTab> createState() => _FriendProfileStatsTabState();
}

class _FriendProfileStatsTabState extends State<_FriendProfileStatsTab>
    with AutomaticKeepAliveClientMixin<_FriendProfileStatsTab> {
  _FriendStatsInterval _interval = _FriendStatsInterval.week;
  _FriendChartMode _mode = _FriendChartMode.both;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final completedPacts = widget.pacts
        .where((p) => p.status == PactStatus.completed)
        .toList();
    final currentStreak = _currentCompletionStreak(widget.pacts);
    final longestStreak = _longestCompletionStreak(widget.pacts);

    final successRate = widget.pacts.isEmpty
        ? 0.0
        : (completedPacts.length / widget.pacts.length) * 100;

    final avgLeadHours = _averageCompletionLeadHours(completedPacts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: _FriendMetricBlock(
                  title: 'Streak',
                  value: '$currentStreak day',
                  subtitle: 'Current',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: _FriendMetricBlock(
                  title: 'Success Rate',
                  value: '${successRate.toStringAsFixed(0)}%',
                  subtitle: '${completedPacts.length}/${widget.pacts.length}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: _FriendMetricBlock(
                  title: 'Longest Streak',
                  value: '$longestStreak day',
                  subtitle: 'Best',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: _FriendMetricBlock(
                  title: 'Total Completed',
                  value: '${completedPacts.length}',
                  subtitle: 'All time',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: _FriendMetricBlock(
            title: 'Avg Completion Lead Time',
            value: '${avgLeadHours.toStringAsFixed(1)} hr',
            subtitle: 'Before deadline',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pact Summary',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Interval',
                    style: TextStyle(
                      color: _friendSecondaryTextColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<_FriendStatsInterval>(
                      initialValue: _interval,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _friendBorderColor(context),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _friendBorderColor(context),
                          ),
                        ),
                      ),
                      dropdownColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      iconEnabledColor: _friendSecondaryTextColor(context),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _FriendStatsInterval.week,
                          child: Text('Week'),
                        ),
                        DropdownMenuItem(
                          value: _FriendStatsInterval.month,
                          child: Text('Month'),
                        ),
                        DropdownMenuItem(
                          value: _FriendStatsInterval.threeMonths,
                          child: Text('3 Months'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _interval = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FriendChoiceChip(
                    label: 'Completed',
                    selected: _mode == _FriendChartMode.completed,
                    onTap: () =>
                        setState(() => _mode = _FriendChartMode.completed),
                  ),
                  _FriendChoiceChip(
                    label: 'Failed',
                    selected: _mode == _FriendChartMode.failed,
                    onTap: () =>
                        setState(() => _mode = _FriendChartMode.failed),
                  ),
                  _FriendChoiceChip(
                    label: 'Both',
                    selected: _mode == _FriendChartMode.both,
                    onTap: () => setState(() => _mode = _FriendChartMode.both),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              RepaintBoundary(
                child: _FriendPactSummaryChart(
                  pacts: widget.pacts,
                  interval: _interval,
                  mode: _mode,
                ),
              ),
              if (_mode == _FriendChartMode.both) ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _FriendLegendDot(
                      color: AppColors.completed,
                      label: 'Completed',
                    ),
                    SizedBox(width: 12),
                    _FriendLegendDot(color: AppColors.accent, label: 'Failed'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  double _averageCompletionLeadHours(List<PactModel> completedPacts) {
    if (completedPacts.isEmpty) return 0;

    final leadDurations = completedPacts
        .where((p) => p.completedAt != null)
        .map((p) => p.deadline.difference(p.completedAt!))
        .where((d) => d.inMinutes >= 0)
        .toList();

    if (leadDurations.isEmpty) return 0;

    final totalMinutes = leadDurations.fold<int>(
      0,
      (sum, d) => sum + d.inMinutes,
    );

    return (totalMinutes / leadDurations.length) / 60;
  }

  int _currentCompletionStreak(List<PactModel> pacts) {
    final finished =
        pacts
            .where(
              (p) =>
                  p.status == PactStatus.completed ||
                  p.status == PactStatus.failed,
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
    return streak;
  }

  int _longestCompletionStreak(List<PactModel> pacts) {
    final finished =
        pacts
            .where(
              (p) =>
                  p.status == PactStatus.completed ||
                  p.status == PactStatus.failed,
            )
            .toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));

    var longest = 0;
    var current = 0;
    for (final pact in finished) {
      if (pact.status == PactStatus.completed) {
        current += 1;
        if (current > longest) {
          longest = current;
        }
      } else {
        current = 0;
      }
    }

    return longest;
  }
}

class _FriendMetricBlock extends StatelessWidget {
  const _FriendMetricBlock({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _friendSecondaryTextColor(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: _friendSecondaryTextColor(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _FriendChoiceChip extends StatelessWidget {
  const _FriendChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppElevation.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppElevation.radiusSmall),
          border: Border.all(color: _friendBorderColor(context)),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? Colors.white : _friendSecondaryTextColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FriendLegendDot extends StatelessWidget {
  const _FriendLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: _friendSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}

class _FriendPactSummaryChart extends StatelessWidget {
  const _FriendPactSummaryChart({
    required this.pacts,
    required this.interval,
    required this.mode,
  });

  final List<PactModel> pacts;
  final _FriendStatsInterval interval;
  final _FriendChartMode mode;

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();

    if (points.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No data for selected filter.',
            style: TextStyle(color: _friendSecondaryTextColor(context)),
          ),
        ),
      );
    }

    final maxValue = points.fold<int>(1, (max, p) {
      final value = mode == _FriendChartMode.completed
          ? p.completed
          : mode == _FriendChartMode.failed
          ? p.failed
          : (p.completed + p.failed);
      return value > max ? value : max;
    });

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final combined = p.completed + p.failed;
          final modeValue = mode == _FriendChartMode.completed
              ? p.completed
              : mode == _FriendChartMode.failed
              ? p.failed
              : combined;

          final totalHeight = modeValue == 0
              ? 8.0
              : (120 * (modeValue / maxValue)).clamp(8, 120).toDouble();

          final completedHeight = combined == 0
              ? 0.0
              : totalHeight * (p.completed / combined);
          final failedHeight = combined == 0
              ? 0.0
              : totalHeight - completedHeight;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$modeValue',
                    style: TextStyle(
                      color: _friendSecondaryTextColor(context),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: mode == _FriendChartMode.both
                        ? SizedBox(
                            height: totalHeight,
                            child: Column(
                              children: [
                                if (failedHeight > 0)
                                  Container(
                                    height: failedHeight,
                                    color: AppColors.accent,
                                  ),
                                if (completedHeight > 0)
                                  Container(
                                    height: completedHeight,
                                    color: AppColors.completed,
                                  ),
                              ],
                            ),
                          )
                        : Container(
                            height: totalHeight,
                            color: mode == _FriendChartMode.completed
                                ? AppColors.completed
                                : AppColors.accent,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.label,
                    style: TextStyle(
                      color: _friendSecondaryTextColor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_FriendChartPoint> _buildPoints() {
    final now = DateTime.now();

    if (interval == _FriendStatsInterval.week) {
      return List.generate(7, (index) {
        final day = DateTime(now.year, now.month, now.day - (6 - index));
        final completed = pacts.where((p) {
          return p.status == PactStatus.completed && _sameDay(p.deadline, day);
        }).length;
        final failed = pacts.where((p) {
          return p.status == PactStatus.failed && _sameDay(p.deadline, day);
        }).length;

        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final weekdayLabel = labels[day.weekday - 1];
        return _FriendChartPoint(weekdayLabel, completed, failed);
      });
    }

    if (interval == _FriendStatsInterval.month) {
      return List.generate(4, (index) {
        final end = DateTime(now.year, now.month, now.day - (3 - index) * 7);
        final start = end.subtract(const Duration(days: 6));

        final completed = pacts.where((p) {
          return p.status == PactStatus.completed &&
              !p.deadline.isBefore(start) &&
              !p.deadline.isAfter(end);
        }).length;

        final failed = pacts.where((p) {
          return p.status == PactStatus.failed &&
              !p.deadline.isBefore(start) &&
              !p.deadline.isAfter(end);
        }).length;

        return _FriendChartPoint('W${index + 1}', completed, failed);
      });
    }

    return List.generate(3, (index) {
      final monthDate = DateTime(now.year, now.month - (2 - index), 1);

      final completed = pacts.where((p) {
        return p.status == PactStatus.completed &&
            p.deadline.year == monthDate.year &&
            p.deadline.month == monthDate.month;
      }).length;

      final failed = pacts.where((p) {
        return p.status == PactStatus.failed &&
            p.deadline.year == monthDate.year &&
            p.deadline.month == monthDate.month;
      }).length;

      final labels = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final monthLabel = labels[monthDate.month - 1];
      return _FriendChartPoint(monthLabel, completed, failed);
    });
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _FriendChartPoint {
  const _FriendChartPoint(this.label, this.completed, this.failed);

  final String label;
  final int completed;
  final int failed;
}

Color _friendSecondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textSecondaryDark
      : AppColors.textSecondaryLight;
}

Color _friendBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkBorder
      : AppColors.lightBorder;
}
