import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/pact_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_card.dart';
import '../pacts/pact_details_screen.dart';

class VerifierPactsScreen extends StatefulWidget {
  const VerifierPactsScreen({
    super.key,
    required this.currentUserId,
    required this.friend,
  });

  final String currentUserId;
  final UserModel friend;

  @override
  State<VerifierPactsScreen> createState() => _VerifierPactsScreenState();
}

class _VerifierPactsScreenState extends State<VerifierPactsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verifier Pacts',
          style: AppTypography.titleMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'From ${widget.friend.displayName ?? widget.friend.username ?? 'Friend'}',
                style: AppTypography.bodyMedium.copyWith(
                  color: secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTabs(),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StreamBuilder<List<PactModel>>(
              stream: _firestoreService.streamPactsForVerifierByFriend(
                verifierId: widget.currentUserId,
                friendId: widget.friend.userId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final pacts = snapshot.data ?? const <PactModel>[];
                final filtered = _tabIndex == 0
                    ? pacts.where(_isActiveVerifierPact).toList()
                    : pacts.where(_isHistoryVerifierPact).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _tabIndex == 0
                          ? 'No active verifier pacts.'
                          : 'No verifier history yet.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: secondary,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  itemBuilder: (context, index) {
                    final pact = filtered[index];
                    return InkWell(
                      borderRadius: AppElevation.cardRadius,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PactDetailsScreen(
                              pactId: pact.pactId,
                              initialPact: pact,
                            ),
                          ),
                        );
                      },
                      child: AppCard(
                        variant: AppCardVariant.outlined,
                        padding: const EdgeInsets.all(AppSpacing.md),
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
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    DateFormat(
                                      'EEE, MMM d • h:mm a',
                                    ).format(pact.deadline),
                                    style: AppTypography.caption.copyWith(
                                      color: secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _StatusChip(pact: pact),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemCount: filtered.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        variant: AppCardVariant.outlined,
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            _tabButton(label: 'Active', index: 0),
            _tabButton(label: 'History', index: 1),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({required String label, required int index}) {
    final selected = _tabIndex == index;
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppElevation.radiusSmall),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelLarge.copyWith(
              color: selected ? Colors.white : secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  bool _isActiveVerifierPact(PactModel pact) {
    if (pact.status == PactStatus.verificationPending) {
      return true;
    }
    if (pact.status == PactStatus.failed &&
        pact.consequenceStatus == ConsequenceStatus.pendingApproval) {
      return true;
    }
    if (pact.status == PactStatus.active) {
      return true;
    }
    return false;
  }

  bool _isHistoryVerifierPact(PactModel pact) {
    return !_isActiveVerifierPact(pact);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.pact});

  final PactModel pact;

  @override
  Widget build(BuildContext context) {
    final label = _label();
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppElevation.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _label() {
    if (pact.status == PactStatus.verificationPending) {
      return 'Waiting Approval';
    }
    if (pact.status == PactStatus.failed) {
      switch (pact.consequenceStatus) {
        case ConsequenceStatus.pendingSubmission:
          return 'Failed - Due';
        case ConsequenceStatus.pendingApproval:
          return 'Consequence Review';
        case ConsequenceStatus.rejected:
          return 'Consequence Rejected';
        case ConsequenceStatus.approved:
          return 'Failed Closed';
        case ConsequenceStatus.none:
          return 'Failed';
      }
    }
    if (pact.status == PactStatus.completed) {
      return 'Completed';
    }
    return 'Waiting Evidence';
  }

  Color _color() {
    if (pact.status == PactStatus.verificationPending) {
      return AppColors.warning;
    }
    if (pact.status == PactStatus.failed) {
      switch (pact.consequenceStatus) {
        case ConsequenceStatus.pendingSubmission:
          return AppColors.primary;
        case ConsequenceStatus.pendingApproval:
          return Colors.blue;
        case ConsequenceStatus.rejected:
          return AppColors.accent;
        case ConsequenceStatus.approved:
          return AppColors.textSecondaryDark;
        case ConsequenceStatus.none:
          return AppColors.accent;
      }
    }
    if (pact.status == PactStatus.completed) {
      return AppColors.success;
    }
    return AppColors.primary;
  }
}
