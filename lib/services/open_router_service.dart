import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_model.dart';
import '../models/message.dart';

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
      // Игнорируем приветственное сообщение бота, если оно первое и системное
      // Но в нашем случае мы просто шлем всю историю.
      if (msg.text.isEmpty) continue;
      result.add({
        'role': msg.fromUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    return result;
  }

  /// Отправить сообщение (обычный, без стриминга)
  Future<String> sendMessage({
    required String apiKey,
    required String modelId,
    required List<Message> history,
    String? systemPrompt,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': modelId,
            'messages': _buildMessagesJson(history, systemPrompt),
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Ошибка ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) throw Exception('Пустой ответ от модели.');
    final content =
        (choices.first as Map<String, dynamic>)['message']
            as Map<String, dynamic>;
    return (content['content'] as String?)?.trim() ?? '';
  }

  /// Отправить сообщение с SSE-стримингом
  Stream<String> sendMessageStream({
    required String apiKey,
    required String modelId,
    required List<Message> history,
    String? systemPrompt,
  }) async* {
    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/chat/completions'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({
      'model': modelId,
      'messages': _buildMessagesJson(history, systemPrompt),
      'stream': true,
    });

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Ошибка ${response.statusCode}: $body');
    }

    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final index = buffer.indexOf('\n');
        final line = buffer.substring(0, index).trim();
        buffer = buffer.substring(index + 1);

        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>? ?? [];
            if (choices.isEmpty) continue;
            final delta =
                (choices.first as Map<String, dynamic>)['delta']
                    as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            // Пропускаем невалидные строки
          }
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
