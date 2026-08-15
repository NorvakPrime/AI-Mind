class Message {
  Message(
    this.text, {
    required this.fromUser,
    this.timestamp,
    this.thought,
    this.toolCalls,
    this.toolResult,
    this.toolCallId,
    this.toolCallProgress,
    this.toolCallName,
    this.toolCallArgs,
    this.toolCallStartTime,
    this.mediaPath,
    this.mediaType,
  });
  final String text;
  final bool fromUser;
  final DateTime? timestamp;
  final String? thought;
  final List<dynamic>? toolCalls;
  final String? toolResult;
  final String? toolCallId;
  /// Progress map: {callId: 0.0..1.0} for downloads
  final Map<String, double>? toolCallProgress;
  /// Function name (e.g. 'getVideoInfo')
  final String? toolCallName;
  /// Function arguments as JSON string
  final String? toolCallArgs;
  /// Start time of download (for progress estimation)
  final DateTime? toolCallStartTime;
  /// Path to image or video file
  final String? mediaPath;
  /// 'image' or 'video'
  final String? mediaType;

  Message copyWith({
    String? text,
    bool? fromUser,
    DateTime? timestamp,
    String? thought,
    List<dynamic>? toolCalls,
    String? toolResult,
    String? toolCallId,
    Map<String, double>? toolCallProgress,
    String? toolCallName,
    String? toolCallArgs,
    DateTime? toolCallStartTime,
    String? mediaPath,
    String? mediaType,
  }) {
    return Message(
      text ?? this.text,
      fromUser: fromUser ?? this.fromUser,
      timestamp: timestamp ?? this.timestamp,
      thought: thought ?? this.thought,
      toolCalls: toolCalls ?? this.toolCalls,
      toolResult: toolResult ?? this.toolResult,
      toolCallId: toolCallId ?? this.toolCallId,
      toolCallProgress: toolCallProgress ?? this.toolCallProgress,
      toolCallName: toolCallName ?? this.toolCallName,
      toolCallArgs: toolCallArgs ?? this.toolCallArgs,
      toolCallStartTime: toolCallStartTime ?? this.toolCallStartTime,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'fromUser': fromUser,
        'timestamp': timestamp?.toIso8601String(),
        if (thought != null) 'thought': thought,
        if (toolCalls != null) 'toolCalls': toolCalls,
        if (toolResult != null) 'toolResult': toolResult,
        if (toolCallId != null) 'toolCallId': toolCallId,
        if (toolCallProgress != null) 'toolCallProgress': toolCallProgress,
        if (toolCallName != null) 'toolCallName': toolCallName,
        if (toolCallArgs != null) 'toolCallArgs': toolCallArgs,
        if (toolCallStartTime != null) 'toolCallStartTime': toolCallStartTime!.toIso8601String(),
        if (mediaPath != null) 'mediaPath': mediaPath,
        if (mediaType != null) 'mediaType': mediaType,
      };

  factory Message.fromMap(Map<String, dynamic> m) => Message(
        m['text'] as String? ?? '',
        fromUser: m['fromUser'] as bool? ?? false,
        timestamp: m['timestamp'] != null
            ? DateTime.tryParse(m['timestamp'] as String)
            : null,
        thought: m['thought'] as String?,
        toolCalls: m['toolCalls'] as List<dynamic>?,
        toolResult: m['toolResult'] as String?,
        toolCallId: m['toolCallId'] as String?,
        toolCallProgress: m['toolCallProgress'] != null
            ? (m['toolCallProgress'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v.toDouble()))
            : null,
        toolCallName: m['toolCallName'] as String?,
        toolCallArgs: m['toolCallArgs'] as String?,
        toolCallStartTime: m['toolCallStartTime'] != null
            ? DateTime.tryParse(m['toolCallStartTime'] as String)
            : null,
        mediaPath: m['mediaPath'] as String?,
        mediaType: m['mediaType'] as String?,
      );
}
