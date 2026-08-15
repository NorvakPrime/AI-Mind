import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/translations.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';
import '../utils/animations.dart';
import '../utils/logger.dart';

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
    final l10n = Translations.of(context);
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
          Text(
            l10n.startDialog,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.askAnything,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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

    // Используем отдельное поле для мыслей, если оно есть.
    // Если нет (например, при стриминге), пытаемся распарсить из текста.
    String? thought = message.thought;
    String content = message.text;

    if (!isUser && thought == null) {
      final thinkRegex = RegExp(r'<think>(.*?)(?:</think>|$)', dotAll: true);
      final match = thinkRegex.firstMatch(message.text);
      if (match != null) {
        thought = match.group(1)?.trim();
        content = message.text.replaceFirst(thinkRegex, '').trim();
        AppLogger.log('Found reasoning in text: ${thought?.length} chars',
            tag: 'UI');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[_buildAvatar(), const SizedBox(width: 10)],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (thought != null && thought.isNotEmpty)
                      _ThoughtBlock(thought: thought),
                    if (content.isNotEmpty || isUser || message.mediaPath != null)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 560),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.userBubble
                              : AppColors.botBubble,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.mediaPath != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _MediaDisplay(
                                  path: message.mediaPath!,
                                  type: message.mediaType ?? 'image',
                                ),
                              ),
                            if (content.isNotEmpty)
                              MarkdownBody(
                                data: content,
                                selectable: true,
                                onTapLink: (text, href, title) {
                                  if (href != null) {
                                    final uri = Uri.tryParse(href);
                                    if (uri != null) {
                                      launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  }
                                },
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
                                      left:
                                          BorderSide(color: AppColors.accent, width: 3),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // Tool calls
                    if (message.toolCallId != null && message.toolCallName != null)
                      _ToolCallBlock(
                        callId: message.toolCallId!,
                        callName: message.toolCallName!,
                        callArgs: message.toolCallArgs,
                        result: message.toolResult,
                        progress: message.toolCallProgress?[message.toolCallId],
                      ),
                  ],
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
                    label: Translations.of(context).editResponseShort,
                    onTap: () => _showEditDialog(context),
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    label: Translations.of(context).regenerate,
                    onTap: onRegenerate,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: Translations.of(context).delete,
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
    final l10n = Translations.of(context);
    final controller = TextEditingController(text: message.text);
    showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          l10n.editResponse,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          maxLines: 10,
          minLines: 1,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: l10n.messageHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onEdit?.call(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(
              l10n.save,
              style: const TextStyle(color: Colors.white),
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

// ───────────────────────── Блок размышлений ─────────────────────────

class _ThoughtBlock extends StatefulWidget {
  const _ThoughtBlock({required this.thought});
  final String thought;

  @override
  State<_ThoughtBlock> createState() => _ThoughtBlockState();
}

class _ThoughtBlockState extends State<_ThoughtBlock> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = Translations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceBorder.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isExpanded
                          ? Icons.lightbulb_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: _isExpanded
                          ? AppColors.accentLight
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.thought,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isExpanded
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: MarkdownBody(
                  data: widget.thought,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
                decoration: InputDecoration(
                  hintText: Translations.of(context).messageHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
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
                backgroundColor: _hasText ? AppColors.accent : AppColors.surface,
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

// ───────────────────────── Блок вызова функции ─────────────────────────

class _ToolCallBlock extends StatefulWidget {
  const _ToolCallBlock({
    required this.callId,
    required this.callName,
    this.callArgs,
    this.result,
    this.progress,
    this.startTime,
  });

  final String callId;
  final String callName;
  final String? callArgs;
  final String? result;
  final double? progress;
  final DateTime? startTime;

  @override
  State<_ToolCallBlock> createState() => _ToolCallBlockState();
}

class _ToolCallBlockState extends State<_ToolCallBlock> {
  bool _isExpanded = false;
  Timer? _etaTimer;
  double? _etaSeconds;

  @override
  void initState() {
    super.initState();
    if (widget.startTime != null) {
      _startEtaTimer();
    }
  }

  @override
  void didUpdateWidget(_ToolCallBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != null && _etaTimer == null) {
      _startEtaTimer();
    }
  }

  void _startEtaTimer() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.progress != null && widget.progress! > 0 && widget.progress! < 1.0 && widget.startTime != null) {
        final elapsed = DateTime.now().difference(widget.startTime!).inSeconds;
        if (elapsed > 2) { // Wait for a few seconds to get stable ETA
          final totalSeconds = (elapsed / widget.progress!).round();
          final remaining = totalSeconds - elapsed;
          setState(() => _etaSeconds = remaining.toDouble());
        }
      } else if (widget.progress == 1.0) {
        _etaTimer?.cancel();
        _etaTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  String _formatEta(double? seconds) {
    if (seconds == null || seconds.isNegative || !seconds.isFinite) return '...';
    if (seconds < 60) return '${seconds.round()}s';
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).round();
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Translations.of(context);
    final isDownloading = widget.callName.contains('download');
    final isComplete = widget.progress == 1.0 || widget.result != null;
    bool isError = false;
    if (widget.result != null) {
      try {
        final res = jsonDecode(widget.result!);
        // Ошибка, только если поле error существует и не равно null
        isError = res is Map && res['error'] != null;
      } catch (_) {
        // Резервный вариант на случай невалидного JSON
        isError = widget.result!.contains('"error":');
      }
    }
    final isRunning = !isComplete;



    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red.withValues(alpha: 0.3) : AppColors.surfaceBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isDownloading ? Icons.download_rounded : Icons.terminal_rounded,
                    size: 16,
                    color: isError ? Colors.red : (isComplete ? Colors.green : AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.get('tool_call')}: ${widget.callName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        if (isRunning)
                          Text(
                            widget.progress != null 
                                ? '${(widget.progress! * 100).toInt()}% • ETA: ${_formatEta(_etaSeconds)}'
                                : l10n.get('tool_call_running'),
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          )
                        else if (isComplete)
                          Text(
                            l10n.get('tool_call_completed'),
                            style: const TextStyle(fontSize: 10, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                  if (isRunning)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    )
                  else if (isComplete)
                    Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 16, color: isError ? Colors.red : Colors.green),
                  const SizedBox(width: 8),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (isRunning && widget.progress != null && widget.progress! > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: AppColors.surface,
                color: AppColors.accent,
                minHeight: 2,
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 12, color: AppColors.surfaceBorder),
                        if (widget.callArgs != null) ...[
                          Text(l10n.get('tool_call_params'), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.callArgs!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary)),
                        ],
                        if (widget.result != null) ...[
                          const SizedBox(height: 8),
                          Text(l10n.get('tool_call_result'), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            widget.result!,
                            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isError ? Colors.redAccent : Colors.greenAccent),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Отображение Медиа ─────────────────────────

class _MediaDisplay extends StatelessWidget {
  const _MediaDisplay({required this.path, required this.type});
  final String path;
  final String type;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 8), Text('File not found', style: TextStyle(color: Colors.red))]),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: type == 'video' ? _VideoPlayerWidget(path: path) : Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48)),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({required this.path});
  final String path;

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> with AutomaticKeepAliveClientMixin {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: const VideoControllerConfiguration(
      enableHardwareAcceleration: false, // <-- Force software rendering in Flutter texture
    ),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    // Disable hardware acceleration as requested to avoid driver issues (like libcuda errors)
    try {
      if (player.platform is NativePlayer) {
        final native = player.platform as NativePlayer;
        // 'no' = полностью программное декодирование (CPU), никакого CUDA/NVDEC/VAAPI
        await native.setProperty('hwdec', 'no');
      }
    } catch (e) {
      debugPrint('Error setting player properties: $e');
    }

    await player.open(Media(widget.path), play: false);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Video(controller: controller),
          _VideoControls(player: player, path: widget.path),
        ],
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.player, required this.path});
  final Player player;
  final String path;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _playing = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.player.stream.playing.listen((p) {
      if (mounted) setState(() => _playing = p);
    });
  }

  void _togglePlay() {
    widget.player.playOrPause();
    _resetHideTimer();
  }

  void _resetHideTimer() {
    setState(() => _showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  Future<void> _openExternal() async {
    final uri = Uri.file(widget.path);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch ${widget.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetHideTimer,
      behavior: HitTestBehavior.translucent,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black26,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                  onPressed: _openExternal,
                  tooltip: 'Open in system player',
                ),
              ),
              IconButton(
                iconSize: 48,
                icon: Icon(
                  _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: _togglePlay,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.path.split('/').last,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}
