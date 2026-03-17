import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/friend_model.dart';
import '../../models/pact_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pact_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../create_pact/create_pact_screen.dart';
import '../friends/friends_tab_view.dart';
import '../pacts/pact_details_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../../theme/colors.dart';
import '../../widgets/common/avatar.dart';
import '../../widgets/common/app_logo_bar.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey _notificationIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final pactProvider = Provider.of<PactProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (authProvider.firebaseUser != null) {
      final userId = authProvider.firebaseUser!.uid;
      unawaited(pactProvider.registerNotificationUser(userId));
      pactProvider.loadActivePacts(userId);
      pactProvider.loadCompletedPacts(userId);
      pactProvider.loadPactsToVerify(userId);
      postProvider.loadUserPosts(userId);
    }
  }

  Future<void> _openCreatePactFlow() async {
    final pactProvider = Provider.of<PactProvider>(context, listen: false);
    if (pactProvider.hasPendingConsequence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pact creation is locked until your pending consequence is approved.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

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
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openCreateActionSheet() async {
    final pactProvider = Provider.of<PactProvider>(context, listen: false);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.post_add, color: onSurface),
                  title: Text(
                    'Create Post',
                    style: TextStyle(color: onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (pactProvider.hasPendingConsequence) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Posting is locked until your pending consequence is approved.',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                      return;
                    }
                    _openCreatePostFlow();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: onSurface),
                  title: Text(
                    'Create Pact',
                    style: TextStyle(color: onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openCreatePactFlow();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreatePostFlow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final storageService = StorageService();
    final user = authProvider.userModel;
    final userId = authProvider.firebaseUser?.uid;
    final pactProvider = Provider.of<PactProvider>(context, listen: false);

    if (pactProvider.hasPendingConsequence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Posting is locked until your pending consequence is approved.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (user == null || userId == null) return;

    final captionController = TextEditingController();
    final imagePicker = ImagePicker();
    File? selectedImage;
    bool isSubmitting = false;
    bool sheetActive = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final onSurface = Theme.of(context).colorScheme.onSurface;
            Future<void> pickImage() async {
              final picked = await imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );

              if (picked == null) return;

              if (!context.mounted || !sheetActive) return;
              setModalState(() {
                selectedImage = File(picked.path);
              });
            }

            Future<void> publish() async {
              if (captionController.text.trim().isEmpty ||
                  selectedImage == null) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Caption and image are required.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                return;
              }

              if (!context.mounted || !sheetActive) return;
              setModalState(() {
                isSubmitting = true;
              });

              try {
                final imageUrl = await storageService.uploadPostImage(
                  userId,
                  selectedImage!,
                );

                final success = await postProvider.createPost(
                  authorId: userId,
                  authorDisplayName:
                      user.displayName ?? user.username ?? 'Focus User',
                  authorUsername: user.username,
                  authorProfilePictureUrl: user.profilePictureUrl,
                  caption: captionController.text.trim(),
                  imageUrl: imageUrl,
                );

                if (!mounted || !context.mounted || !sheetActive) return;
                if (success) {
                  sheetActive = false;
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Post published.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  });
                }
              } on StorageServiceException catch (error) {
                if (!mounted || !this.context.mounted) return;
                final message = error.code == 'config-missing'
                    ? 'Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET to your .env file.'
                    : 'Image upload failed. Please try again.';

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
                    content: Text('Failed to publish post. Please try again.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } finally {
                if (context.mounted && sheetActive) {
                  setModalState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: captionController,
                      maxLines: 3,
                      style: TextStyle(color: onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Caption',
                        hintText: 'What do you want to share?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          selectedImage == null
                              ? 'Upload Image'
                              : 'Image Selected',
                        ),
                      ),
                    ),
                    if (selectedImage != null) ...[
                      const SizedBox(height: 10),
                      _buildCreatePostImagePreview(
                        selectedImage!,
                        onRemove: () {
                          setModalState(() {
                            selectedImage = null;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : publish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publish Post'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      sheetActive = false;
    });
  }

  Widget _buildCreatePostImagePreview(
    File imageFile, {
    required VoidCallback onRemove,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Preview',
                  style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(child: _buildAdaptiveFileImagePreview(imageFile)),
        ],
      ),
    );
  }

  Widget _buildAdaptiveFileImagePreview(File imageFile) {
    return FutureBuilder<ui.Size>(
      future: _resolveFileImageSize(imageFile),
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                constraints: BoxConstraints(
                  maxWidth: maxPreviewWidth,
                  maxHeight: 220,
                ),
                child: AspectRatio(
                  aspectRatio: resolvedAspectRatio,
                  child: Image.file(imageFile, fit: BoxFit.contain),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<ui.Size> _resolveFileImageSize(File imageFile) {
    final imageProvider = FileImage(imageFile);
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

  Future<void> _openNotificationsPopup() async {
    final authProvider = context.read<AuthProvider>();
    final userId =
        authProvider.userModel?.userId ?? authProvider.firebaseUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to view notifications.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final processingIds = <String>{};
    final iconContext = _notificationIconKey.currentContext;
    if (iconContext == null) {
      return;
    }

    final iconRenderBox = iconContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (iconRenderBox == null || overlayBox == null) {
      return;
    }

    final iconOffset = iconRenderBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final iconSize = iconRenderBox.size;
    final overlaySize = overlayBox.size;
    const popupWidth = 320.0;
    const horizontalPadding = 8.0;

    final popupLeft = (iconOffset.dx + iconSize.width - popupWidth).clamp(
      horizontalPadding,
      overlaySize.width - popupWidth - horizontalPadding,
    );
    final popupTop = iconOffset.dy + iconSize.height + 6;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        final secondary = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;

        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            Future<void> handleRequestAction(
              FriendModel request,
              bool accept,
            ) async {
              if (processingIds.contains(request.friendshipId)) {
                return;
              }

              setModalState(() {
                processingIds.add(request.friendshipId);
              });

              try {
                if (accept) {
                  await _firestoreService.acceptFriendRequest(
                    request.friendshipId,
                  );
                } else {
                  await _firestoreService.declineFriendRequest(
                    request.friendshipId,
                  );
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      accept
                          ? 'Friend request accepted.'
                          : 'Friend request declined.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      accept
                          ? 'Unable to accept friend request right now.'
                          : 'Unable to decline friend request right now.',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() {
                    processingIds.remove(request.friendshipId);
                  });
                }
              }
            }

            Future<void> handleAppNotificationTap(
              Map<String, dynamic> notification,
            ) async {
              final notificationId = (notification['id'] ?? '').toString();
              final pactId = (notification['pactId'] ?? '').toString();

              if (notificationId.isNotEmpty) {
                await _firestoreService.markNotificationAsRead(notificationId);
              }

              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }

              if (pactId.isNotEmpty && mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PactDetailsScreen(pactId: pactId),
                  ),
                );
              }
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => Navigator.of(sheetContext).pop(),
                  ),
                ),
                Positioned(
                  left: popupLeft,
                  top: popupTop,
                  width: popupWidth,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 12,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 430),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _firestoreService.streamUserNotifications(
                            userId,
                          ),
                          builder: (context, appNotificationSnapshot) {
                            final appNotifications =
                                appNotificationSnapshot.data ??
                                const <Map<String, dynamic>>[];

                            return StreamBuilder<List<FriendModel>>(
                              stream: _firestoreService
                                  .streamPendingFriendRequests(userId),
                              builder: (context, pendingSnapshot) {
                                if (pendingSnapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    appNotificationSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 220,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                }

                                final pendingRequests =
                                    pendingSnapshot.data ??
                                    const <FriendModel>[];
                                final existingPactIds = appNotifications
                                    .map(
                                      (notification) =>
                                          (notification['pactId'] ?? '')
                                              .toString(),
                                    )
                                    .where((id) => id.isNotEmpty)
                                    .toSet();
                                final requesterIds = pendingRequests
                                    .map((request) => request.userId)
                                    .toSet()
                                    .toList();

                                return StreamBuilder<List<PactModel>>(
                                  stream: _firestoreService
                                      .streamPactsForVerifier(userId),
                                  builder: (context, verifierSnapshot) {
                                    final verifierPacts =
                                        verifierSnapshot.data ??
                                        const <PactModel>[];

                                    return FutureBuilder<List<UserModel>>(
                                      future: requesterIds.isEmpty
                                          ? Future.value(const <UserModel>[])
                                          : _firestoreService.getUsersByIds(
                                              requesterIds,
                                            ),
                                      builder: (context, usersSnapshot) {
                                        final users =
                                            usersSnapshot.data ??
                                            const <UserModel>[];
                                        final usersById = <String, UserModel>{
                                          for (final user in users)
                                            user.userId: user,
                                        };

                                        final tiles = <Widget>[];

                                        for (final notification
                                            in appNotifications) {
                                          final type =
                                              (notification['type'] ?? '')
                                                  .toString();
                                          final title =
                                              (notification['title'] ??
                                                      'Notification')
                                                  .toString();
                                          final body =
                                              (notification['body'] ?? '')
                                                  .toString();
                                          final isRead =
                                              notification['read'] == true;
                                          final createdAtRaw =
                                              notification['createdAt'];
                                          DateTime? createdAt;
                                          if (createdAtRaw is Timestamp) {
                                            createdAt = createdAtRaw.toDate();
                                          }

                                          final icon = switch (type) {
                                            'verifier-assigned' =>
                                              Icons.assignment_ind_outlined,
                                            'consequence-review-required' =>
                                              Icons.rule_folder_outlined,
                                            _ => Icons.verified_outlined,
                                          };

                                          tiles.add(
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () =>
                                                  handleAppNotificationTap(
                                                    notification,
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isRead
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .surfaceContainerHighest
                                                            .withValues(
                                                              alpha: 0.65,
                                                            )
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .surfaceContainerHighest,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isRead
                                                        ? AppColors.darkBorder
                                                        : AppColors.primary
                                                              .withValues(
                                                                alpha: 0.35,
                                                              ),
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      icon,
                                                      color: AppColors.primary,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            title,
                                                            style: TextStyle(
                                                              color: onSurface,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                          if (body.isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 2,
                                                                  ),
                                                              child: Text(
                                                                body,
                                                                style: TextStyle(
                                                                  color:
                                                                      secondary,
                                                                  fontSize: 12,
                                                                ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          if (createdAt != null)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              child: Text(
                                                                DateFormat(
                                                                  'MMM d, h:mm a',
                                                                ).format(
                                                                  createdAt,
                                                                ),
                                                                style: TextStyle(
                                                                  color:
                                                                      secondary,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        for (final pact in verifierPacts) {
                                          if (existingPactIds.contains(
                                            pact.pactId,
                                          )) {
                                            continue;
                                          }

                                          final needsApproval =
                                              pact.status ==
                                                  PactStatus
                                                      .verificationPending ||
                                              (pact.status ==
                                                      PactStatus.failed &&
                                                  pact.consequenceStatus ==
                                                      ConsequenceStatus
                                                          .pendingApproval);
                                          final newlyAssigned =
                                              pact.status == PactStatus.active;

                                          if (!needsApproval &&
                                              !newlyAssigned) {
                                            continue;
                                          }

                                          final title = needsApproval
                                              ? 'Waiting for your approval'
                                              : 'New pact assigned to you';
                                          final body = pact.taskDescription;

                                          tiles.add(
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () =>
                                                  handleAppNotificationTap({
                                                    'id': '',
                                                    'pactId': pact.pactId,
                                                    'title': title,
                                                    'body': body,
                                                    'read': false,
                                                  }),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .assignment_ind_outlined,
                                                      color: AppColors.primary,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            title,
                                                            style: TextStyle(
                                                              color: onSurface,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                          if (body.isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 2,
                                                                  ),
                                                              child: Text(
                                                                body,
                                                                style: TextStyle(
                                                                  color:
                                                                      secondary,
                                                                  fontSize: 12,
                                                                ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        for (final request in pendingRequests) {
                                          final requester =
                                              usersById[request.userId];
                                          final senderName =
                                              requester?.displayName ??
                                              requester?.username ??
                                              'A user';
                                          final senderUsername =
                                              (requester?.username ?? '')
                                                  .trim();
                                          final isProcessing = processingIds
                                              .contains(request.friendshipId);

                                          tiles.add(
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  AppAvatar(
                                                    imageUrl: requester
                                                        ?.profilePictureUrl,
                                                    radius: 18,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '$senderName sent you a friend request.',
                                                          style: TextStyle(
                                                            color: onSurface,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        if (senderUsername
                                                            .isNotEmpty)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 2,
                                                                ),
                                                            child: Text(
                                                              '@$senderUsername',
                                                              style: TextStyle(
                                                                color:
                                                                    secondary,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Row(
                                                          children: [
                                                            OutlinedButton(
                                                              onPressed:
                                                                  isProcessing
                                                                  ? null
                                                                  : () => handleRequestAction(
                                                                      request,
                                                                      false,
                                                                    ),
                                                              style: OutlinedButton.styleFrom(
                                                                foregroundColor:
                                                                    AppColors
                                                                        .primary,
                                                                side: const BorderSide(
                                                                  color: AppColors
                                                                      .primary,
                                                                ),
                                                                minimumSize:
                                                                    const Size(
                                                                      0,
                                                                      34,
                                                                    ),
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          12,
                                                                    ),
                                                                textStyle: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'Decline',
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            ElevatedButton(
                                                              onPressed:
                                                                  isProcessing
                                                                  ? null
                                                                  : () => handleRequestAction(
                                                                      request,
                                                                      true,
                                                                    ),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    AppColors
                                                                        .primary,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                minimumSize:
                                                                    const Size(
                                                                      0,
                                                                      34,
                                                                    ),
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          12,
                                                                    ),
                                                                textStyle: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                isProcessing
                                                                    ? '...'
                                                                    : 'Accept',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        if (tiles.isEmpty) {
                                          return SizedBox(
                                            height: 220,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .notifications_none_outlined,
                                                  color: secondary,
                                                  size: 26,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'No notifications yet.',
                                                  style: TextStyle(
                                                    color: secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Notifications',
                                              style: TextStyle(
                                                color: onSurface,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Flexible(
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                itemCount: tiles.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 10),
                                                itemBuilder: (context, index) =>
                                                    tiles[index],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppLogoBar(
        notificationKey: _notificationIconKey,
        onNotificationTap: _openNotificationsPopup,
        onSettingsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const _DashboardTabView(),
          _buildFeedView(),
          _buildFriendsView(),
          ProfileScreen(onRetry: _loadUserData),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        onPlusTap: _openCreateActionSheet,
      ),
    );
  }

  Widget _buildFeedView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Text(
        'Feed View - Coming Soon',
        style: TextStyle(color: secondary, fontSize: 18),
      ),
    );
  }

  Widget _buildFriendsView() {
    return FriendsTabView();
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

  Future<void> _openPactDetails(PactModel pact) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PactDetailsScreen(pactId: pact.pactId, initialPact: pact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final pactProvider = Provider.of<PactProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Theme.of(context).scaffoldBackgroundColor,
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
                  _buildFeaturedPactCard(featuredPact),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle(
                  _dashboardTabIndex == 0
                      ? 'Upcoming Pacts'
                      : 'Completed & Failed',
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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      _dashboardTabIndex == 0
                          ? 'No additional upcoming pacts.'
                          : 'No completed or failed pacts yet.',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
              ],
              if (pactProvider.hasPendingConsequence) ...[
                const SizedBox(height: 14),
                _buildConsequenceLockOverlayCard(
                  pactProvider.pendingConsequencePact,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(label: 'Active', index: 0),
          _buildTabButton(label: 'History', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String label, required int index}) {
    final isSelected = _dashboardTabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsequenceLockOverlayCard(PactModel? pendingConsequencePact) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final waitingApproval =
        pendingConsequencePact?.consequenceStatus ==
        ConsequenceStatus.pendingApproval;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            waitingApproval
                ? 'Consequence Evidence Submitted'
                : 'Consequence Due',
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            waitingApproval
                ? 'Evidence submitted, waiting for approval. You cannot create pacts, posts, comments, likes, or chat messages until the verifier approves it.'
                : 'Submit consequence evidence before you can create pacts, posts, comments, likes, or chat messages.',
            style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
          ),
          if (pendingConsequencePact != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openPactDetails(pendingConsequencePact),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  waitingApproval
                      ? 'View Submission Status'
                      : 'Submit Consequence Evidence',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    Map<String, _CalendarDayMarker> pactMarkers, {
    required List<PactModel> activePacts,
    required List<PactModel> expiredPacts,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final monthLabel = DateFormat('MMMM').format(_visibleMonth);
    final weekdayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = _buildMonthCells(_visibleMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.95),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                monthLabel,
                style: TextStyle(
                  color: onSurface,
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
                        style: TextStyle(
                          color: secondary,
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
                  ? onSurface
                  : secondary.withValues(alpha: 0.6);

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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, color: onSurface, size: 22),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final secondary = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
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
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  'Pacts on $dayLabel',
                  style: TextStyle(
                    color: onSurface,
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

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(_openPactDetails(pact));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat(
                                        'h:mm a',
                                      ).format(pact.deadline),
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                label: _statusBadgeLabel(pact),
                                color: _statusBadgeColor(pact),
                              ),
                            ],
                          ),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildFeaturedPactCard(PactModel pact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final isOverdue = pact.isOverdue;
    final countdownText = pact.timeRemainingFormatted;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openPactDetails(pact),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOverdue
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(
                  label: isOverdue ? 'FAILED' : 'ONGOING',
                  color: isOverdue ? AppColors.accent : AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Deadline: ${DateFormat('EEE, MMM d • h:mm a').format(pact.deadline)}',
              style: TextStyle(color: secondary, fontSize: 14),
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
                    color: isOverdue ? AppColors.accent : onSurface,
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
                onPressed: () => _openPactDetails(pact),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final isOverdue = pact.isOverdue;
    final isHistoryCard = !showOverdue;
    final badgeColor = isHistoryCard
        ? _statusBadgeColor(pact)
        : (isOverdue ? AppColors.accent : AppColors.darkBackground);
    final badgeText = isHistoryCard
        ? pact.timeRemainingFormatted
        : (isOverdue ? 'FAILED' : pact.timeRemainingFormatted);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPactDetails(pact),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showOverdue && isOverdue
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                    style: TextStyle(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d • h:mm a').format(pact.deadline),
                    style: TextStyle(color: secondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isHistoryCard
                    ? badgeColor.withValues(alpha: 0.2)
                    : (isOverdue
                          ? AppColors.accent.withValues(alpha: 0.2)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: isHistoryCard
                      ? badgeColor
                      : (isOverdue ? AppColors.accent : secondary),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PactProvider pactProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            pactProvider.errorMessage ?? 'Unable to load pacts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface),
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
              foregroundColor: onSurface,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final isActive = _dashboardTabIndex == 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.flag_outlined : Icons.history,
            size: 42,
            color: secondary,
          ),
          const SizedBox(height: 12),
          Text(
            isActive
                ? 'No active pacts right now'
                : 'No completed or failed pacts yet',
            style: TextStyle(
              color: onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? 'Create a pact to start your countdown and stay accountable.'
                : 'Completed and failed pacts will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildHeroHeader({required String name}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back, $name',
            style: TextStyle(fontSize: 16, color: secondary),
          ),
        ],
      ),
    );
  }

  String _statusBadgeLabel(PactModel pact) {
    switch (pact.status) {
      case PactStatus.active:
        return pact.isOverdue ? 'FAILED' : 'ONGOING';
      case PactStatus.completed:
        return 'COMPLETED';
      case PactStatus.failed:
        return 'FAILED';
      case PactStatus.verificationPending:
        return 'PENDING';
    }
  }

  Color _statusBadgeColor(PactModel pact) {
    switch (pact.status) {
      case PactStatus.active:
        return pact.isOverdue ? AppColors.accent : AppColors.primary;
      case PactStatus.completed:
        return AppColors.completed;
      case PactStatus.failed:
        return AppColors.accent;
      case PactStatus.verificationPending:
        return AppColors.warning;
    }
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
