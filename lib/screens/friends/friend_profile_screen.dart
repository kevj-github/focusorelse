import 'package:flutter/material.dart';

import '../../models/pact_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: _FriendProfileHeaderCard(
                friend: widget.friend,
                onMessage: openMessage,
                onUnfriend: unfriend,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: onSurface,
                unselectedLabelColor: secondary,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.primary, width: 3),
                  insets: EdgeInsets.symmetric(horizontal: 28),
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
                            style: TextStyle(color: secondary),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: posts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
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
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            AppAvatar(imageUrl: friend.profilePictureUrl, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friend.displayName ?? friend.username ?? 'Friend',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((friend.username ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${friend.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    (friend.bio ?? '').trim().isEmpty
                        ? 'No bio yet.'
                        : friend.bio!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                  horizontal: 10,
                  vertical: 8,
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

    final successRate = widget.pacts.isEmpty
        ? 0.0
        : (completedPacts.length / widget.pacts.length) * 100;

    final avgLeadHours = _averageCompletionLeadHours(completedPacts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: _FriendMetricBlock(
                  title: 'Streak',
                  value: '${widget.user.stats.currentStreak} day',
                  subtitle: 'Current',
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                  value: '${widget.user.stats.longestStreak} day',
                  subtitle: 'Best',
                ),
              ),
            ),
            const SizedBox(width: 10),
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
        const SizedBox(height: 10),
        AppCard(
          child: _FriendMetricBlock(
            title: 'Avg Completion Lead Time',
            value: '${avgLeadHours.toStringAsFixed(1)} hr',
            subtitle: 'Before deadline',
          ),
        ),
        const SizedBox(height: 12),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _friendBorderColor(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _friendSecondaryTextColor(context),
            fontSize: 12,
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
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: _friendSecondaryTextColor(context),
            fontSize: 12,
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
