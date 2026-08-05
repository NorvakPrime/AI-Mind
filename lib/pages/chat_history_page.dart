import 'package:flutter/material.dart';

import '../models/chat_session.dart';
import '../theme/app_colors.dart';
import '../utils/animations.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({
    super.key,
    required this.sessions,
    required this.activeSessionId,
    required this.onSelect,
    required this.onNewChat,
    required this.onDelete,
  });

  final List<ChatSession> sessions;
  final String activeSessionId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNewChat;
  final ValueChanged<String> onDelete;

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Чаты',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textSecondary,
        ),
        actions: [
          IconButton(
            onPressed: widget.onNewChat,
            icon: const Icon(
              Icons.edit_square,
              size: 20,
              color: AppColors.accent,
            ),
            tooltip: 'Новый чат',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Нет чатов',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.sessions.length,
              itemBuilder: (_, i) {
                final s = widget.sessions[i];
                final isActive = s.id == widget.activeSessionId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: isActive
                        ? AppColors.surfaceLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => widget.onSelect(s.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.accent.withValues(alpha: 0.4)
                                : AppColors.surfaceBorder.withValues(
                                    alpha: 0.5,
                                  ),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.surfaceBorder.withValues(
                                        alpha: 0.3,
                                      ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.chat_bubble_rounded,
                                size: 17,
                                color: isActive
                                    ? AppColors.accent
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isActive
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    s.lastMessagePreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _showDeleteConfirmation(context, s),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatSession session) {
    showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Удалить чат?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Text(
          'Вы уверены, что хотите удалить чат "${session.displayTitle}"? Это действие нельзя отменить.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(session.id);
              // Вызываем setState, чтобы перерисовать список в истории
              setState(() {});
            },
            child: const Text(
              'Удалить',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
