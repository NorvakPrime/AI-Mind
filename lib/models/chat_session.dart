import 'message.dart';

/// Сессия чата
class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.systemPrompt,
    List<Message>? messages,
  }) : messages = messages ?? [];

  final String id;
  String title;
  final DateTime createdAt;
  final List<Message> messages;
  String? systemPrompt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toMap()).toList(),
    if (systemPrompt != null) 'systemPrompt': systemPrompt,
  };

  factory ChatSession.fromMap(Map<String, dynamic> m) => ChatSession(
    id: m['id'] as String? ?? '',
    title: m['title'] as String? ?? 'Новый чат',
    createdAt: m['createdAt'] != null
        ? DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    messages: (m['messages'] as List<dynamic>? ?? [])
        .map((e) => Message.fromMap(e as Map<String, dynamic>))
        .toList(),
    systemPrompt: m['systemPrompt'] as String?,
  );

  String get displayTitle {
    if (title.isNotEmpty && title != 'Новый чат') return title;
    final userMsg = messages.firstWhere(
      (m) => m.fromUser && m.text.isNotEmpty,
      orElse: () => const Message('', fromUser: true),
    );
    if (userMsg.text.isNotEmpty) {
      return userMsg.text.length > 40
          ? '${userMsg.text.substring(0, 40)}…'
          : userMsg.text;
    }
    return 'Новый чат';
  }

  String get lastMessagePreview {
    if (messages.isEmpty) return 'Пустой чат';
    final last = messages.last;
    final preview = last.text.length > 60
        ? '${last.text.substring(0, 60)}…'
        : last.text;
    return preview.isEmpty ? '…' : preview;
  }
}
