import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/pact_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/avatar.dart';

class PactDetailsScreen extends StatefulWidget {
  const PactDetailsScreen({super.key, required this.pactId, this.initialPact});

  final String pactId;
  final PactModel? initialPact;

  @override
  State<PactDetailsScreen> createState() => _PactDetailsScreenState();
}

class _PactDetailsScreenState extends State<PactDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _submissionNoteController =
      TextEditingController();
  Timer? _ticker;
  bool _isSubmittingEvidence = false;
  bool _didSeedSubmissionNote = false;
  File? _selectedPhotoEvidence;
  File? _selectedVideoEvidence;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _submissionNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PactModel?>(
      stream: _firestoreService.streamPact(widget.pactId),
      builder: (context, snapshot) {
        final pact = snapshot.data ?? widget.initialPact;

        if (pact == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pact Details')),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final statusTheme = _statusThemeForPact(pact);
        final countdown = _formatCountdown(pact);
        final authProvider = context.watch<AuthProvider>();
        final currentUserId = authProvider.firebaseUser?.uid;
        final isOwner = currentUserId != null && currentUserId == pact.userId;
        final isVerifier =
            currentUserId != null &&
            pact.verifierId != null &&
            currentUserId == pact.verifierId;

        if (!_didSeedSubmissionNote) {
          _submissionNoteController.text = _submissionNoteFromPact(pact);
          _didSeedSubmissionNote = true;
        }

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Pact Details'),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -1.0),
                      radius: 1.25,
                      colors: [
                        statusTheme.main.withValues(alpha: 0.24),
                        AppColors.darkBackground,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDateBadge(pact, statusTheme),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMainCard(
                        pact: pact,
                        statusTheme: statusTheme,
                        countdownText: countdown,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildMetaCard(
                        pact: pact,
                        statusTheme: statusTheme,
                        isOwner: isOwner,
                        isVerifier: isVerifier,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildStakesCard(pact, statusTheme),
                      const SizedBox(height: AppSpacing.xl),
                      _buildActionArea(
                        pact: pact,
                        statusTheme: statusTheme,
                        isOwner: isOwner,
                        isVerifier: isVerifier,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateBadge(PactModel pact, _PactStatusTheme statusTheme) {
    final dayText = DateFormat('dd').format(pact.deadline);
    final monthYearText = DateFormat('MMM yyyy').format(pact.deadline);
    final weekdayText = DateFormat('EEEE').format(pact.deadline);

    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: statusTheme.main.withValues(alpha: 0.55),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: statusTheme.main.withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: statusTheme.main.withValues(alpha: 0.3),
                blurRadius: 52,
                spreadRadius: 7,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayText,
                style: AppTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                monthYearText,
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          weekdayText,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard({
    required PactModel pact,
    required _PactStatusTheme statusTheme,
    required String countdownText,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppElevation.radiusXl),
        border: Border.all(color: statusTheme.main.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: statusTheme.main.withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildPill(
                _statusLabel(pact).toUpperCase(),
                statusTheme.main,
                foregroundColor: Colors.white,
              ),
              _buildPill(
                _verificationLabel(pact.verificationType),
                Colors.white,
                foregroundColor: Colors.white,
                subtle: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            pact.taskDescription,
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 205,
              height: 205,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: statusTheme.main.withValues(alpha: 0.9),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusTheme.main.withValues(alpha: 0.27),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkBackground,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TIME LEFT',
                      style: AppTypography.label.copyWith(
                        color: statusTheme.main,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      countdownText,
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Deadline: ${DateFormat('h:mm a').format(pact.deadline)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Due by ${DateFormat('EEE, MMM d • h:mm a').format(pact.deadline)}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard({
    required PactModel pact,
    required _PactStatusTheme statusTheme,
    required bool isOwner,
    required bool isVerifier,
  }) {
    final roleLabel = isOwner
        ? 'Owner'
        : isVerifier
        ? 'Verifier'
        : 'Viewer';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  icon: Icons.flag,
                  title: 'Current Status',
                  value: _statusLabel(pact),
                  valueColor: statusTheme.main,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoTile(
                  icon: Icons.person,
                  title: 'Your Role',
                  value: roleLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVerifierTile(pact),
          if (pact.evidenceUrl != null && pact.evidenceUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildEvidenceIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildStakesCard(PactModel pact, _PactStatusTheme statusTheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: statusTheme.main),
              const SizedBox(width: 8),
              const Text(
                'CONSEQUENCE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _consequenceDescription(pact),
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea({
    required PactModel pact,
    required _PactStatusTheme statusTheme,
    required bool isOwner,
    required bool isVerifier,
  }) {
    final pactProvider = context.read<PactProvider>();
    final existingEvidenceUrl = pact.evidenceUrl;
    final hasLocalPreview =
        _selectedPhotoEvidence != null || _selectedVideoEvidence != null;
    final showNetworkPreview =
        !hasLocalPreview &&
        existingEvidenceUrl != null &&
        existingEvidenceUrl.isNotEmpty;
    final showConsequenceNetworkPreview =
        !hasLocalPreview &&
        pact.consequenceEvidenceUrl != null &&
        pact.consequenceEvidenceUrl!.isNotEmpty;
    final isConsequenceOwnerSubmission =
        isOwner &&
        pact.status == PactStatus.failed &&
        (pact.consequenceStatus == ConsequenceStatus.pendingSubmission ||
            pact.consequenceStatus == ConsequenceStatus.rejected ||
            pact.consequenceStatus == ConsequenceStatus.none);
    final isConsequenceVerifierReview =
        isVerifier &&
        pact.status == PactStatus.failed &&
        pact.consequenceStatus == ConsequenceStatus.pendingApproval;

    final notesCard = _buildSubmissionNotesCard(
      editable: isOwner && pact.status == PactStatus.active && !pact.isOverdue,
    );

    final evidencePreview = hasLocalPreview
        ? _buildLocalEvidencePreview()
        : (showNetworkPreview
              ? _buildNetworkEvidencePreview(existingEvidenceUrl)
              : null);
    final consequenceEvidencePreview = hasLocalPreview
        ? _buildLocalEvidencePreview()
        : (showConsequenceNetworkPreview
              ? _buildNetworkEvidencePreview(pact.consequenceEvidenceUrl)
              : null);
    final ownerEvidencePreview = isConsequenceOwnerSubmission
        ? (hasLocalPreview ? _buildLocalEvidencePreview() : null)
        : evidencePreview;

    if (pact.status == PactStatus.verificationPending && isVerifier) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          notesCard,
          if (evidencePreview != null) ...[
            const SizedBox(height: 10),
            evidencePreview,
          ],
          const SizedBox(height: 10),
          const Text(
            'Verification Required',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: pactProvider.isLoading
                ? null
                : () => _verifyPact(pact, approved: false),
            icon: const Icon(Icons.close),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            label: const Text('Reject Evidence'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: pactProvider.isLoading
                ? null
                : () => _verifyPact(pact, approved: true),
            icon: const Icon(Icons.check),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            label: const Text('Approve & Complete'),
          ),
        ],
      );
    }

    if (isConsequenceVerifierReview) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          notesCard,
          if (consequenceEvidencePreview != null) ...[
            const SizedBox(height: 10),
            consequenceEvidencePreview,
          ],
          const SizedBox(height: 10),
          const Text(
            'Consequence Review Required',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: pactProvider.isLoading
                ? null
                : () => _verifyConsequence(pact, approved: false),
            icon: const Icon(Icons.close),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            label: const Text('Reject Consequence Evidence'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: pactProvider.isLoading
                ? null
                : () => _verifyConsequence(pact, approved: true),
            icon: const Icon(Icons.check),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            label: const Text('Approve Consequence Evidence'),
          ),
        ],
      );
    }

    if ((isOwner && pact.status == PactStatus.active && !pact.isOverdue) ||
        isConsequenceOwnerSubmission) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          notesCard,
          const SizedBox(height: 10),
          if (ownerEvidencePreview != null) ...[
            ownerEvidencePreview,
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmittingEvidence ? null : _pickPhotoEvidence,
                  icon: const Icon(Icons.photo_library_outlined),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.darkBorder),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  label: const Text('Upload Photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmittingEvidence ? null : _pickVideoEvidence,
                  icon: const Icon(Icons.video_library_outlined),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.darkBorder),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  label: const Text('Upload Video'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isSubmittingEvidence
                ? null
                : () => _submitEvidence(pact),
            icon: _isSubmittingEvidence
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: statusTheme.main,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: Text(
              isConsequenceOwnerSubmission
                  ? 'Submit Consequence Evidence'
                  : 'Confirm Submission',
            ),
          ),
          if (isConsequenceOwnerSubmission)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Consequence lock remains active until verifier approval.',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        notesCard,
        if (evidencePreview != null) ...[
          const SizedBox(height: 10),
          evidencePreview,
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Text(
            _statusSummary(pact),
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionNotesCard({required bool editable}) {
    final fieldBackground = editable
        ? AppColors.darkBackground.withValues(alpha: 0.4)
        : AppColors.darkBackground.withValues(alpha: 0.9);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submission Notes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _submissionNoteController,
            enabled: editable,
            maxLines: 3,
            style: TextStyle(
              color: editable
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fieldBackground,
              hintText: 'Add notes about your submission or completion...',
              hintStyle: TextStyle(
                color: editable
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryDark.withValues(alpha: 0.6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: editable
                      ? AppColors.darkBorder
                      : AppColors.darkBorder.withValues(alpha: 0.55),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.darkBorder.withValues(alpha: 0.45),
                ),
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalEvidencePreview() {
    final selectedPhoto = _selectedPhotoEvidence;
    final selectedVideo = _selectedVideoEvidence;

    if (selectedPhoto != null) {
      return _buildEvidencePreviewFrame(
        label: 'Preview',
        trailing: TextButton.icon(
          onPressed: _clearSelectedEvidence,
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Remove'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        child: _buildAdaptiveImagePreview(FileImage(selectedPhoto)),
      );
    }

    if (selectedVideo != null) {
      return _buildEvidencePreviewFrame(
        label: 'Preview',
        trailing: TextButton.icon(
          onPressed: _clearSelectedEvidence,
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Remove'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        child: _buildVideoPreviewPlaceholder(
          subtitle: selectedVideo.path.split('\\').last,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNetworkEvidencePreview(String? evidenceUrl) {
    if (evidenceUrl == null || evidenceUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_looksLikeImageUrl(evidenceUrl)) {
      return _buildEvidencePreviewFrame(
        label: 'Submitted Evidence',
        child: _buildAdaptiveImagePreview(NetworkImage(evidenceUrl)),
      );
    }

    return _buildEvidencePreviewFrame(
      label: 'Submitted Evidence',
      child: _buildVideoPreviewPlaceholder(
        subtitle: 'Video uploaded successfully.',
      ),
    );
  }

  Widget _buildEvidencePreviewFrame({
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 6),
          Center(child: child),
        ],
      ),
    );
  }

  void _clearSelectedEvidence() {
    setState(() {
      _selectedPhotoEvidence = null;
      _selectedVideoEvidence = null;
    });
  }

  Widget _buildAdaptiveImagePreview(ImageProvider imageProvider) {
    return FutureBuilder<ui.Size>(
      future: _resolveImageSize(imageProvider),
      builder: (context, snapshot) {
        final resolvedAspectRatio = snapshot.hasData
            ? (snapshot.data!.width / snapshot.data!.height)
                  .clamp(0.7, 1.8)
                  .toDouble()
            : 4 / 3;

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxPreviewWidth = constraints.maxWidth.clamp(180.0, 230.0);

            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: AppColors.darkBackground,
                constraints: BoxConstraints(
                  maxWidth: maxPreviewWidth,
                  maxHeight: 220,
                ),
                child: AspectRatio(
                  aspectRatio: resolvedAspectRatio,
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildVideoPreviewPlaceholder(
                      subtitle: 'Unable to render image preview.',
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<ui.Size> _resolveImageSize(ImageProvider imageProvider) {
    final completer = Completer<ui.Size>();
    final imageStream = imageProvider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (imageInfo, _) {
        final image = imageInfo.image;
        if (!completer.isCompleted) {
          completer.complete(
            ui.Size(image.width.toDouble(), image.height.toDouble()),
          );
        }
        imageStream.removeListener(listener);
      },
      onError: (_, __) {
        if (!completer.isCompleted) {
          completer.complete(const ui.Size(4, 3));
        }
        imageStream.removeListener(listener);
      },
    );

    imageStream.addListener(listener);
    return completer.future;
  }

  Widget _buildVideoPreviewPlaceholder({required String subtitle}) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_rounded,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            'Video Preview',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  bool _looksLikeImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.contains('/image/');
  }

  Future<void> _pickPhotoEvidence() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPhotoEvidence = File(picked.path);
      _selectedVideoEvidence = null;
    });
  }

  Future<void> _pickVideoEvidence() async {
    final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedVideoEvidence = File(picked.path);
      _selectedPhotoEvidence = null;
    });
  }

  Widget _buildVerifierTile(PactModel pact) {
    if (pact.verifierId == null || pact.verifierId!.isEmpty) {
      return _infoTile(
        icon: Icons.verified_user_outlined,
        title: 'Verifier',
        value: _verificationLabel(pact.verificationType),
      );
    }

    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUser(pact.verifierId!),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName =
            user?.displayName ?? user?.username ?? 'Verifier User';

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              AppAvatar(imageUrl: user?.profilePictureUrl, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verifier',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvidenceIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Evidence submitted',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondaryDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(
    String text,
    Color color, {
    bool subtle = false,
    Color? foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: subtle
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor ?? color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }

  Future<void> _submitEvidence(PactModel pact) async {
    if (_selectedPhotoEvidence == null && _selectedVideoEvidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload a photo or video before confirming submission.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingEvidence = true;
    });

    try {
      final pactProvider = context.read<PactProvider>();
      final success = await pactProvider.submitEvidence(
        pact: pact,
        photoFile: _selectedPhotoEvidence,
        videoFile: _selectedVideoEvidence,
        submissionNote: _submissionNoteController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Evidence submitted successfully.'
                : (pactProvider.errorMessage ??
                      'Could not submit evidence. Please try again.'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.primary,
        ),
      );

      if (success) {
        setState(() {
          _selectedPhotoEvidence = null;
          _selectedVideoEvidence = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingEvidence = false;
        });
      }
    }
  }

  Future<void> _verifyPact(PactModel pact, {required bool approved}) async {
    final success = await context.read<PactProvider>().verifyPact(
      pact,
      approved,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? approved
                    ? 'Pact approved and completed.'
                    : 'Pact rejected.'
              : 'Unable to update verification right now.',
        ),
        backgroundColor: success
            ? (approved ? AppColors.success : AppColors.primary)
            : AppColors.primary,
      ),
    );
  }

  Future<void> _verifyConsequence(
    PactModel pact, {
    required bool approved,
  }) async {
    final success = await context.read<PactProvider>().verifyConsequence(
      pact,
      approved,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? approved
                    ? 'Consequence evidence approved.'
                    : 'Consequence evidence rejected. User must resubmit.'
              : 'Unable to update consequence review right now.',
        ),
        backgroundColor: success
            ? (approved ? AppColors.success : AppColors.primary)
            : AppColors.primary,
      ),
    );
  }

  _PactStatusTheme _statusThemeForPact(PactModel pact) {
    if (pact.status == PactStatus.completed) {
      return const _PactStatusTheme(main: AppColors.completed);
    }

    if (pact.status == PactStatus.failed || pact.isOverdue) {
      return const _PactStatusTheme(main: AppColors.accent);
    }

    return const _PactStatusTheme(main: AppColors.primary);
  }

  String _statusLabel(PactModel pact) {
    if (pact.status == PactStatus.completed) {
      return 'Completed';
    }

    if (pact.status == PactStatus.failed || pact.isOverdue) {
      return 'Failed';
    }

    return 'Ongoing';
  }

  String _verificationLabel(VerificationType type) {
    switch (type) {
      case VerificationType.selfAttest:
        return 'Self Verification';
      case VerificationType.friendVerify:
        return 'Friend Review';
      case VerificationType.aiVerify:
        return 'AI Verification';
      case VerificationType.photoProof:
        return 'Photo Proof';
      case VerificationType.videoProof:
        return 'Video Proof';
    }
  }

  String _consequenceDescription(PactModel pact) {
    if (pact.consequenceDetails.isNotEmpty) {
      final customText = pact.consequenceDetails['description'];
      if (customText is String && customText.trim().isNotEmpty) {
        return customText.trim();
      }
    }

    switch (pact.consequenceType) {
      case ConsequenceType.socialSharing:
        return 'If you miss this pact, you need to post a consequence update visible to your accountability circle.';
      case ConsequenceType.donationChallenge:
        return 'If this pact fails, a donation-style challenge is triggered based on the pre-agreed stakes.';
      case ConsequenceType.funnyPenalty:
        return 'Missing this pact triggers a playful penalty to keep accountability memorable and social.';
    }
  }

  String _formatCountdown(PactModel pact) {
    if (pact.status == PactStatus.completed) {
      return 'DONE';
    }

    if (pact.status == PactStatus.failed || pact.isOverdue) {
      return '00:00:00';
    }

    final remaining = pact.deadline.difference(DateTime.now());
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    final hours = safeRemaining.inHours;
    final minutes = safeRemaining.inMinutes.remainder(60);
    final seconds = safeRemaining.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _statusSummary(PactModel pact) {
    if (pact.status == PactStatus.completed) {
      return 'This pact is completed. Great execution and accountability.';
    }

    if (pact.status == PactStatus.failed || pact.isOverdue) {
      if (pact.consequenceStatus == ConsequenceStatus.pendingApproval) {
        return 'This pact failed and consequence evidence is waiting for verifier approval.';
      }
      if (pact.consequenceStatus == ConsequenceStatus.rejected) {
        return 'Consequence evidence was rejected. Resubmit to clear your lock.';
      }
      if (pact.consequenceStatus == ConsequenceStatus.approved) {
        return 'This pact failed, and the required consequence has been completed and approved.';
      }
      return 'This pact failed. Review the consequence details and create the next pact quickly to keep momentum.';
    }

    if (pact.status == PactStatus.verificationPending) {
      return 'Evidence was submitted and is waiting for verifier action.';
    }

    return 'This pact is ongoing. Submit evidence before the deadline to avoid triggering the consequence.';
  }

  String _submissionNoteFromPact(PactModel pact) {
    final note = pact.consequenceDetails['submissionNote'];
    if (note is String && note.trim().isNotEmpty) {
      return note.trim();
    }
    return '';
  }
}

class _PactStatusTheme {
  const _PactStatusTheme({required this.main});

  final Color main;
}
