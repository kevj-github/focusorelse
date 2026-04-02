import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/pact_model.dart';
import '../../models/post_comment_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/streak_calculator.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/avatar.dart';

enum _StatsInterval { week, month, threeMonths }

enum _ChartMode { completed, failed, both }

Color _surfaceColor(BuildContext context) =>
    Theme.of(context).colorScheme.surface;

Color _surfaceVariantColor(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainerHighest;

Color _onSurfaceColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface;

Color _secondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textSecondaryDark
      : AppColors.textSecondaryLight;
}

Color _borderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkBorder
      : AppColors.lightBorder;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
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
    return Consumer2<AuthProvider, PactProvider>(
      builder: (context, authProvider, pactProvider, _) {
        final user = authProvider.userModel;

        if (user == null && authProvider.isLoading) {
          return const _ProfileLoadingState();
        }

        if (user == null && authProvider.errorMessage != null) {
          return _ProfileErrorState(
            message: authProvider.errorMessage!,
            onRetry: widget.onRetry,
          );
        }

        if (user == null) {
          return _ProfileErrorState(
            message: 'Unable to load profile right now.',
            onRetry: widget.onRetry,
          );
        }

        final pacts = [
          ...pactProvider.activePacts,
          ...pactProvider.completedPacts,
        ];

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: _ProfileHeader(
                  user: user,
                  onEditProfile: () =>
                      _showEditProfileSheet(context, authProvider, user),
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
                  labelColor: _onSurfaceColor(context),
                  unselectedLabelColor: _secondaryTextColor(context),
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
                    _ProfilePostsTab(user: user),
                    _ProfileStatsTab(user: user, pacts: pacts),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    AuthProvider authProvider,
    UserModel user,
  ) async {
    final displayNameController = TextEditingController(
      text: user.displayName ?? '',
    );
    final usernameController = TextEditingController(text: user.username ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');
    final picker = ImagePicker();
    final storageService = StorageService();

    String? uploadedPhotoUrl = user.profilePictureUrl;
    bool isUploadingPhoto = false;
    bool isSaving = false;
    bool sheetActive = true;
    bool isCheckingUsername = false;
    bool? usernameAvailable;
    String? usernameError;
    Timer? usernameDebounce;

    String normalizeUsername(String input) {
      final lower = input.trim().toLowerCase();
      final withoutPrefix = lower.startsWith('@') ? lower.substring(1) : lower;
      return withoutPrefix.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceVariantColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> uploadPhoto() async {
              final uid = authProvider.firebaseUser?.uid;
              if (uid == null) return;

              final picked = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );
              if (picked == null) return;

              if (!context.mounted || !sheetActive) return;
              setModalState(() {
                isUploadingPhoto = true;
              });

              try {
                final photoUrl = await storageService.uploadProfilePicture(
                  uid,
                  File(picked.path),
                );

                if (context.mounted && sheetActive) {
                  setModalState(() {
                    uploadedPhotoUrl = photoUrl;
                  });
                }
              } on StorageServiceException catch (error) {
                if (!mounted || !this.context.mounted) return;
                final message = error.code == 'config-missing'
                    ? 'Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET to your .env file.'
                    : 'Profile photo upload failed. Please try again.';

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (_) {
                if (!mounted || !this.context.mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to upload profile photo. Please try again.',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } finally {
                if (context.mounted && sheetActive) {
                  setModalState(() {
                    isUploadingPhoto = false;
                  });
                }
              }
            }

            Future<void> saveChanges() async {
              final normalizedUsername = normalizeUsername(
                usernameController.text,
              );
              final trimmedDisplayName = displayNameController.text.trim();

              if (trimmedDisplayName.isEmpty) {
                setModalState(() {
                  usernameError = 'Display name is required.';
                });
                return;
              }

              if (normalizedUsername.length < 3) {
                setModalState(() {
                  usernameError =
                      'Username must be at least 3 characters long.';
                });
                return;
              }

              final isAvailable = await authProvider.isUsernameAvailable(
                normalizedUsername,
                excludeUserId: user.userId,
              );
              if (!isAvailable) {
                setModalState(() {
                  usernameError = 'Username is already taken.';
                  usernameAvailable = false;
                });
                return;
              }

              if (!context.mounted || !sheetActive) return;
              setModalState(() {
                isSaving = true;
                usernameError = null;
              });

              final updated = user.copyWith(
                displayName: trimmedDisplayName,
                username: normalizedUsername,
                bio: bioController.text.trim(),
                profilePictureUrl: uploadedPhotoUrl,
              );

              await authProvider.updateUserProfile(updated);

              if (!mounted || !context.mounted || !sheetActive) return;
              sheetActive = false;
              Navigator.of(context).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile',
                      style: AppTypography.titleLarge.copyWith(
                        color: _onSurfaceColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: AppAvatar(imageUrl: uploadedPhotoUrl, radius: 42),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isUploadingPhoto || isSaving
                            ? null
                            : uploadPhoto,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(
                          isUploadingPhoto
                              ? 'Uploading...'
                              : 'Upload Profile Picture',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppInput(
                      controller: displayNameController,
                      label: 'Display Name',
                      hintText: 'How others will see your name',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: usernameController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: _onSurfaceColor(context),
                      ),
                      onChanged: (value) {
                        final normalized = normalizeUsername(value);
                        if (value != normalized) {
                          usernameController.value = usernameController.value
                              .copyWith(
                                text: normalized,
                                selection: TextSelection.collapsed(
                                  offset: normalized.length,
                                ),
                              );
                        }

                        usernameDebounce?.cancel();
                        if (normalized.length < 3) {
                          setModalState(() {
                            isCheckingUsername = false;
                            usernameAvailable = null;
                            usernameError = normalized.isEmpty
                                ? null
                                : 'Username must be at least 3 characters long.';
                          });
                          return;
                        }

                        setModalState(() {
                          isCheckingUsername = true;
                          usernameError = null;
                        });

                        usernameDebounce = Timer(
                          const Duration(milliseconds: 450),
                          () async {
                            final isAvailable = await authProvider
                                .isUsernameAvailable(
                                  normalized,
                                  excludeUserId: user.userId,
                                );

                            if (!context.mounted || !sheetActive) return;
                            setModalState(() {
                              isCheckingUsername = false;
                              usernameAvailable = isAvailable;
                              usernameError = isAvailable
                                  ? null
                                  : 'Username is already taken.';
                            });
                          },
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'lowercase, numbers, underscore',
                      ),
                    ),
                    if (isCheckingUsername ||
                        usernameError != null ||
                        usernameAvailable == true)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          left: AppSpacing.xs,
                        ),
                        child: Text(
                          isCheckingUsername
                              ? 'Checking username...'
                              : (usernameError ?? 'Username is available.'),
                          style: AppTypography.label.copyWith(
                            color: isCheckingUsername
                                ? _secondaryTextColor(context)
                                : (usernameError != null
                                      ? AppColors.primary
                                      : AppColors.accent),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppInput(
                      controller: bioController,
                      label: 'Bio',
                      hintText: 'Write a short bio',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Save Changes',
                      isLoading: isSaving,
                      onPressed: saveChanges,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      usernameDebounce?.cancel();
      sheetActive = false;
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEditProfile});

  final UserModel user;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
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
            AppAvatar(imageUrl: user.profilePictureUrl, radius: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.displayName ?? user.username ?? 'Focus User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      color: _onSurfaceColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((user.username ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: _secondaryTextColor(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    (user.bio ?? '').trim().isEmpty
                        ? 'No bio yet. Tap Edit Profile to add one.'
                        : user.bio!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: _secondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onEditProfile,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _borderColor(context)),
                foregroundColor: _onSurfaceColor(context),
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
                  borderRadius: BorderRadius.circular(AppElevation.radiusSmall),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: Text(
                'Edit',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePostsTab extends StatelessWidget {
  const _ProfilePostsTab({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, _) {
        final posts = postProvider.userPosts;

        if (postProvider.isLoading && posts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (posts.isEmpty) {
          return const _ProfileEmptyState(
            title: 'No posts yet',
            subtitle:
                'Use the + button from bottom navigation and choose Post to publish.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 0),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final post = posts[index];
            return InkWell(
              onTap: () => _openPostDetails(context, post, user),
              child: _PostGridTile(post: post),
            );
          },
        );
      },
    );
  }

  void _openPostDetails(BuildContext context, PostModel post, UserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _InstagramPostScreen(post: post, currentUser: user),
      ),
    );
  }
}

class _ProfileStatsTab extends StatefulWidget {
  const _ProfileStatsTab({required this.user, required this.pacts});

  final UserModel user;
  final List<PactModel> pacts;

  @override
  State<_ProfileStatsTab> createState() => _ProfileStatsTabState();
}

class _ProfileStatsTabState extends State<_ProfileStatsTab>
    with AutomaticKeepAliveClientMixin<_ProfileStatsTab> {
  _StatsInterval _interval = _StatsInterval.week;
  _ChartMode _mode = _ChartMode.both;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final completedPacts = widget.pacts
        .where((p) => p.status == PactStatus.completed)
        .toList();
    final streakStats = StreakCalculator.fromPacts(widget.pacts);
    final currentStreak = streakStats.current;
    final longestStreak = streakStats.longest;

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
                child: _MetricBlock(
                  title: 'Streak',
                  value: '$currentStreak day',
                  subtitle: 'Current',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: _MetricBlock(
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
                child: _MetricBlock(
                  title: 'Longest Streak',
                  value: '$longestStreak day',
                  subtitle: 'Best',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: _MetricBlock(
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
          child: _MetricBlock(
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
                style: AppTypography.titleMedium.copyWith(
                  color: _onSurfaceColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    'Interval',
                    style: AppTypography.label.copyWith(
                      color: _secondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<_StatsInterval>(
                      initialValue: _interval,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        filled: true,
                        fillColor: _surfaceColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppElevation.radiusSmall,
                          ),
                          borderSide: BorderSide(color: _borderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppElevation.radiusSmall,
                          ),
                          borderSide: BorderSide(color: _borderColor(context)),
                        ),
                      ),
                      dropdownColor: _surfaceVariantColor(context),
                      iconEnabledColor: _secondaryTextColor(context),
                      style: AppTypography.labelSmall.copyWith(
                        color: _onSurfaceColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _StatsInterval.week,
                          child: Text('Week'),
                        ),
                        DropdownMenuItem(
                          value: _StatsInterval.month,
                          child: Text('Month'),
                        ),
                        DropdownMenuItem(
                          value: _StatsInterval.threeMonths,
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
                  _ChoiceChip(
                    label: 'Completed',
                    selected: _mode == _ChartMode.completed,
                    onTap: () => setState(() => _mode = _ChartMode.completed),
                  ),
                  _ChoiceChip(
                    label: 'Failed',
                    selected: _mode == _ChartMode.failed,
                    onTap: () => setState(() => _mode = _ChartMode.failed),
                  ),
                  _ChoiceChip(
                    label: 'Both',
                    selected: _mode == _ChartMode.both,
                    onTap: () => setState(() => _mode = _ChartMode.both),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              RepaintBoundary(
                child: _PactSummaryChart(
                  pacts: widget.pacts,
                  interval: _interval,
                  mode: _mode,
                ),
              ),
              if (_mode == _ChartMode.both) ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _LegendDot(color: AppColors.completed, label: 'Completed'),
                    SizedBox(width: 12),
                    _LegendDot(color: AppColors.error, label: 'Failed'),
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

class _PactSummaryChart extends StatelessWidget {
  const _PactSummaryChart({
    required this.pacts,
    required this.interval,
    required this.mode,
  });

  final List<PactModel> pacts;
  final _StatsInterval interval;
  final _ChartMode mode;

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();

    if (points.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No data for selected filter.',
            style: AppTypography.bodyMedium.copyWith(
              color: _secondaryTextColor(context),
            ),
          ),
        ),
      );
    }

    final maxValue = points.fold<int>(1, (max, p) {
      final value = mode == _ChartMode.completed
          ? p.completed
          : mode == _ChartMode.failed
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
          final modeValue = mode == _ChartMode.completed
              ? p.completed
              : mode == _ChartMode.failed
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$modeValue',
                    style: AppTypography.labelSmall.copyWith(
                      color: _secondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppElevation.radiusSmall,
                    ),
                    child: mode == _ChartMode.both
                        ? SizedBox(
                            height: totalHeight,
                            child: Column(
                              children: [
                                if (failedHeight > 0)
                                  Container(
                                    height: failedHeight,
                                    color: AppColors.error,
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
                            color: mode == _ChartMode.completed
                                ? AppColors.completed
                                : AppColors.error,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    p.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: _secondaryTextColor(context),
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

  List<_ChartPoint> _buildPoints() {
    final now = DateTime.now();

    if (interval == _StatsInterval.week) {
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
        return _ChartPoint(weekdayLabel, completed, failed);
      });
    }

    if (interval == _StatsInterval.month) {
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

        return _ChartPoint('W${index + 1}', completed, failed);
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
      return _ChartPoint(monthLabel, completed, failed);
    });
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
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
          style: AppTypography.label.copyWith(
            color: _secondaryTextColor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            color: _onSurfaceColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.label.copyWith(
            color: _secondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
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
          color: selected ? AppColors.primary : _surfaceColor(context),
          borderRadius: BorderRadius.circular(AppElevation.radiusSmall),
          border: Border.all(color: _borderColor(context)),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? Colors.white : _secondaryTextColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

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
          style: AppTypography.label.copyWith(
            color: _secondaryTextColor(context),
          ),
        ),
      ],
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: _surfaceVariantColor(context),
            borderRadius: BorderRadius.circular(AppElevation.radiusMedium),
            border: Border.all(color: _borderColor(context)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: _surfaceVariantColor(context),
            borderRadius: BorderRadius.circular(AppElevation.radiusMedium),
            border: Border.all(color: _borderColor(context)),
          ),
        ),
      ],
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: _secondaryTextColor(context),
                      size: 34,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(
                        color: _onSurfaceColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: _secondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.primary,
                      size: 34,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: _onSurfaceColor(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (onRetry != null)
                      SizedBox(
                        width: 180,
                        child: AppButton(label: 'Retry', onPressed: onRetry),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PostGridTile extends StatelessWidget {
  const _PostGridTile({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: post.postId.isEmpty ? post.imageUrl : post.postId,
      child: ColoredBox(
        color: Colors.black,
        child: Image.network(
          post.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: _secondaryTextColor(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstagramPostScreen extends StatefulWidget {
  const _InstagramPostScreen({required this.post, required this.currentUser});

  final PostModel post;
  final UserModel currentUser;

  @override
  State<_InstagramPostScreen> createState() => _InstagramPostScreenState();
}

class _InstagramPostScreenState extends State<_InstagramPostScreen> {
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
          backgroundColor: _surfaceColor(context),
          appBar: AppBar(
            backgroundColor: _surfaceColor(context),
            foregroundColor: _onSurfaceColor(context),
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
                                  color: _onSurfaceColor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.more_horiz,
                              color: _secondaryTextColor(context),
                            ),
                          ],
                        ),
                      ),
                      Hero(
                        tag: currentPost.postId.isEmpty
                            ? currentPost.imageUrl
                            : currentPost.postId,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            currentPost.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: _surfaceVariantColor(context),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: _secondaryTextColor(context),
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
                                              ? _secondaryTextColor(context)
                                              : _onSurfaceColor(context)),
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
                                color: _onSurfaceColor(context),
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
                            color: _onSurfaceColor(context),
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
                              color: _onSurfaceColor(context),
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
                            color: _secondaryTextColor(context),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                        color: _borderColor(context),
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
                                  color: _secondaryTextColor(context),
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
                                          color: _onSurfaceColor(context),
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
                    color: _surfaceVariantColor(context),
                    border: Border(
                      top: BorderSide(color: _borderColor(context)),
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
                            color: _onSurfaceColor(context),
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
                                  color: _onSurfaceColor(context),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: AppTypography.bodyMedium.copyWith(
                                    color: _secondaryTextColor(context),
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
    if (currentPost.authorId == widget.currentUser.userId) {
      final ownUsername = widget.currentUser.username?.trim();
      if (ownUsername != null && ownUsername.isNotEmpty) {
        return ownUsername;
      }
      return (widget.currentUser.displayName ?? 'focus_user')
          .trim()
          .toLowerCase()
          .replaceAll(' ', '_');
    }

    return (currentPost.authorUsername?.trim().isNotEmpty ?? false)
        ? currentPost.authorUsername!.trim()
        : currentPost.authorDisplayName.trim().toLowerCase().replaceAll(
            ' ',
            '_',
          );
  }

  String? _resolvedAvatarUrl(PostModel currentPost) {
    if (currentPost.authorId == widget.currentUser.userId) {
      return widget.currentUser.profilePictureUrl;
    }
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

class _ChartPoint {
  const _ChartPoint(this.label, this.completed, this.failed);

  final String label;
  final int completed;
  final int failed;
}
