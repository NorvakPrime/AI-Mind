/// Модель с API: хранит id, имя и цены
class AiModel {
  const AiModel({
    required this.id,
    required this.name,
    this.promptPrice,
    this.completionPrice,
  });
  final String id;
  final String name;
  final double? promptPrice; // $ за 1M токенов (вход)
  final double? completionPrice; // $ за 1M токенов (выход)

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (promptPrice != null) 'promptPrice': promptPrice,
    if (completionPrice != null) 'completionPrice': completionPrice,
  };

  factory AiModel.fromMap(Map<String, dynamic> m) {
    double? parsePrice(dynamic v) {
      if (v == null) return null;
      if (v is num) return v * 1000000; // per-token → per-1M
      if (v is String) {
        final cleaned = v.replaceAll(RegExp(r'[^0-9.]'), '');
        if (cleaned.isEmpty) return null;
        final parsed = double.tryParse(cleaned);
        if (parsed != null) return parsed * 1000000;
      }
      return null;
    }

    final pricing = m['pricing'] as Map<String, dynamic>?;
    return AiModel(
      id: m['id'] as String? ?? '',
      name: (m['name'] as String?) ?? (m['id'] as String? ?? ''),
      promptPrice: pricing != null ? parsePrice(pricing['prompt']) : null,
      completionPrice: pricing != null
          ? parsePrice(pricing['completion'])
          : null,
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
  const AiModel(id: 'deepseek/deepseek-r1', name: 'DeepSeek R1'),
  const AiModel(id: 'google/gemma-3-27b-it', name: 'Gemma 3 27B'),
  const AiModel(id: 'anthropic/claude-3.5-sonnet', name: 'Claude 3.5 Sonnet'),
  const AiModel(id: 'openai/gpt-4o', name: 'GPT-4o'),
];
