import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/pact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../create_pact/create_pact_screen.dart';
import '../../theme/colors.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pactProvider = Provider.of<PactProvider>(context, listen: false);

    if (authProvider.firebaseUser != null) {
      final userId = authProvider.firebaseUser!.uid;
      pactProvider.loadActivePacts(userId);
      pactProvider.loadCompletedPacts(userId);
      pactProvider.loadPactsToVerify(userId);
    }
  }

  Future<void> _openCreatePactFlow() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreatePactScreen()));

    if (!mounted) return;

    if (created == true) {
      _loadUserData();
      setState(() {
        _selectedIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pact created successfully.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Focus or Else',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.darkSurface,
              backgroundImage: authProvider.userModel?.profilePictureUrl != null
                  ? NetworkImage(authProvider.userModel!.profilePictureUrl!)
                  : null,
              child: authProvider.userModel?.profilePictureUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.textSecondaryDark,
                    )
                  : null,
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const _DashboardTabView(),
          _buildFeedView(),
          _buildFriendsView(),
          _buildProfileView(authProvider),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        onPlusTap: _openCreatePactFlow,
      ),
    );
  }

  Widget _buildFeedView() {
    return const Center(
      child: Text(
        'Feed View - Coming Soon',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildFriendsView() {
    return const Center(
      child: Text(
        'Friends View - Coming Soon',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildProfileView(AuthProvider authProvider) {
    final user = authProvider.userModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.darkSurface,
            backgroundImage: user?.profilePictureUrl != null
                ? NetworkImage(user!.profilePictureUrl!)
                : null,
            child: user?.profilePictureUrl == null
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.textSecondaryDark,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? user?.username ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _DashboardTabView extends StatefulWidget {
  const _DashboardTabView();

  @override
  State<_DashboardTabView> createState() => _DashboardTabViewState();
}

class _DashboardTabViewState extends State<_DashboardTabView> {
  int _dashboardTabIndex = 0;
  DateTime _visibleMonth = DateTime.now();
  late DateTime _selectedDate;
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _countdownTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final pactProvider = Provider.of<PactProvider>(context);

    final activePacts = List<PactModel>.from(pactProvider.activePacts)
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final expiredPacts = List<PactModel>.from(pactProvider.completedPacts)
      ..sort((a, b) => b.deadline.compareTo(a.deadline));

    final selectedPacts = _dashboardTabIndex == 0 ? activePacts : expiredPacts;

    final PactModel? featuredPact =
        _dashboardTabIndex == 0 && activePacts.isNotEmpty
        ? activePacts.first
        : null;

    final List<PactModel> upcomingPacts = _dashboardTabIndex == 0
        ? activePacts.skip(1).toList()
        : expiredPacts;
    final pactMarkers = _buildCalendarMarkerMap(
      activePacts: activePacts,
      expiredPacts: expiredPacts,
    );

    final bool isLoading = pactProvider.isLoading && selectedPacts.isEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, -1.0),
                radius: 1.15,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.darkBackground,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 220,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final uid = authProvider.firebaseUser?.uid;
            if (uid != null) {
              pactProvider.loadActivePacts(uid);
              pactProvider.loadCompletedPacts(uid);
              pactProvider.loadPactsToVerify(uid);
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              _buildHeroHeader(
                name:
                    authProvider.userModel?.displayName ??
                    authProvider.userModel?.username ??
                    'User',
              ),
              const SizedBox(height: 20),
              _buildDashboardTabs(),
              const SizedBox(height: 16),
              _buildCalendarCard(
                pactMarkers,
                activePacts: activePacts,
                expiredPacts: expiredPacts,
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (pactProvider.errorMessage != null &&
                  selectedPacts.isEmpty)
                _buildErrorState(context, pactProvider)
              else if (selectedPacts.isEmpty)
                _buildEmptyState()
              else ...[
                if (featuredPact != null) ...[
                  _buildSectionTitle('Featured Active Pact'),
                  const SizedBox(height: 12),
                  _buildFeaturedPactCard(context, featuredPact),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle(
                  _dashboardTabIndex == 0 ? 'Upcoming Pacts' : 'Expired Pacts',
                ),
                const SizedBox(height: 12),
                ...upcomingPacts
                    .take(6)
                    .map(
                      (pact) => _buildUpcomingPactCard(
                        pact,
                        showOverdue: _dashboardTabIndex == 0,
                      ),
                    ),
                if (upcomingPacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Text(
                      _dashboardTabIndex == 0
                          ? 'No additional upcoming pacts.'
                          : 'No expired/completed pacts yet.',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          _buildTabButton(label: 'Active', index: 0),
          _buildTabButton(label: 'Expired', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String label, required int index}) {
    final isSelected = _dashboardTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _dashboardTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.26),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(
    Map<String, _CalendarDayMarker> pactMarkers, {
    required List<PactModel> activePacts,
    required List<PactModel> expiredPacts,
  }) {
    final monthLabel = DateFormat('MMMM').format(_visibleMonth);
    final weekdayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = _buildMonthCells(_visibleMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.95)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _buildCalendarArrow(
                icon: Icons.chevron_left,
                onTap: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              const SizedBox(width: 6),
              _buildCalendarArrow(
                icon: Icons.chevron_right,
                onTap: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final isCurrentMonth = day.month == _visibleMonth.month;
              final isSelected = _isSameDay(day, _selectedDate);
              final marker = pactMarkers[_dateKey(day)];
              final hasActiveDeadline = marker?.hasActive ?? false;
              final hasExpiredDeadline = marker?.hasExpired ?? false;

              final cellBackground = isSelected
                  ? AppColors.primary
                  : hasActiveDeadline
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent;

              final cellBorder = hasExpiredDeadline && !hasActiveDeadline
                  ? Border.all(color: AppColors.accent.withValues(alpha: 0.5))
                  : null;

              final dayTextColor = isSelected
                  ? Colors.white
                  : hasActiveDeadline
                  ? Colors.white
                  : isCurrentMonth
                  ? Colors.white
                  : AppColors.textSecondaryDark.withValues(alpha: 0.5);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                    _visibleMonth = DateTime(day.year, day.month, 1);
                  });

                  if (marker != null) {
                    _showPactsForDay(
                      day,
                      activePacts: activePacts,
                      expiredPacts: expiredPacts,
                    );
                  }
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cellBackground,
                      border: cellBorder,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: dayTextColor,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (marker != null)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : hasActiveDeadline
                                  ? AppColors.primary
                                  : AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Map<String, _CalendarDayMarker> _buildCalendarMarkerMap({
    required List<PactModel> activePacts,
    required List<PactModel> expiredPacts,
  }) {
    final markerMap = <String, _CalendarDayMarker>{};

    for (final pact in activePacts) {
      final key = _dateKey(pact.deadline);
      final existing = markerMap[key];
      markerMap[key] = _CalendarDayMarker(
        hasActive: true,
        hasExpired: existing?.hasExpired ?? false,
        count: (existing?.count ?? 0) + 1,
      );
    }

    for (final pact in expiredPacts) {
      final key = _dateKey(pact.deadline);
      final existing = markerMap[key];
      markerMap[key] = _CalendarDayMarker(
        hasActive: existing?.hasActive ?? false,
        hasExpired: true,
        count: (existing?.count ?? 0) + 1,
      );
    }

    return markerMap;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<DateTime> _buildMonthCells(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final gridStart = firstDayOfMonth.subtract(
      Duration(days: firstWeekdayOffset),
    );

    return List<DateTime>.generate(
      42,
      (index) =>
          DateTime(gridStart.year, gridStart.month, gridStart.day + index),
    );
  }

  Future<void> _showPactsForDay(
    DateTime day, {
    required List<PactModel> activePacts,
    required List<PactModel> expiredPacts,
  }) async {
    final dayPacts = <PactModel>[
      ...activePacts.where((pact) => _isSameDay(pact.deadline, day)),
      ...expiredPacts.where((pact) => _isSameDay(pact.deadline, day)),
    ]..sort((a, b) => a.deadline.compareTo(b.deadline));

    if (dayPacts.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dayLabel = DateFormat('EEE, MMM d').format(day);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  'Pacts on $dayLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dayPacts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final pact = dayPacts[index];
                      final isActive = pact.status == PactStatus.active;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pact.taskDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('h:mm a').format(pact.deadline),
                                    style: const TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(
                              label: isActive ? 'ACTIVE' : 'EXPIRED',
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.accent,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildFeaturedPactCard(BuildContext context, PactModel pact) {
    final isOverdue = pact.isOverdue;
    final countdownText = pact.timeRemainingFormatted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue ? AppColors.primary : AppColors.darkBorder,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pact.taskDescription,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(
                label: isOverdue ? 'OVERDUE' : 'ACTIVE',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Deadline: ${DateFormat('EEE, MMM d • h:mm a').format(pact.deadline)}',
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: isOverdue
                    ? AppColors.primary
                    : AppColors.textSecondaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                isOverdue ? 'Overdue — action required' : countdownText,
                style: TextStyle(
                  color: isOverdue ? AppColors.primary : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Evidence submission flow coming soon.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Submit Evidence'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildUpcomingPactCard(PactModel pact, {required bool showOverdue}) {
    final isOverdue = pact.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: showOverdue && isOverdue
              ? AppColors.primary
              : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pact.taskDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('MMM d • h:mm a').format(pact.deadline),
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: showOverdue && isOverdue
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.darkBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              showOverdue && isOverdue
                  ? 'OVERDUE'
                  : pact.timeRemainingFormatted,
              style: TextStyle(
                color: showOverdue && isOverdue
                    ? AppColors.primary
                    : AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PactProvider pactProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            pactProvider.errorMessage ?? 'Unable to load pacts.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              final uid = Provider.of<AuthProvider>(
                context,
                listen: false,
              ).firebaseUser?.uid;
              if (uid != null) {
                pactProvider.loadActivePacts(uid);
                pactProvider.loadCompletedPacts(uid);
                pactProvider.loadPactsToVerify(uid);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isActive = _dashboardTabIndex == 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.flag_outlined : Icons.history,
            size: 42,
            color: AppColors.textSecondaryDark,
          ),
          const SizedBox(height: 12),
          Text(
            isActive ? 'No active pacts right now' : 'No expired pacts yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? 'Create a pact to start your countdown and stay accountable.'
                : 'Completed and expired pacts will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildHeroHeader({required String name}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkSurface.withValues(alpha: 0.35),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back, $name',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayMarker {
  const _CalendarDayMarker({
    required this.hasActive,
    required this.hasExpired,
    required this.count,
  });

  final bool hasActive;
  final bool hasExpired;
  final int count;
}
