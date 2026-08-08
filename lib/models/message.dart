class Message {
  const Message(
    this.text, {
    required this.fromUser,
    this.timestamp,
    this.thought,
  });
  final String text;
  final bool fromUser;
  final DateTime? timestamp;
  final String? thought;

  Map<String, dynamic> toMap() => {
        'text': text,
        'fromUser': fromUser,
        'timestamp': timestamp?.toIso8601String(),
        if (thought != null) 'thought': thought,
      };

  factory Message.fromMap(Map<String, dynamic> m) => Message(
        m['text'] as String? ?? '',
        fromUser: m['fromUser'] as bool? ?? false,
        timestamp: m['timestamp'] != null
            ? DateTime.tryParse(m['timestamp'] as String)
            : null,
        thought: m['thought'] as String?,
      );
}
