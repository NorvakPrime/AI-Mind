import 'package:flutter/material.dart';

/// Информация о размышлениях модели
class AiReasoningInfo {
  const AiReasoningInfo({
    this.mandatory = false,
    this.defaultEnabled = false,
    this.defaultEffort,
    this.supportedEfforts = const [],
  });

  final bool mandatory;
  final bool defaultEnabled;
  final String? defaultEffort;
  final List<String> supportedEfforts;

  Map<String, dynamic> toMap() => {
        'mandatory': mandatory,
        'default_enabled': defaultEnabled,
        'default_effort': defaultEffort,
        'supported_efforts': supportedEfforts,
      };

  factory AiReasoningInfo.fromMap(Map<String, dynamic> m) {
    return AiReasoningInfo(
      mandatory: m['mandatory'] as bool? ?? false,
      defaultEnabled: m['default_enabled'] as bool? ?? false,
      defaultEffort: m['default_effort'] as String?,
      supportedEfforts: (m['supported_efforts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Модель с API: хранит id, имя и цены
class AiModel {
  const AiModel({
    required this.id,
    required this.name,
    this.promptPrice,
    this.completionPrice,
    this.reasoning,
    this.supportedParameters = const [],
  });
  final String id;
  final String name;
  final double? promptPrice; // $ за 1M токенов (вход)
  final double? completionPrice; // $ за 1M токенов (выход)
  final AiReasoningInfo? reasoning;
  final List<String> supportedParameters;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (promptPrice != null) 'promptPrice': promptPrice,
    if (completionPrice != null) 'completionPrice': completionPrice,
    if (reasoning != null) 'reasoning': reasoning!.toMap(),
    'supported_parameters': supportedParameters,
  };

  factory AiModel.fromMap(Map<String, dynamic> m) {
    double? parsePrice(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble() * 1000000; // per-token → per-1M
      if (v is String) {
        final cleaned = v.replaceAll(RegExp(r'[^0-9.]'), '');
        if (cleaned.isEmpty) return null;
        final parsed = double.tryParse(cleaned);
        if (parsed != null) return parsed * 1000000;
      }
      return null;
    }

    final pricing = m['pricing'] as Map<String, dynamic>?;
    final reasoningRaw = m['reasoning'] as Map<String, dynamic>?;

    // Сначала ищем в pricing (из API), затем в корне (из кэша)
    final promptP = pricing != null
        ? parsePrice(pricing['prompt'])
        : (m['promptPrice'] as num?)?.toDouble();

    final completionP = pricing != null
        ? parsePrice(pricing['completion'])
        : (m['completionPrice'] as num?)?.toDouble();

    return AiModel(
      id: m['id'] as String? ?? '',
      name: (m['name'] as String?) ?? (m['id'] as String? ?? ''),
      promptPrice: promptP,
      completionPrice: completionP,
      reasoning:
          reasoningRaw != null ? AiReasoningInfo.fromMap(reasoningRaw) : null,
      supportedParameters: (m['supported_parameters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Форматированная строка цены
  String? get priceLabel {
    if (promptPrice == null && completionPrice == null) return null;
    final p = promptPrice ?? 0;
    final c = completionPrice ?? 0;
    final d = String.fromCharCode(36); // dollar sign
    return 'In: $d${p.toStringAsFixed(4)} / Out: $d${c.toStringAsFixed(4)} per 1M tok';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AiModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Стартовый набор моделей (fallback)
final List<AiModel> kDefaultModels = [
  const AiModel(
    id: 'deepseek/deepseek-r1',
    name: 'DeepSeek R1',
    reasoning: AiReasoningInfo(
      supportedEfforts: ['max', 'high', 'medium', 'low', 'none'],
      defaultEffort: 'high',
      defaultEnabled: true,
    ),
  ),
  const AiModel(id: 'google/gemma-3-27b-it', name: 'Gemma 3 27B'),
  const AiModel(id: 'anthropic/claude-3.5-sonnet', name: 'Claude 3.5 Sonnet'),
  const AiModel(id: 'openai/gpt-4o', name: 'GPT-4o'),
];
