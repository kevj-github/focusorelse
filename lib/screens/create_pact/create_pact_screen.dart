import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../widgets/common/app_button.dart';

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
  final TextEditingController _verifierController = TextEditingController();

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

  List<String> _friendUserIds = [];
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
    _verifierController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendUserIds() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      setState(() {
        _friendUserIds = [];
        _loadingFriends = false;
        _selectedVerificationMethod = CreateVerificationMethod.ai;
      });
      return;
    }

    try {
      final friendIds = await _firestoreService.getAcceptedFriendUserIds(
        userId,
      );
      if (!mounted) return;

      setState(() {
        _friendUserIds = friendIds;
        _loadingFriends = false;
        _selectedVerificationMethod = _friendUserIds.isNotEmpty
            ? CreateVerificationMethod.friend
            : CreateVerificationMethod.ai;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _friendUserIds = [];
        _loadingFriends = false;
        _selectedVerificationMethod = CreateVerificationMethod.ai;
      });
    }
  }

  bool get _hasFriends => _friendUserIds.isNotEmpty;

  bool get _isFriendVerification =>
      _selectedVerificationMethod == CreateVerificationMethod.friend;

  bool get _isVerifierValid {
    if (!_isFriendVerification) return true;
    return _friendUserIds.contains(_verifierController.text.trim());
  }

  List<String> get _matchingVerifierSuggestions {
    final query = _verifierController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _friendUserIds.take(5).toList();
    }

    return _friendUserIds
        .where((id) => id.toLowerCase().contains(query))
        .take(5)
        .toList();
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
    if (_verifierController.text.trim().isEmpty) {
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
    setState(() {
      _attemptedSubmit = true;
    });

    if (!_isFormValid) return;

    final authProvider = context.read<AuthProvider>();
    final pactProvider = context.read<PactProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null ||
        _selectedDeadline == null ||
        _selectedConsequence == null) {
      return;
    }

    final verificationType = _isFriendVerification
        ? VerificationType.friendVerify
        : VerificationType.aiVerify;

    final verifierId = _isFriendVerification
        ? _verifierController.text.trim()
        : null;

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

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: const Text(
          'Create Pact',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                    AppColors.primary.withOpacity(0.14),
                    AppColors.darkBackground,
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
                  color: AppColors.accent.withOpacity(0.08),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isSuccess
                ? _buildSuccessState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _SectionCard(
                        title: 'Task',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _taskController,
                              maxLength: _taskMaxLength,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white),
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
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Category',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
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
                      const SizedBox(height: 12),
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
                            const SizedBox(height: 8),
                            const Text(
                              'Deadline must be at least 1 hour from current time.',
                              style: TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 12,
                              ),
                            ),
                            if (_errorForDeadline() != null)
                              _InlineError(message: _errorForDeadline()!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Verification Method',
                        child: DropdownButtonFormField<CreateVerificationMethod>(
                          value: _selectedVerificationMethod,
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
                                      _verifierController.clear();
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
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Friend Proof Type',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
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
                                    selectedColor: AppColors.primary
                                        .withOpacity(0.22),
                                    side: BorderSide(
                                      color: _selectedFriendProofType == type
                                          ? AppColors.primary
                                          : AppColors.darkBorder,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Verifier',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _verifierController,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Verifier user ID',
                                  suffixIcon: Icon(
                                    Icons.person_search_outlined,
                                  ),
                                ),
                              ),
                              if (_matchingVerifierSuggestions.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkBackground.withOpacity(
                                      0.7,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.darkBorder,
                                    ),
                                  ),
                                  child: Column(
                                    children: _matchingVerifierSuggestions
                                        .map(
                                          (suggestedId) => ListTile(
                                            dense: true,
                                            title: Text(
                                              suggestedId,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _verifierController.text =
                                                    suggestedId;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              if (_errorForVerifier() != null)
                                _InlineError(message: _errorForVerifier()!),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Consequence',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<ConsequenceType>(
                              value: _selectedConsequence,
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
                      const SizedBox(height: 12),
                      _SectionCard(title: 'Review', child: _buildReview()),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Seal Pact',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Final submission is non-editable after submit.',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onLongPress: pactProvider.isLoading
                                  ? null
                                  : _sealPact,
                              child: Container(
                                height: 78,
                                decoration: BoxDecoration(
                                  gradient: _isFormValid
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.accent,
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            AppColors.darkBorder,
                                            AppColors.darkBorder,
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
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
                            const SizedBox(height: 8),
                            const Text(
                              'Long-press the fingerprint to seal your pact.',
                              style: TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 12,
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
      if (_isFriendVerification)
        MapEntry(
          'Verifier',
          _verifierController.text.trim().isEmpty
              ? 'Not set'
              : _verifierController.text.trim(),
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 102,
                    child: Text(
                      row.key,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(color: Colors.white),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Pact Sealed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your pact is live. Stay accountable and submit evidence before the deadline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Back to Dashboard',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.35),
            AppColors.accent.withOpacity(0.25),
            AppColors.darkBorder,
          ],
        ),
      ),
      padding: const EdgeInsets.all(1.1),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.darkBorder.withOpacity(0.75)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
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
