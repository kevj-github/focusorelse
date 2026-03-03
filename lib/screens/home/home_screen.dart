import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final pactProvider = Provider.of<PactProvider>(context);
    final user = authProvider.userModel;

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
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.darkSurface,
              backgroundImage: user?.profilePictureUrl != null
                  ? NetworkImage(user!.profilePictureUrl!)
                  : null,
              child: user?.profilePictureUrl == null
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
          _buildDashboard(authProvider, pactProvider),
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
        onPlusTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create pact feature coming soon!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(AuthProvider authProvider, PactProvider pactProvider) {
    final user = authProvider.userModel;
    final activePacts = pactProvider.activePacts;
    final pactsToVerify = pactProvider.pactsToVerify;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
            'Welcome back, ${user?.displayName ?? user?.username ?? 'User'} 👋',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Stay focused and close your commitments.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accountability Snapshot',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Active Pacts',
                        activePacts.length.toString(),
                        Icons.task_alt,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Completion',
                        '${(user?.stats.completionRate ?? 0).toStringAsFixed(0)}%',
                        Icons.trending_up,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Streak',
                        '${user?.stats.currentStreak ?? 0} days',
                        Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Create pact flow coming soon.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.darkBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New Pact'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.darkBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Friends'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Pacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (activePacts.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  child: const Text(
                    'Go to Feed',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (activePacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 44,
                      color: AppColors.textSecondaryDark,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No active pacts yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Start your first pact to build momentum and streak.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activePacts.take(3).map((pact) => _buildPactCard(pact)),

          if (pactsToVerify.isNotEmpty) ...[
            const SizedBox(height: 26),
            const Row(
              children: [
                Icon(Icons.verified_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Pending Verifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...pactsToVerify
                .take(3)
                .map((pact) => _buildPactCard(pact, isVerification: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPactCard(dynamic pact, {bool isVerification = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerification
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.darkBorder,
        ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isVerification)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VERIFY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: AppColors.textSecondaryDark,
              ),
              const SizedBox(width: 4),
              Text(
                pact.timeRemainingFormatted,
                style: TextStyle(
                  fontSize: 14,
                  color: pact.isOverdue
                      ? AppColors.primary
                      : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ],
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
