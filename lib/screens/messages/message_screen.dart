import 'package:flutter/material.dart';

import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/time_label.dart';
import '../../widgets/common/avatar.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({
    super.key,
    required this.currentUserId,
    required this.friend,
  });

  final String currentUserId;
  final UserModel friend;

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    await _firestoreService.markConversationAsRead(
      currentUserId: widget.currentUserId,
      friendUserId: widget.friend.userId,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    final isLocked = await _firestoreService.userHasPendingConsequence(
      widget.currentUserId,
    );
    if (isLocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chat is locked until your pending consequence is approved.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _firestoreService.sendMessage(
        senderId: widget.currentUserId,
        recipientId: widget.friend.userId,
        text: text,
      );
      _messageController.clear();
      await _markRead();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send message right now.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            AppAvatar(imageUrl: widget.friend.profilePictureUrl, radius: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.displayName ??
                        widget.friend.username ??
                        'Friend',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((widget.friend.username ?? '').isNotEmpty)
                    Text(
                      '@${widget.friend.username}',
                      style: AppTypography.caption.copyWith(color: secondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _firestoreService.streamChatMessages(
                currentUserId: widget.currentUserId,
                friendUserId: widget.friend.userId,
              ),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessageModel>[];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markRead();
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hello 👋',
                      style: AppTypography.bodyMedium.copyWith(
                        color: secondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == widget.currentUserId;

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        constraints: const BoxConstraints(maxWidth: 290),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppElevation.radiusMedium,
                          ),
                          boxShadow: isMine ? AppElevation.shadowSmall : null,
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isMine ? Colors.white : onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              TimeLabel.formatRelativeShort(message.createdAt),
                              style: AppTypography.labelSmall.copyWith(
                                color: (isMine ? Colors.white : onSurface)
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppElevation.inputRadius,
                        boxShadow: AppElevation.shadowSmall,
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        style: AppTypography.bodyMedium.copyWith(
                          color: onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: secondary,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
