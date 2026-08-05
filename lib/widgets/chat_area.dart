import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/message.dart';
import '../theme/app_colors.dart';
import '../utils/animations.dart';

// ───────────────────────── Область чата ─────────────────────────

class ChatArea extends StatelessWidget {
  const ChatArea({
    super.key,
    required this.messages,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onEditMessage,
    required this.onRegenerate,
    required this.onDeleteMessage,
  });

  final List<Message> messages;
  final TextEditingController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final bool isLoading;
  final Future<void> Function() onSend;
  final Function(int index, String newText) onEditMessage;
  final VoidCallback onRegenerate;
  final Function(int index) onDeleteMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Column(
          children: [
            // ── Сообщения ──
            Expanded(
              child: messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => MessageBubble(
                        message: messages[i],
                        isLast: i == messages.length - 1,
                        onEdit: (newText) => onEditMessage(i, newText),
                        onRegenerate: onRegenerate,
                        onDelete: () => onDeleteMessage(i),
                      ),
                    ),
            ),

            // ── Поле ввода ──
            InputBar(
              controller: controller,
              focusNode: focusNode,
              isLoading: isLoading,
              onSend: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Пустое состояние ─────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Начните диалог',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Задайте любой вопрос',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Пузырь сообщения ─────────────────────────

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.isLast = false,
    this.onEdit,
    this.onRegenerate,
    this.onDelete,
  });

  final Message message;
  final bool isLast;
  final Function(String)? onEdit;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    final showActions = !isUser && isLast;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[_buildAvatar(), const SizedBox(width: 10)],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.userBubble : AppColors.botBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.accentDim.withValues(alpha: 0.3)
                          : AppColors.surfaceBorder.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  child: MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14.5,
                        height: 1.55,
                        color: isUser
                            ? AppColors.textPrimary
                            : AppColors.textPrimary.withValues(alpha: 0.9),
                      ),
                      em: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isUser
                            ? const Color(0xFFADFFD1)
                            : AppColors.accentLight,
                        letterSpacing: 0.2,
                      ),
                      code: const TextStyle(
                        backgroundColor: AppColors.bg,
                        color: AppColors.accentLight,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.surfaceBorder,
                          width: 0.5,
                        ),
                      ),
                      blockquote: const TextStyle(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.accent, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser) ...[const SizedBox(width: 10), _buildUserAvatar()],
            ],
          ),
          if (showActions)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Изм.',
                    onTap: () => _showEditDialog(context),
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Ещё раз',
                    onTap: onRegenerate,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Удалить',
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text(
          'Редактировать ответ',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          maxLines: 10,
          minLines: 1,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(hintText: 'Текст сообщения...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onEdit?.call(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text(
              'Сохранить',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 16,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Поле ввода ─────────────────────────

class InputBar extends StatefulWidget {
  const InputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final Future<void> Function() onSend;

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Кнопка прикрепить
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 22),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppColors.surfaceBorder,
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 10),

          // Поле ввода
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.4,
                ),
                cursorColor: AppColors.accent,
                onSubmitted: (_) => widget.onSend(),
                enabled: !widget.isLoading,
                decoration: const InputDecoration(
                  hintText: 'Сообщение…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Кнопка отправить
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              onPressed: widget.isLoading
                  ? null
                  : (_hasText ? widget.onSend : null),
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: _hasText ? Colors.white : AppColors.textMuted,
                    ),
              style: IconButton.styleFrom(
                backgroundColor: _hasText
                    ? AppColors.accent
                    : AppColors.surface,
                disabledBackgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: _hasText
                      ? BorderSide.none
                      : const BorderSide(
                          color: AppColors.surfaceBorder,
                          width: 0.5,
                        ),
                ),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
