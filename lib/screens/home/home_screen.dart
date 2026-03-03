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
              // TODO: Navigate to profile
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(authProvider, pactProvider),
          _buildFriendsView(),
          _buildPactsView(pactProvider),
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
        onCreateTap: () {
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
          // Welcome message
          Text(
            'Welcome back, ${user?.displayName ?? user?.username ?? 'User'}! 👋',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stay focused and achieve your goals',
            style: TextStyle(fontSize: 16, color: Color(0xFF9BA1A6)),
          ),
          const SizedBox(height: 32),

          // Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF2659).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Active Pacts',
                      activePacts.length.toString(),
                      Icons.task_alt,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF2D2D30),
                    ),
                    _buildStatItem(
                      'Completion',
                      '${(user?.stats.completionRate ?? 0).toStringAsFixed(0)}%',
                      Icons.trending_up,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF2D2D30),
                    ),
                    _buildStatItem(
                      'Streak',
                      '${user?.stats.currentStreak ?? 0} days',
                      Icons.local_fire_department,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Active pacts section
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
                      _selectedIndex = 2;
                    });
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Color(0xFFFF2659)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (activePacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.task_outlined,
                      size: 48,
                      color: const Color(0xFF9BA1A6).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No active pacts',
                      style: TextStyle(fontSize: 16, color: Color(0xFF9BA1A6)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first pact to get started!',
                      style: TextStyle(fontSize: 14, color: Color(0xFF9BA1A6)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activePacts.take(3).map((pact) => _buildPactCard(pact)),

          if (pactsToVerify.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Pending Verifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
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
        Icon(icon, color: const Color(0xFFFF2659), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9BA1A6)),
        ),
      ],
    );
  }

  Widget _buildPactCard(dynamic pact, {bool isVerification = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerification
              ? const Color(0xFFFF2659).withValues(alpha: 0.3)
              : const Color(0xFF2D2D30),
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
                    color: const Color(0xFFFF2659).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VERIFY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF2659),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Color(0xFF9BA1A6)),
              const SizedBox(width: 4),
              Text(
                pact.timeRemainingFormatted,
                style: TextStyle(
                  fontSize: 14,
                  color: pact.isOverdue
                      ? const Color(0xFFFF2659)
                      : const Color(0xFF9BA1A6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPactsView(PactProvider pactProvider) {
    return const Center(
      child: Text(
        'Pacts View - Coming Soon',
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
            backgroundColor: const Color(0xFF1E1E20),
            backgroundImage: user?.profilePictureUrl != null
                ? NetworkImage(user!.profilePictureUrl!)
                : null,
            child: user?.profilePictureUrl == null
                ? const Icon(Icons.person, size: 50, color: Color(0xFF9BA1A6))
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
            style: const TextStyle(fontSize: 14, color: Color(0xFF9BA1A6)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2659),
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
