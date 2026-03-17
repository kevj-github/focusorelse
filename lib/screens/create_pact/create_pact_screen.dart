import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pact_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/avatar.dart';

enum CreateVerificationMethod { friend, ai }

enum FriendProofType { photos, videos, both }

class CreatePactScreen extends StatefulWidget {
  const CreatePactScreen({super.key});

  @override
  State<CreatePactScreen> createState() => _CreatePactScreenState();
}

class _CreatePactScreenState extends State<CreatePactScreen> {
  static const int _taskMaxLength = 150;

  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _taskController = TextEditingController();

  final List<String> _categories = const [
    'Study',
    'Fitness',
    'Work',
    'Health',
    'Personal',
  ];

  String? _selectedCategory;
  DateTime? _selectedDeadline;
  CreateVerificationMethod _selectedVerificationMethod =
      CreateVerificationMethod.ai;
  FriendProofType _selectedFriendProofType = FriendProofType.both;
  ConsequenceType? _selectedConsequence;

  List<UserModel> _friendUsers = [];
  String? _selectedVerifierUserId;
  bool _loadingFriends = true;
  bool _attemptedSubmit = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadFriendUserIds();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendUserIds() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      setState(() {
        _friendUsers = [];
        _selectedVerifierUserId = null;
        _loadingFriends = false;
        _selectedVerificationMethod = CreateVerificationMethod.ai;
      });
      return;
    }

    try {
      final friendIds = await _firestoreService.getAcceptedFriendUserIds(
        userId,
      );
      final friendUsers = await _firestoreService.getUsersByIds(friendIds);
      if (!mounted) return;

      final sortedFriendUsers = List<UserModel>.from(friendUsers)
        ..sort((a, b) {
          final aLabel = _userDisplayLabel(a).toLowerCase();
          final bLabel = _userDisplayLabel(b).toLowerCase();
          return aLabel.compareTo(bLabel);
        });

      setState(() {
        _friendUsers = sortedFriendUsers;
        _selectedVerifierUserId = sortedFriendUsers.isNotEmpty
            ? sortedFriendUsers.first.userId
            : null;
        _loadingFriends = false;
        _selectedVerificationMethod = _friendUsers.isNotEmpty
            ? CreateVerificationMethod.friend
            : CreateVerificationMethod.ai;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _friendUsers = [];
        _selectedVerifierUserId = null;
        _loadingFriends = false;
        _selectedVerificationMethod = CreateVerificationMethod.ai;
      });
    }
  }

  bool get _hasFriends => _friendUsers.isNotEmpty;

  bool get _isFriendVerification =>
      _selectedVerificationMethod == CreateVerificationMethod.friend;

  bool get _isVerifierValid {
    if (!_isFriendVerification) return true;
    return _selectedVerifierUserId != null &&
        _friendUsers.any((friend) => friend.userId == _selectedVerifierUserId);
  }

  bool get _isFormValid {
    final hasTask = _taskController.text.trim().isNotEmpty;
    final hasCategory = _selectedCategory != null;
    final hasDeadline = _selectedDeadline != null;
    final hasConsequence = _selectedConsequence != null;
    final hasVerifier = _isVerifierValid;

    return hasTask &&
        hasCategory &&
        hasDeadline &&
        hasConsequence &&
        hasVerifier;
  }

  String? _errorForTask() {
    if (!_attemptedSubmit) return null;
    if (_taskController.text.trim().isEmpty) {
      return 'Task is required.';
    }
    return null;
  }

  String? _errorForCategory() {
    if (!_attemptedSubmit) return null;
    if (_selectedCategory == null) {
      return 'Category is required.';
    }
    return null;
  }

  String? _errorForDeadline() {
    if (!_attemptedSubmit) return null;
    if (_selectedDeadline == null) {
      return 'Deadline is required.';
    }
    return null;
  }

  String? _errorForVerifier() {
    if (!_attemptedSubmit || !_isFriendVerification) return null;
    if (!_hasFriends) {
      return 'Add at least one friend before choosing friend verification.';
    }
    if ((_selectedVerifierUserId ?? '').isEmpty) {
      return 'Verifier is required.';
    }
    if (!_isVerifierValid) {
      return 'Verifier must be from your friend list.';
    }
    return null;
  }

  String? _errorForConsequence() {
    if (!_attemptedSubmit) return null;
    if (_selectedConsequence == null) {
      return 'Consequence is required.';
    }
    return null;
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final minDeadline = now.add(const Duration(hours: 1));
    final initialDate = _selectedDeadline?.isAfter(minDeadline) == true
        ? _selectedDeadline!
        : minDeadline;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDeadline,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (!mounted || pickedTime == null) return;

    final deadline = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (deadline.isBefore(minDeadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deadline must be at least 1 hour from now.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() {
      _selectedDeadline = deadline;
    });
  }

  Future<void> _sealPact() async {
    final pactProvider = context.read<PactProvider>();
    if (pactProvider.hasPendingConsequence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete and get verifier approval for your pending consequence before creating a new pact.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() {
      _attemptedSubmit = true;
    });

    if (!_isFormValid) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null ||
        _selectedDeadline == null ||
        _selectedConsequence == null) {
      return;
    }

    final verificationType = _isFriendVerification
        ? VerificationType.friendVerify
        : VerificationType.aiVerify;

    final verifierId = _isFriendVerification ? _selectedVerifierUserId : null;

    final createdPactId = await pactProvider.createPact(
      userId: userId,
      taskDescription: _taskController.text.trim(),
      deadline: _selectedDeadline!,
      verificationType: verificationType,
      verifierId: verifierId,
      consequenceType: _selectedConsequence!,
      consequenceDetails: {
        'category': _selectedCategory,
        'label': _consequenceLabel(_selectedConsequence!),
        'verificationMethod': _isFriendVerification
            ? 'friend_verification'
            : 'ai_verification',
        if (_isFriendVerification)
          'friendProofType': _friendProofLabel(_selectedFriendProofType),
      },
    );

    if (!mounted) return;

    if (createdPactId != null) {
      setState(() {
        _isSuccess = true;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pactProvider.errorMessage ?? 'Failed to create pact.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _verificationMethodLabel(CreateVerificationMethod method) {
    switch (method) {
      case CreateVerificationMethod.friend:
        return 'Friend Verification';
      case CreateVerificationMethod.ai:
        return 'AI Verification';
    }
  }

  String _friendProofLabel(FriendProofType type) {
    switch (type) {
      case FriendProofType.photos:
        return 'photos';
      case FriendProofType.videos:
        return 'videos';
      case FriendProofType.both:
        return 'both';
    }
  }

  String _consequenceLabel(ConsequenceType type) {
    switch (type) {
      case ConsequenceType.socialSharing:
        return 'Social Sharing';
      case ConsequenceType.donationChallenge:
        return 'Donation Challenge';
      case ConsequenceType.funnyPenalty:
        return 'Funny Penalty';
    }
  }

  String _deadlineLabel() {
    final deadline = _selectedDeadline;
    if (deadline == null) return 'Select a deadline';
    final date = '${deadline.month}/${deadline.day}/${deadline.year}';
    final time = TimeOfDay.fromDateTime(deadline).format(context);
    return '$date at $time';
  }

  @override
  Widget build(BuildContext context) {
    final pactProvider = context.watch<PactProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'Create Pact',
          style: AppTypography.titleMedium.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -1),
                  radius: 1.2,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.14),
                    background,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 90,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isSuccess
                ? _buildSuccessState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    children: [
                      if (pactProvider.hasPendingConsequence)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppElevation.radiusMedium,
                            ),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Pact creation is locked while a consequence is pending. Submit consequence evidence from your failed pact and wait for verifier approval.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      _SectionCard(
                        title: 'Task',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _taskController,
                              maxLength: _taskMaxLength,
                              maxLines: 3,
                              style: TextStyle(color: onSurface),
                              decoration: const InputDecoration(
                                labelText: 'What will you complete?',
                                helperText: 'Keep this clear and measurable.',
                              ),
                              onChanged: (_) {
                                if (_attemptedSubmit) {
                                  setState(() {});
                                }
                              },
                            ),
                            if (_errorForTask() != null)
                              _InlineError(message: _errorForTask()!),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Category',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              items: _categories
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Choose category',
                              ),
                            ),
                            if (_errorForCategory() != null)
                              _InlineError(message: _errorForCategory()!),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Deadline',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppButton(
                              label: _deadlineLabel(),
                              variant: AppButtonVariant.outline,
                              onPressed: _pickDeadline,
                              icon: const Icon(Icons.schedule),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Deadline must be at least 1 hour from current time.',
                              style: AppTypography.bodySmall.copyWith(
                                color: onSurface,
                              ),
                            ),
                            if (_errorForDeadline() != null)
                              _InlineError(message: _errorForDeadline()!),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Verification Method',
                        child: DropdownButtonFormField<CreateVerificationMethod>(
                          initialValue: _selectedVerificationMethod,
                          items: [
                            DropdownMenuItem<CreateVerificationMethod>(
                              value: CreateVerificationMethod.friend,
                              enabled: _hasFriends,
                              child: Text(
                                _hasFriends
                                    ? 'Friend Verification'
                                    : 'Friend Verification (Add friends first)',
                              ),
                            ),
                            const DropdownMenuItem<CreateVerificationMethod>(
                              value: CreateVerificationMethod.ai,
                              child: Text('AI Verification'),
                            ),
                          ],
                          onChanged: _loadingFriends
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  if (value ==
                                          CreateVerificationMethod.friend &&
                                      !_hasFriends) {
                                    return;
                                  }

                                  setState(() {
                                    _selectedVerificationMethod = value;
                                    if (value == CreateVerificationMethod.ai) {
                                      _selectedVerifierUserId = null;
                                    } else if (_selectedVerifierUserId ==
                                            null &&
                                        _friendUsers.isNotEmpty) {
                                      _selectedVerifierUserId =
                                          _friendUsers.first.userId;
                                    }
                                  });
                                },
                          decoration: InputDecoration(
                            labelText: 'Choose verification method',
                            helperText: _loadingFriends
                                ? 'Loading friend list...'
                                : (_hasFriends
                                      ? 'Friend verification available.'
                                      : 'No friends found. Use AI verification for now.'),
                          ),
                        ),
                      ),
                      if (_isFriendVerification) ...[
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Friend Proof Type',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: FriendProofType.values
                                .map(
                                  (type) => ChoiceChip(
                                    label: Text(_friendProofLabel(type)),
                                    selected: _selectedFriendProofType == type,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedFriendProofType = type;
                                      });
                                    },
                                    selectedColor: AppColors.primary.withValues(
                                      alpha: 0.22,
                                    ),
                                    side: BorderSide(
                                      color: _selectedFriendProofType == type
                                          ? AppColors.primary
                                          : borderColor,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Verifier',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _isVerifierValid
                                    ? _selectedVerifierUserId
                                    : null,
                                items: _friendUsers
                                    .map(
                                      (friend) => DropdownMenuItem<String>(
                                        value: friend.userId,
                                        child: _buildVerifierDropdownOption(
                                          friend,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                selectedItemBuilder: (context) {
                                  return _friendUsers
                                      .map(
                                        (friend) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _selectedVerifierCompactLabel(
                                              friend,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVerifierUserId = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Choose verifier username',
                                  helperText:
                                      'Only your accepted friends appear here.',
                                ),
                              ),
                              if (_errorForVerifier() != null)
                                _InlineError(message: _errorForVerifier()!),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Consequence',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<ConsequenceType>(
                              initialValue: _selectedConsequence,
                              items: ConsequenceType.values
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(_consequenceLabel(type)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedConsequence = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Select consequence',
                              ),
                            ),
                            if (_errorForConsequence() != null)
                              _InlineError(message: _errorForConsequence()!),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(title: 'Review', child: _buildReview()),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        title: 'Seal Pact',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Final submission is non-editable after submit.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            GestureDetector(
                              onLongPress:
                                  (pactProvider.isLoading ||
                                      pactProvider.hasPendingConsequence)
                                  ? null
                                  : _sealPact,
                              child: Container(
                                height: 78,
                                decoration: BoxDecoration(
                                  gradient:
                                      (_isFormValid &&
                                          !pactProvider.hasPendingConsequence)
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.accent,
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [borderColor, borderColor],
                                        ),
                                  borderRadius: BorderRadius.circular(
                                    AppElevation.radiusXl,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: pactProvider.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.fingerprint,
                                        color: Colors.white,
                                        size: 38,
                                      ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Long-press the fingerprint to seal your pact.',
                              style: AppTypography.bodySmall.copyWith(
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final rows = <MapEntry<String, String>>[
      MapEntry(
        'Task',
        _taskController.text.trim().isEmpty
            ? 'Not set'
            : _taskController.text.trim(),
      ),
      MapEntry('Category', _selectedCategory ?? 'Not set'),
      MapEntry(
        'Deadline',
        _selectedDeadline == null ? 'Not set' : _deadlineLabel(),
      ),
      MapEntry(
        'Verification',
        _verificationMethodLabel(_selectedVerificationMethod),
      ),
      if (_isFriendVerification)
        MapEntry('Friend Proof', _friendProofLabel(_selectedFriendProofType)),
      if (_isFriendVerification) MapEntry('Verifier', _selectedVerifierLabel()),
      MapEntry(
        'Consequence',
        _selectedConsequence == null
            ? 'Not set'
            : _consequenceLabel(_selectedConsequence!),
      ),
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 102,
                    child: Text(
                      row.key,
                      style: AppTypography.bodySmall.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: AppTypography.bodyMedium.copyWith(
                        color: onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSuccessState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondaryText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pact Sealed',
              style: AppTypography.headlineSmall.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your pact is live. Stay accountable and submit evidence before the deadline.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: secondaryText),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Back to Dashboard',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  String _selectedVerifierLabel() {
    if ((_selectedVerifierUserId ?? '').isEmpty) {
      return 'Not set';
    }

    final matches = _friendUsers.where(
      (friend) => friend.userId == _selectedVerifierUserId,
    );

    if (matches.isEmpty) {
      return 'Not set';
    }

    return _userDisplayLabel(matches.first);
  }

  Widget _buildVerifierDropdownOption(UserModel user) {
    final username = (user.username ?? '').trim();
    final displayName = (user.displayName ?? '').trim();

    return Row(
      children: [
        AppAvatar(imageUrl: user.profilePictureUrl, radius: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                username.isNotEmpty ? '@$username' : 'Unknown user',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (displayName.isNotEmpty)
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _selectedVerifierCompactLabel(UserModel user) {
    final username = (user.username ?? '').trim();
    if (username.isNotEmpty) {
      return '@$username';
    }

    final displayName = (user.displayName ?? '').trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }

    return 'Unknown user';
  }

  String _userDisplayLabel(UserModel user) {
    final username = (user.username ?? '').trim();
    final displayName = (user.displayName ?? '').trim();

    if (username.isNotEmpty && displayName.isNotEmpty) {
      return '@$username ($displayName)';
    }

    if (username.isNotEmpty) {
      return '@$username';
    }

    if (displayName.isNotEmpty) {
      return displayName;
    }

    return 'Unknown user';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.96 : 0.98,
    );
    final onSurface = colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.accent.withValues(alpha: 0.25),
            borderColor,
          ],
        ),
      ),
      padding: const EdgeInsets.all(1.1),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: borderColor.withValues(alpha: 0.75)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.primary, fontSize: 12),
      ),
    );
  }
}
