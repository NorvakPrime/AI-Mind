import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_model.dart';
import '../models/chat_chunk.dart';
import '../models/message.dart';
import '../utils/logger.dart';

class OpenRouterService {
  OpenRouterService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _baseUrl = 'https://openrouter.ai/api/v1';

  List<Map<String, dynamic>> _buildMessagesJson(
    List<Message> messages,
    String? systemPrompt,
  ) {
    final List<Map<String, dynamic>> result = [];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      result.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in messages) {
      if (msg.toolResult != null) {
        result.add({
          'role': 'tool',
          'content': msg.toolResult,
          'tool_call_id': msg.toolCallId,
        });
        continue;
      }

      // Игнорируем мысли (thought), отправляем только основной текст.
      String cleanText = msg.text
          .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
          .replaceAll(RegExp(r'<think>.*$', dotAll: true), '')
          .trim();

      if (cleanText.isEmpty && !msg.fromUser && msg.toolCalls == null) continue;

      final Map<String, dynamic> map = {
        'role': msg.fromUser ? 'user' : 'assistant',
        'content': cleanText,
      };

      if (msg.toolCalls != null) {
        map['tool_calls'] = msg.toolCalls;
      }

      result.add(map);
    }
    return result;
  }

  /// Извлечь текст размышлений из различных форматов ответа
  String? _extractReasoning(Map<String, dynamic> data) {
    // 1. reasoning_details (List) - Современный формат
    final details = data['reasoning_details'] as List<dynamic>?;
    if (details != null && details.isNotEmpty) {
      String collected = "";
      for (final d in details) {
        if (d is Map<String, dynamic>) {
          final type = d['type'];
          if (type == 'reasoning.text') {
            collected += (d['text'] ?? "").toString();
          } else if (type == 'reasoning.summary') {
            collected += (d['summary'] ?? "").toString();
          }
        }
      }
      if (collected.isNotEmpty) return collected;
    }

    // 2. reasoning_content или reasoning (String) - Стандарт/Legacy
    final r = data['reasoning_content'] ?? data['reasoning'];
    if (r is String && r.isNotEmpty) return r;

    return null;
  }

  /// Отправить сообщение (обычный, без стриминга)
  Future<Message> sendMessage({
    required String apiKey,
    required String modelId,
    required List<Message> history,
    String? systemPrompt,
    Map<String, dynamic>? reasoning,
    bool includeReasoning = false,
    List<Map<String, dynamic>>? tools,
  }) async {
    final url = '$_baseUrl/chat/completions';
    final body = {
      'model': modelId,
      'messages': _buildMessagesJson(history, systemPrompt),
      if (reasoning != null) 'reasoning': reasoning,
      if (includeReasoning) 'include_reasoning': true,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
    };

    AppLogger.request(url, body);

    final response = await _client
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      AppLogger.error('API Error ${response.statusCode}', response.body);
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }

    AppLogger.response(url, response.body);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) throw Exception('Пустой ответ от модели.');

    final messageMap =
        (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>;

    final content = messageMap['content'] as String? ?? "";
    final toolCalls = messageMap['tool_calls'] as List<dynamic>?;
    
    // Пытаемся извлечь мысли из спец. полей
    String? reasoningText = _extractReasoning(messageMap);
    String finalContent = content;

    // Если в спец. полях пусто, пробуем вытащить из текста
    if (reasoningText == null || reasoningText.isEmpty) {
      final thinkRegex = RegExp(r'<think>(.*?)(?:</think>|$)', dotAll: true);
      final match = thinkRegex.firstMatch(content);
      if (match != null) {
        reasoningText = match.group(1)?.trim();
        finalContent = content.replaceFirst(thinkRegex, '').trim();
      }
    }

    return Message(
      finalContent,
      fromUser: false,
      timestamp: DateTime.now(),
      thought: reasoningText,
      toolCalls: toolCalls,
    );
  }

  /// Отправить сообщение с SSE-стримингом
  Stream<ChatChunk> sendMessageStream({
    required String apiKey,
    required String modelId,
    required List<Message> history,
    String? systemPrompt,
    Map<String, dynamic>? reasoning,
    bool includeReasoning = false,
    List<Map<String, dynamic>>? tools,
  }) async* {
    final url = '$_baseUrl/chat/completions';
    final body = {
      'model': modelId,
      'messages': _buildMessagesJson(history, systemPrompt),
      'stream': true,
      if (reasoning != null) 'reasoning': reasoning,
      if (includeReasoning) 'include_reasoning': true,
      if (tools != null && tools.isNotEmpty) 'tools': tools,
    };

    AppLogger.request('$url (STREAM)', body);

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode(body);

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      final bodyText = await response.stream.bytesToString();
      AppLogger.error('API Stream Error ${response.statusCode}', bodyText);
      throw Exception('Ошибка ${response.statusCode}: $bodyText');
    }

    String buffer = '';
    bool hasReasoning = false;

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final index = buffer.indexOf('\n');
        final line = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 1);

        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            if (hasReasoning) yield ChatChunk(content: '\n</think>\n');
            return;
          }
          try {

            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>? ?? [];
            if (choices.isEmpty) continue;

            final delta =
                (choices.first as Map<String, dynamic>)['delta']
                    as Map<String, dynamic>?;
            if (delta == null) continue;

            final rContent = _extractReasoning(delta);
            final content = delta['content'] as String?;
            final toolCalls = delta['tool_calls'] as List<dynamic>?;

            if (toolCalls != null) {
              yield ChatChunk(toolCalls: toolCalls);
            }

            if (rContent != null && rContent.isNotEmpty) {
              if (!hasReasoning) {
                hasReasoning = true;
                yield ChatChunk(content: '<think>\n');
              }
              yield ChatChunk(reasoning: rContent);
            } else if (content != null && content.isNotEmpty) {
              if (hasReasoning) {
                hasReasoning = false;
                yield ChatChunk(content: '\n</think>\n\n');
              }
              yield ChatChunk(content: content);
            }
          } catch (_) {}
        }
      }
    }
  }

  /// Получить список текстовых моделей
  Future<List<AiModel>> fetchModels(String apiKey) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/models?output_modalities=text'),
          headers: {'Authorization': 'Bearer $apiKey'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Ошибка ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final models = data['data'] as List<dynamic>? ?? [];
    return models
        .map((m) {
          final map = m as Map<String, dynamic>;
          return AiModel.fromMap(map);
        })
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  /// Получить остаток баланса
  Future<double> fetchBalance(String apiKey) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/credits'),
          headers: {'Authorization': 'Bearer $apiKey'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Ошибка ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final totalCredits = (data['data']?['total_credits'] as num?) ?? 0;
    final totalUsage = (data['data']?['total_usage'] as num?) ?? 0;
    return totalCredits.toDouble() - totalUsage.toDouble();
  }
}
