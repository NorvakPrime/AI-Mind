import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_model.dart';
import '../models/message.dart';
import '../utils/logger.dart';

class OpenRouterService {
  OpenRouterService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _baseUrl = 'https://openrouter.ai/api/v1';

  List<Map<String, String>> _buildMessagesJson(
    List<Message> messages,
    String? systemPrompt,
  ) {
    final List<Map<String, String>> result = [];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      result.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in messages) {
      // Игнорируем мысли (thought), отправляем только основной текст.
      // Дополнительно очищаем текст от тегов <think>, если они там вдруг остались.
      String cleanText = msg.text
          .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
          .replaceAll(RegExp(r'<think>.*$', dotAll: true), '')
          .trim();

      if (cleanText.isEmpty && !msg.fromUser) continue;

      result.add({
        'role': msg.fromUser ? 'user' : 'assistant',
        'content': cleanText,
      });
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
  Future<String> sendMessage({
    required String apiKey,
    required String modelId,
    required List<Message> history,
    String? systemPrompt,
    Map<String, dynamic>? reasoning,
    bool includeReasoning = false,
  }) async {
    final url = '$_baseUrl/chat/completions';
    final body = {
      'model': modelId,
      'messages': _buildMessagesJson(history, systemPrompt),
      if (reasoning != null) 'reasoning': reasoning,
      if (includeReasoning) 'include_reasoning': true,
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

    final message =
        (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>;

    final content = message['content'] as String?;
    final reasoningText = _extractReasoning(message);

    if (reasoningText != null && reasoningText.trim().isNotEmpty) {
      return '<think>\n${reasoningText.trim()}\n</think>\n\n${content?.trim() ?? ''}';
    }

    return content?.trim() ?? '';
  }

  /// Отправить сообщение с SSE-стримингом
  Stream<String> sendMessageStream({
    required String apiKey,
    required String modelId,
    required List<Message> history,
    String? systemPrompt,
    Map<String, dynamic>? reasoning,
    bool includeReasoning = false,
  }) async* {
    final url = '$_baseUrl/chat/completions';
    final body = {
      'model': modelId,
      'messages': _buildMessagesJson(history, systemPrompt),
      'stream': true,
      if (reasoning != null) 'reasoning': reasoning,
      if (includeReasoning) 'include_reasoning': true,
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
            if (hasReasoning) yield '\n</think>\n';
            return;
          }
          try {
            AppLogger.log('Raw SSE Data: $data', tag: 'SSE_RAW');
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>? ?? [];
            if (choices.isEmpty) continue;

            final delta =
                (choices.first as Map<String, dynamic>)['delta']
                    as Map<String, dynamic>?;
            if (delta == null) continue;

            final rContent = _extractReasoning(delta);
            final content = delta['content'] as String?;

            if (rContent != null && rContent.isNotEmpty) {
              if (!hasReasoning) {
                hasReasoning = true;
                AppLogger.log('Reasoning started...', tag: 'STREAM');
                yield '<think>\n';
              }
              AppLogger.log('Reasoning chunk: $rContent', tag: 'STREAM');
              yield rContent;
            } else if (content != null && content.isNotEmpty) {
              if (hasReasoning) {
                hasReasoning = false;
                AppLogger.log('Reasoning ended.', tag: 'STREAM');
                yield '\n</think>\n\n';
              }
              AppLogger.log('Content chunk: $content', tag: 'STREAM');
              yield content;
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
