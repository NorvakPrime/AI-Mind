import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:language_picker/languages.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/translations.dart';
import '../models/ai_model.dart';
import '../models/chat_chunk.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../pages/chat_history_page.dart';
import '../pages/settings_page.dart';
import '../services/open_router_service.dart';
import '../services/settings_service.dart';
import '../services/tool_service.dart';
import '../services/youtube_cookie_service.dart';
import '../theme/app_colors.dart';
import '../utils/animations.dart';
import '../widgets/chat_area.dart';
import '../widgets/settings_panel.dart';

const _kSfwPrompt = '''
---Mode: SFW (Safe For Work)---
Ты находишься в строгом безопасном режиме. Тебе категорически запрещено генерировать любой контент для взрослых (18+). Это включает: графические описания половых актов, гениталий, экстремальных фетишей, порнографических диалогов и сексуального взаимодействия с пользователем.
Однако тебе разрешено: обсуждать романтические чувства, флирт, поцелуи, объятия и ненавязчивые проявления нежности, если это не переходит в откровенную эротику. Также ты можешь затрагивать темы биологии и отношений в академическом или информативном ключе. Если пользователь пытается нарушить эти рамки, ты обязан тактично сменить тему или вежливо отказать, оставаясь в своем персонаже.
''';

const _kNsfwPrompt = '''
---Mode: NSFW (Not Safe For Work)---
Ты переходишь в режим полной свободы для взрослых. Теперь тебе разрешено описывать любые откровенные, эротические, табуированные и извращенные темы без цензуры. Ты можешь детально обыгрывать сцены сексуального характера, физическую близость и взаимодействие с пользователем, полностью следуя сюжету и инструкциям, которые он задал выше.
Твоя задача — максимально ярко и атмосферно развивать сценарий, углубляя эмоциональную или физическую связь между персонажами. Ты должен учитывать контекст ролевой игры, действовать согласно логике персонажа и обеспечивать реалистичную реакцию на действия пользователя (включая согласие и обоюдное участие в рамках вымышленной истории). Основной фокус — на погружении, динамике развития событий и детализации переживаний.
''';

