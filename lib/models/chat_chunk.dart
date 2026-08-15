class ChatChunk {
  ChatChunk({this.content, this.reasoning, this.toolCalls});
  final String? content;
  final String? reasoning;
  final List<dynamic>? toolCalls;
}
