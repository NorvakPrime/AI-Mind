import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_model.dart';
import '../models/chat_session.dart';

class SettingsService {
  static const _kApiToken = 'api_token';
  static const _kModelId = 'model_id';
  static const _kTemperature = 'temperature';
  static const _kTopP = 'top_p';
  static const _kMaxTokens = 'max_tokens';
  static const _kStreaming = 'streaming';
  static const _kCachedModels = 'cached_models';
  static const _kChatSessions = 'chat_sessions';
  static const _kActiveChatId = 'active_chat_id';
  static const _kNsfwDefault = 'nsfw_default';
  static const _kLanguageDefault = 'language_default';
  static const _kReasoningEffort = 'reasoning_effort';
  static const _kReasoningSummary = 'reasoning_summary';
  static const _kTutorialComplete = 'tutorial_complete';

  final SharedPreferences _prefs;
  SettingsService(this._prefs);

  // ── Токен ──
  String get apiToken => _prefs.getString(_kApiToken) ?? '';
  Future<void> setApiToken(String v) => _prefs.setString(_kApiToken, v);

  // ── Модель (id) ──
  String get modelId => _prefs.getString(_kModelId) ?? kDefaultModels.first.id;
  Future<void> setModelId(String v) => _prefs.setString(_kModelId, v);

  // ── Температура ──
  double get temperature => _prefs.getDouble(_kTemperature) ?? 0.7;
  Future<void> setTemperature(double v) => _prefs.setDouble(_kTemperature, v);

  // ── Top P ──
  double get topP => _prefs.getDouble(_kTopP) ?? 0.9;
  Future<void> setTopP(double v) => _prefs.setDouble(_kTopP, v);

  // ── Макс. токенов ──
  double get maxTokens => _prefs.getDouble(_kMaxTokens) ?? 2048;
  Future<void> setMaxTokens(double v) => _prefs.setDouble(_kMaxTokens, v);

  // ── Потоковые ответы ──
  bool get streaming => _prefs.getBool(_kStreaming) ?? false;
  Future<void> setStreaming(bool v) => _prefs.setBool(_kStreaming, v);

  // ── Кэш моделей ──
  List<AiModel> get cachedModels {
    final raw = _prefs.getString(_kCachedModels);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((m) => AiModel.fromMap(m as Map<String, dynamic>))
          .where((m) => m.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setCachedModels(List<AiModel> models) {
    final json = jsonEncode(models.map((m) => m.toMap()).toList());
    return _prefs.setString(_kCachedModels, json);
  }

  // ── Сессии чатов ──
  List<ChatSession> get chatSessions {
    final raw = _prefs.getString(_kChatSessions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((m) => ChatSession.fromMap(m as Map<String, dynamic>))
          .where((s) => s.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setChatSessions(List<ChatSession> sessions) {
    final json = jsonEncode(sessions.map((s) => s.toMap()).toList());
    return _prefs.setString(_kChatSessions, json);
  }

  // ── Активный чат ──
  String get activeChatId => _prefs.getString(_kActiveChatId) ?? '';
  Future<void> setActiveChatId(String v) => _prefs.setString(_kActiveChatId, v);

  // ── NSFW по умолчанию ──
  bool get nsfwDefault => _prefs.getBool(_kNsfwDefault) ?? false;
  Future<void> setNsfwDefault(bool v) => _prefs.setBool(_kNsfwDefault, v);

  // ── Язык по умолчанию ──
  String get languageDefault => _prefs.getString(_kLanguageDefault) ?? 'Auto';
  Future<void> setLanguageDefault(String v) =>
      _prefs.setString(_kLanguageDefault, v);

  // ── Reasoning Effort ──
  String? get reasoningEffort => _prefs.getString(_kReasoningEffort);
  Future<void> setReasoningEffort(String? v) => v == null
      ? _prefs.remove(_kReasoningEffort)
      : _prefs.setString(_kReasoningEffort, v);

  // ── Reasoning Summary ──
  String? get reasoningSummary => _prefs.getString(_kReasoningSummary);
  Future<void> setReasoningSummary(String? v) => v == null
      ? _prefs.remove(_kReasoningSummary)
      : _prefs.setString(_kReasoningSummary, v);

  // ── Tutorial ──
  bool get isTutorialComplete => _prefs.getBool(_kTutorialComplete) ?? false;
  Future<void> setTutorialComplete(bool v) =>
      _prefs.setBool(_kTutorialComplete, v);

  // ── Сброс ──
  Future<void> clear() async {
    await _prefs.remove(_kApiToken);
    await _prefs.remove(_kModelId);
    await _prefs.remove(_kTemperature);
    await _prefs.remove(_kTopP);
    await _prefs.remove(_kMaxTokens);
    await _prefs.remove(_kStreaming);
    await _prefs.remove(_kCachedModels);
    await _prefs.remove(_kChatSessions);
    await _prefs.remove(_kActiveChatId);
  }
}