String _getLanguagePrompt(String langName) {
  if (langName == 'Auto') {
    return '---Language: Auto---\nDetect the language used by the user and respond in the same language. Adapt to any language switches naturally.';
  }
  return '---Language: $langName---\nAlways respond strictly in $langName. Ensure high-quality, natural phrasing, regardless of the language the user speaks. If possible, use the native style and cultural nuances of $langName.';
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _openRouterService = OpenRouterService();
  final _toolService = ToolService();

  // Сессии чатов
  List<ChatSession> _sessions = [];
  String _activeSessionId = '';

  // Настройки
  late SettingsService _settings;
  String _modelId = '';
  String _apiToken = '';
  double _temperature = 0.7;
  double _topP = 0.9;
  double _maxTokens = 2048;
  bool _streaming = false;
  String? _reasoningEffort;
  String? _reasoningSummary;
  List<String> _enabledTools = [];
  String? _workingDirectory;
  bool _youtubeEnabled = false;
  late YouTubeCookieService _ytCookieService;
  bool _settingsReady = false;

  List<AiModel> _models = [];
  bool _settingsOpen = false;
  bool _isLoading = false;

  /// Progress tracking for tool calls: {callId: progress 0.0-1.0}
  Map<String, double> _toolCallProgress = {};

  bool get _isWide => MediaQuery.sizeOf(context).width >= 960;
  bool get _showSettings => _isWide && _settingsOpen;

  List<Map<String, dynamic>> get _availableTools =>
      buildAvailableTools(youtubeEnabled: _youtubeEnabled);

  /// Текущая сессия
  ChatSession? get _activeSession {
    for (final s in _sessions) {
      if (s.id == _activeSessionId) return s;
    }
    return null;
  }

  List<Message> get _messages => _activeSession?.messages ?? [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = SettingsService(prefs);
    _ytCookieService = YouTubeCookieService(prefs);

    final cached = _settings.cachedModels;
    final sessions = _settings.chatSessions;
    final activeId = _settings.activeChatId;

    // Если нет сессий — создаём временную (не сохраняем в настройки)
    if (sessions.isEmpty) {
      final session = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: Translations.of(context).newChat,
        createdAt: DateTime.now(),
        messages: [
          Message(
            Translations.of(context).get('first_msg_default'),
            fromUser: false,
          ),
        ],
      );
      sessions.add(session);
    }

    setState(() {
      _apiToken = _settings.apiToken;
      _modelId = _settings.modelId;
      _temperature = _settings.temperature;
      _topP = _settings.topP;
      _maxTokens = _settings.maxTokens;
      _streaming = _settings.streaming;
      _reasoningEffort = _settings.reasoningEffort;
      _reasoningSummary = _settings.reasoningSummary;
      _enabledTools = _settings.enabledTools;
      _workingDirectory = _settings.workingDirectory;
      _youtubeEnabled = _settings.youtubeEnabled;
      _models = cached.isNotEmpty ? cached : List.of(kDefaultModels);

      _toolService.configure(
        workingDirectory: _workingDirectory,
        youtubeEnabled: _youtubeEnabled,
        youtubeCookies: _ytCookieService.cookieHeader,
        youtubeUserAgent: _ytCookieService.userAgent,
      );
      _sessions = sessions;

      // Выбираем активную сессию: либо сохраненную, либо первую доступную
      if (activeId.isNotEmpty && sessions.any((s) => s.id == activeId)) {
        _activeSessionId = activeId;
      } else {
        _activeSessionId = sessions.isNotEmpty ? sessions.first.id : '';
      }
      _settingsReady = true;
    });
  }

  AiModel? _findModel(String id) {
    for (final m in _models) {
      if (m.id == id) return m;
    }
    return null;
  }

  String get _modelName {
    final m = _findModel(_modelId);
    return m?.name ?? _modelId;
  }

  /// Сохранить текущие сессии (только те, где есть сообщения от пользователя)
  Future<void> _saveSessions() async {
    final toSave = _sessions
        .where((s) => s.messages.any((m) => m.fromUser))
        .toList();
    await _settings.setChatSessions(toSave);
    await _settings.setActiveChatId(_activeSessionId);
  }

  /// Начать новый чат
  void _newChat() {
    _showNewChatDialog();
  }

  void _createSession({
    String? systemPrompt,
    String? firstMessage,
    bool isNsfw = false,
    String language = 'Auto',
  }) {
    final l10n = Translations.of(context);
    String finalSystem = systemPrompt ?? '';
    finalSystem += isNsfw ? '\n\n$_kNsfwPrompt' : '\n\n$_kSfwPrompt';

    finalSystem += '\n\n${_getLanguagePrompt(language)}';

    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: l10n.newChat,
      createdAt: DateTime.now(),
      systemPrompt: finalSystem.trim().isEmpty ? null : finalSystem,
      messages: [
        Message(
          (firstMessage == null || firstMessage.trim().isEmpty)
              ? l10n.get('first_msg_default')
              : firstMessage,
          fromUser: false,
        ),
      ],
    );
    setState(() {
      _sessions.insert(0, session);
      _activeSessionId = session.id;
    });
  }

  void _showNewChatDialog() {
    final l10n = Translations.of(context);
    final systemCtrl = TextEditingController();
    final firstCtrl = TextEditingController();
    bool isNsfw = _settings.nsfwDefault;
    String selectedLang = _settings.languageDefault;

    showAnimatedDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                l10n.newChat,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Язык ──
                Text(
                  l10n.languagePriority,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surfaceBorder,
                      width: 0.5,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLang,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceLight,
                      icon: const Icon(
                        Icons.language_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      items:
                          [
                                'Auto',
                                ...Languages.defaultLanguages
                                    .map((l) => l.name)
                                    .toList()
                                  ..sort(),
                              ]
                              .map<DropdownMenuItem<String>>(
                                (lang) => DropdownMenuItem<String>(
                                  value: lang,
                                  child: Text(
                                    lang == 'Auto' ? l10n.auto : lang,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedLang = v);
                          _settings.setLanguageDefault(v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  l10n.systemPrompt,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: systemCtrl,
                  maxLines: 3,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.get('system_prompt_hint'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.firstMessage,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: firstCtrl,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.get('first_msg_hint'),
                  ),
                ),
                const SizedBox(height: 20),
                // NSFW Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surfaceBorder,
                      width: 0.5,
                    ),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      l10n.nsfwMode,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      isNsfw ? l10n.get('nsfw_on') : l10n.get('safe_mode'),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    value: isNsfw,
                    activeThumbColor: AppColors.accent,
                    onChanged: (v) {
                      setDialogState(() => isNsfw = v);
                      _settings.setNsfwDefault(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createSession(
                  systemPrompt: systemCtrl.text,
                  firstMessage: firstCtrl.text,
                  isNsfw: isNsfw,
                  language: selectedLang,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  /// Переключиться на сессию
  void _switchSession(String id) {
    setState(() => _activeSessionId = id);
    _saveSessions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  /// Удалить сессию
  void _deleteSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
      if (_activeSessionId == id) {
        if (_sessions.isNotEmpty) {
          _activeSessionId = _sessions.first.id;
        } else {
          _newChat();
        }
      }
    });
    _saveSessions();
  }

  Map<String, dynamic>? get _reasoningConfig {
    if (_reasoningEffort == null && _reasoningSummary == null) return null;
    return {
      if (_reasoningEffort != null) 'effort': _reasoningEffort,
      if (_reasoningSummary != null) 'summary': _reasoningSummary,
    };
  }

  bool get _shouldIncludeReasoning {
    final model = _findModel(_modelId);
    return model?.supportedParameters.contains('include_reasoning') ?? false;
  }

  /// Парсит ответ модели, разделяя мысли и основной контент
  Message _parseReply(String reply) {
    final thinkRegex = RegExp(r'<think>(.*?)(?:</think>|$)', dotAll: true);
    final match = thinkRegex.firstMatch(reply);
    if (match != null) {
      final thought = match.group(1)?.trim();
      final content = reply.replaceFirst(thinkRegex, '').trim();
      return Message(
        content,
        fromUser: false,
        timestamp: DateTime.now(),
        thought: thought,
      );
    }
    return Message(reply, fromUser: false, timestamp: DateTime.now());
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || _activeSession == null) return;

    setState(() {
      _activeSession!.messages.add(
        Message(text, fromUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Обновить заголовок сессии по первому сообщению
    if (_activeSession!.messages.where((m) => m.fromUser).length == 1) {
      _activeSession!.title = text.length > 40
          ? '${text.substring(0, 40)}…'
          : text;
    }
    _saveSessions();

    if (_apiToken.trim().isEmpty) {
      _showSnack(Translations.of(context).get('api_token_error') == 'api_token_error' ? 'Добавьте API-токен в настройках' : Translations.of(context).get('api_token_error'));
      return;
    }

    try {
      if (_streaming) {
        await _sendStreaming();
      } else {
        final message = await _openRouterService.sendMessage(
          apiKey: _apiToken.trim(),
          modelId: _modelId,
          history: _activeSession!.messages,
          systemPrompt: _activeSession!.systemPrompt,
          reasoning: _reasoningConfig,
          includeReasoning: _shouldIncludeReasoning,
          tools: _availableTools.isNotEmpty ? _availableTools : null,
        );
        if (!mounted) return;
        setState(() {
          _activeSession!.messages.add(message);
          _isLoading = false;
        });

        if (message.toolCalls != null) {
          await _handleToolCalls(message.toolCalls!);
        }

        _scrollToBottom();
        _saveSessions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Ошибка: $e');
    }
  }

  /// Max concurrent downloads
  Future<void> _handleToolCalls(List<dynamic> toolCalls) async {
    // Execute tool calls in parallel and show UI immediately
    final futures = <Future<void>>[];
    for (final call in toolCalls) {
      futures.add(_executeToolCall(call));
    }

    await Future.wait(futures);

    // After all tools are finished - send results back to model
    if (mounted) {
      await _sendManualAfterTool();
    }
  }

  Future<void> _executeToolCall(dynamic call) async {
    final name = call['function']['name'] as String? ?? 'unknown';
    final argsJson = call['function']['arguments'] as String? ?? '{}';
    final callId = call['id'] as String? ?? '';

    Map<String, dynamic> args;
    try {
      args = jsonDecode(argsJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to parse tool call arguments: $argsJson  error: $e');
      setState(() {
        _activeSession!.messages.add(Message(
          '',
          fromUser: false,
          toolCallId: callId,
          toolResult: jsonEncode({'error': 'Invalid tool call arguments received from AI.'}),
          toolCallName: name,
        ));
      });
      return;
    }

    // CREATE and ADD message immediately to show "Pending" state in UI
    final initialMessage = Message(
      '',
      fromUser: false,
      toolCallId: callId,
      toolCallName: name,
      toolCallArgs: argsJson,
      toolCallStartTime: DateTime.now(),
    );

    setState(() {
      _activeSession!.messages.add(initialMessage);
      _toolCallProgress[callId] = 0.0;
    });
    _scrollToBottom();

    // Now execute the actual logic
    final result = await _toolService.execute(
      name,
      args,
      callId: callId,
      onProgress: (p, speed, eta) {
        if (mounted) {
          setState(() {
            _toolCallProgress[callId] = p;
          });
        }
      },
    );

    if (mounted) {
      // Find the initial message and update it with the result
      final index = _activeSession!.messages.indexOf(initialMessage);
      if (index != -1) {
        setState(() {
          _toolCallProgress[callId] = 1.0;
          
          // Check for media display action
          String? mediaPath;
          String? mediaType;
          if (result['action'] == 'display_media') {
            mediaPath = result['media_path'];
            mediaType = result['media_type'];
          }

          _activeSession!.messages[index] = initialMessage.copyWith(
            toolResult: jsonEncode(result),
            toolCallProgress: Map<String, double>.from(_toolCallProgress),
            mediaPath: mediaPath,
            mediaType: mediaType,
          );
        });
      }
    }
  }

  /// Повторная отправка после выполнения тулзов (не меняет текст пользователя)
  Future<void> _sendManualAfterTool() async {
    if (_activeSession == null) return;
    setState(() => _isLoading = true);

    try {
      if (_streaming) {
        await _sendStreaming();
      } else {
        final message = await _openRouterService.sendMessage(
          apiKey: _apiToken.trim(),
          modelId: _modelId,
          history: _activeSession!.messages,
          systemPrompt: _activeSession!.systemPrompt,
          reasoning: _reasoningConfig,
          includeReasoning: _shouldIncludeReasoning,
          tools: _availableTools.isNotEmpty ? _availableTools : null,
        );
        if (!mounted) return;
        setState(() {
          _activeSession!.messages.add(message);
          _isLoading = false;
        });
        if (message.toolCalls != null) {
          await _handleToolCalls(message.toolCalls!);
        }
        _scrollToBottom();
        _saveSessions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Ошибка после Tools: $e');
    }
  }

  /// Ручная отправка текста (для перегенерации)
  Future<void> _sendManual(String text) async {
    if (_isLoading || _activeSession == null) return;

    setState(() => _isLoading = true);
    _scrollToBottom();

    if (_apiToken.trim().isEmpty) {
      _showSnack(Translations.of(context).get('api_token_error') == 'api_token_error' ? 'Добавьте API-токен в настройках' : Translations.of(context).get('api_token_error'));
      return;
    }

    try {
      if (_streaming) {
        await _sendStreaming();
      } else {
        final message = await _openRouterService.sendMessage(
          apiKey: _apiToken.trim(),
          modelId: _modelId,
          history: _activeSession!.messages,
          systemPrompt: _activeSession!.systemPrompt,
          reasoning: _reasoningConfig,
          includeReasoning: _shouldIncludeReasoning,
          tools: _availableTools.isNotEmpty ? _availableTools : null,
        );
        if (!mounted) return;
        setState(() {
          _activeSession!.messages.add(message);
          _isLoading = false;
        });

        if (message.toolCalls != null) {
          await _handleToolCalls(message.toolCalls!);
        }

        _scrollToBottom();
        _saveSessions();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Ошибка: $e');
    }
  }

  StreamSubscription<ChatChunk>? _streamSubscription;

  Future<void> _sendStreaming() async {
    _activeSession!.messages.add(
      Message('', fromUser: false, timestamp: DateTime.now()),
    );
    setState(() {});
    _scrollToBottom();

    String fullReply = '';
    String fullReasoning = '';
    List<dynamic> collectedToolCalls = [];

    final completer = Completer<void>();
    final session = _activeSession!;

    _streamSubscription = _openRouterService
        .sendMessageStream(
          apiKey: _apiToken.trim(),
          modelId: _modelId,
          history: session.messages,
          systemPrompt: session.systemPrompt,
          reasoning: _reasoningConfig,
          includeReasoning: _shouldIncludeReasoning,
          tools: _availableTools.isNotEmpty ? _availableTools : null,
        )
        .listen(
          (chunk) {
            if (chunk.content != null) fullReply += chunk.content!;
            if (chunk.reasoning != null) fullReasoning += chunk.reasoning!;
            if (chunk.toolCalls != null) {
              // OpenRouter streams tool calls incrementally:
              // each chunk has {index, id, function: {name, arguments_partial}}.
              // We must merge by index, concatenating arguments strings.
              for (final tc in chunk.toolCalls!) {
                final idx = tc['index'] as int?;
                if (idx == null) continue;

                // Ensure we have a slot for this index
                while (collectedToolCalls.length <= idx) {
                  collectedToolCalls.add(<String, dynamic>{});
                }

                final existing = collectedToolCalls[idx] as Map<String, dynamic>;
                // Merge id
                if (tc['id'] != null) existing['id'] = tc['id'];
                // Merge function name
                if (tc['function'] != null) {
                  final fn = tc['function'] as Map<String, dynamic>;
                  existing.putIfAbsent('function', () => <String, dynamic>{});
                  final existingFn = existing['function'] as Map<String, dynamic>;
                  if (fn['name'] != null) existingFn['name'] = fn['name'];
                  // Concatenate arguments (they arrive in chunks)
                  final argsChunk = fn['arguments'] as String? ?? '';
                  existingFn['arguments'] =
                      (existingFn['arguments'] as String? ?? '') + argsChunk;
                }
                collectedToolCalls[idx] = existing;
              }
            }

            if (!mounted) return;
            setState(() {
              session.messages[session.messages.length - 1] = Message(
                fullReply,
                fromUser: false,
                timestamp: DateTime.now(),
                thought: fullReasoning.isNotEmpty ? fullReasoning : null,
                toolCalls: collectedToolCalls.isNotEmpty ? collectedToolCalls : null,
              );
            });
            _scrollToBottom();
          },
          onError: (Object e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _showSnack('Ошибка: $e');
            _saveSessions();
            if (!completer.isCompleted) completer.complete();
          },
          onDone: () async {
            if (!mounted) return;

            final lastMsg = session.messages.last;
            if (lastMsg.toolCalls != null) {
              await _handleToolCalls(lastMsg.toolCalls!);
              if (!completer.isCompleted) completer.complete();
              return;
            }

            setState(() {
              final lastIdx = session.messages.length - 1;
              session.messages[lastIdx] = _parseReply(fullReply);
              _isLoading = false;
            });
            _saveSessions();
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );

    return completer.future;
  }

  void _showSnack(String message) {
    setState(() => _isLoading = false);

    // Если это ошибка 429 (Too Many Requests)
    if (message.contains('429')) {
      final model = _findModel(_modelId);
      final isFree = model != null &&
          (model.promptPrice ?? 0) == 0 &&
          (model.completionPrice ?? 0) == 0;

      if (isFree) {
        _show429Dialog();
        return;
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _show429Dialog() {
    final l10n = Translations.of(context);
    showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Row(
          children: [
            const Icon(Icons.speed_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.get('error_429_title'))),
          ],
        ),
        content: Text(
          l10n.get('error_429_desc'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.get('got_it'),
              style: const TextStyle(color: AppColors.accentLight),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openSettings() {
    if (_isWide) {
      setState(() => _settingsOpen = !_settingsOpen);
    } else {
      Navigator.push(
        context,
        SmoothPageRoute(
          child: SettingsPage(
            settings: _settings,
            modelId: _modelId,
            models: _models,
            apiToken: _apiToken,
            temperature: _temperature,
            topP: _topP,
            maxTokens: _maxTokens,
            streaming: _streaming,
            reasoningEffort: _reasoningEffort,
            reasoningSummary: _reasoningSummary,
            enabledTools: _enabledTools,
            workingDirectory: _workingDirectory,
            youtubeEnabled: _youtubeEnabled,
            youtubeCookieService: _ytCookieService,
            onModelChanged: (v) => setState(() => _modelId = v),
            onModelsUpdated: (list) => setState(() => _models = list),
            onSettingsChanged: _reloadFromSettings,
          ),
        ),
      );
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      SmoothPageRoute(
        child: ChatHistoryPage(
          sessions: _sessions,
          activeSessionId: _activeSessionId,
          onSelect: (id) {
            _switchSession(id);
            Navigator.pop(context);
          },
          onNewChat: () {
            _newChat();
            Navigator.pop(context);
          },
          onDelete: _deleteSession,
        ),
      ),
    );
  }

  void _reloadFromSettings() {
    setState(() {
      _apiToken = _settings.apiToken;
      _modelId = _settings.modelId;
      _temperature = _settings.temperature;
      _topP = _settings.topP;
      _maxTokens = _settings.maxTokens;
      _streaming = _settings.streaming;
      _reasoningEffort = _settings.reasoningEffort;
      _reasoningSummary = _settings.reasoningSummary;
      _enabledTools = _settings.enabledTools;
      _workingDirectory = _settings.workingDirectory;
      _youtubeEnabled = _settings.youtubeEnabled;
      final cached = _settings.cachedModels;
      if (cached.isNotEmpty) _models = cached;

      _toolService.configure(
        workingDirectory: _workingDirectory,
        youtubeEnabled: _youtubeEnabled,
        youtubeCookies: _ytCookieService.cookieHeader,
        youtubeUserAgent: _ytCookieService.userAgent,
      );
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _toolService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Translations.of(context);
    if (!_settingsReady) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final chat = ChatArea(
      messages: _messages,
      controller: _messageController,
      scrollController: _scrollController,
      focusNode: _focusNode,
      isLoading: _isLoading,
      onSend: _send,
      onEditMessage: (index, newText) {
        setState(() {
          _activeSession!.messages[index] = _parseReply(newText);
        });
        _saveSessions();
      },
      onRegenerate: () {
        if (_activeSession == null || _messages.isEmpty) return;
        // Находим последнее сообщение пользователя
        int lastUserIdx = -1;
        for (int i = _messages.length - 1; i >= 0; i--) {
          if (_messages[i].fromUser) {
            lastUserIdx = i;
            break;
          }
        }
        if (lastUserIdx != -1) {
          final text = _messages[lastUserIdx].text;
          // Удаляем всё после последнего сообщения пользователя (включая старый ответ бота)
          setState(() {
            _activeSession!.messages.removeRange(
              lastUserIdx + 1,
              _activeSession!.messages.length,
            );
          });
          // Отправляем заново
          _sendManual(text);
        }
      },
      onDeleteMessage: (index) {
        setState(() {
          // Если удаляем ответ бота, и перед ним было сообщение пользователя
          if (!_messages[index].fromUser &&
              index > 0 &&
              _messages[index - 1].fromUser) {
            final userMsg = _messages[index - 1].text;
            _messageController.text = userMsg;
            // Удаляем и ответ бота, и сообщение пользователя
            _activeSession!.messages.removeRange(index - 1, index + 1);
          } else {
            _activeSession!.messages.removeAt(index);
          }
        });
        _saveSessions();
      },
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isWide
            ? Row(
                children: [
                  Expanded(child: chat),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: _showSettings
                        ? Row(
                            children: [
                              Container(
                                width: 1,
                                color: AppColors.surfaceBorder,
                              ),
                              SizedBox(
                                width: 360,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _showSettings ? 1.0 : 0.0,
                                  child: _buildSidePanel(),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              )
            : chat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = Translations.of(context);
    return AppBar(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Mind',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                _modelName,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Новый чат
        IconButton(
          onPressed: _newChat,
          icon: const Icon(
            Icons.edit_square,
            size: 20,
            color: AppColors.textSecondary,
          ),
          tooltip: l10n.newChat,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        // История чатов
        IconButton(
          onPressed: _openHistory,
          icon: const Icon(
            Icons.history_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          tooltip: l10n.history,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        // Настройки
        IconButton(
          onPressed: _openSettings,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: child.key == const ValueKey('close')
                  ? anim
                  : Tween<double>(begin: 1, end: 0).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              _showSettings ? Icons.close_rounded : Icons.tune_rounded,
              key: ValueKey(_showSettings ? 'close' : 'settings'),
              size: 21,
              color: AppColors.textSecondary,
            ),
          ),
          style: IconButton.styleFrom(
            backgroundColor: _showSettings
                ? AppColors.surfaceLight
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSidePanel() {
    return Material(
      color: AppColors.surface,
      child: SettingsPanel(
        showSideBorder: false,
        settings: _settings,
        modelId: _modelId,
        models: _models,
        apiToken: _apiToken,
        temperature: _temperature,
        topP: _topP,
        maxTokens: _maxTokens,
        streaming: _streaming,
        enabledTools: _enabledTools,
        workingDirectory: _workingDirectory,
        youtubeEnabled: _youtubeEnabled,
        youtubeCookieService: _ytCookieService,
        reasoningEffort: _reasoningEffort,
        reasoningSummary: _reasoningSummary,
        onModelChanged: (v) => setState(() => _modelId = v),
        onModelsUpdated: (list) => setState(() => _models = list),
        onSettingsChanged: _reloadFromSettings,
      ),
    );
  }
}
