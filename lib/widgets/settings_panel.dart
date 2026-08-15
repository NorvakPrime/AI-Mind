import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../models/ai_model.dart';
import '../pages/youtube_login_page.dart';
import '../services/locale_service.dart';
import '../services/open_router_service.dart';
import '../services/settings_service.dart';
import '../services/youtube_cookie_service.dart';
import '../services/youtube_login_helper.dart';
import '../services/yt_dlp_service.dart';
import '../theme/app_colors.dart';
import 'section_header.dart';
import 'slider_param.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    this.showSideBorder = false,
    required this.settings,
    required this.modelId,
    required this.models,
    required this.apiToken,
    required this.temperature,
    required this.topP,
    required this.maxTokens,
    required this.streaming,
    this.reasoningEffort,
    this.reasoningSummary,
    required this.enabledTools,
    this.workingDirectory,
    required this.youtubeEnabled,
    this.youtubeCookieService,
    required this.onModelChanged,
    required this.onModelsUpdated,
    required this.onSettingsChanged,
  });

  final bool showSideBorder;
  final SettingsService settings;
  final String modelId;
  final List<AiModel> models;
  final String apiToken;
  final double temperature;
  final double topP;
  final double maxTokens;
  final bool streaming;
  final String? reasoningEffort;
  final String? reasoningSummary;
  final List<String> enabledTools;
  final String? workingDirectory;
  final bool youtubeEnabled;
  final YouTubeCookieService? youtubeCookieService;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<List<AiModel>> onModelsUpdated;
  final VoidCallback onSettingsChanged;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final _apiTokenCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _service = OpenRouterService();
  bool _hideToken = true;

  // Локальные копии параметров (для немедленного UI)
  late double _temperature;
  late double _topP;
  late double _maxTokens;
  late bool _streaming;
  late List<AiModel> _models;
  late String _modelId;
  String? _reasoningEffort;
  String? _reasoningSummary;
  late List<String> _enabledTools;
  String? _workingDirectory;
  late bool _youtubeEnabled;
  late bool _ytHasCookies;
  bool _ytDlpInstalled = false;
  bool _ytDlpDownloading = false;
  double _ytDlpProgress = 0.0;
  final _ytDlpService = YtDlpService();
  String _filterType = 'all'; // all, free, paid, reasoning, no_reasoning

  // Загрузка моделей
  bool _modelsLoading = false;
  String? _modelsError;

  // Баланс
  double? _balance;
  bool _balanceLoading = false;
  String? _balanceError;

  @override
  void initState() {
    super.initState();
    _apiTokenCtrl.text = widget.apiToken;
    _temperature = widget.temperature;
    _topP = widget.topP;
    _maxTokens = widget.maxTokens;
    _streaming = widget.streaming;
    _models = List.from(widget.models);
    _modelId = widget.modelId;
    _reasoningEffort = widget.reasoningEffort;
    _reasoningSummary = widget.reasoningSummary;
    _enabledTools = List.from(widget.enabledTools);
    _workingDirectory = widget.workingDirectory;
    _youtubeEnabled = widget.youtubeEnabled;
    _ytHasCookies = widget.youtubeCookieService?.hasCookies ?? false;
    _checkYtDlp();

    // Авто-загрузка баланса и моделей при старте, если токен уже есть
    final token = widget.apiToken.trim();
    if (token.length > 20 && token.startsWith('sk-')) {
      _fetchAll(token);
    }
  }

  void _checkYtDlp() async {
    if (Platform.isAndroid || Platform.isIOS) return;
    final installed = await _ytDlpService.isInstalled();
    if (mounted) setState(() => _ytDlpInstalled = installed);
  }

  Future<void> _downloadYtDlp() async {
    if (_ytDlpDownloading) return;
    setState(() {
      _ytDlpDownloading = true;
      _ytDlpProgress = 0.0;
    });

    try {
      await _ytDlpService.downloadExecutable(onProgress: (p) {
        if (mounted) setState(() => _ytDlpProgress = p);
      });
      if (mounted) {
        setState(() {
          _ytDlpInstalled = true;
          _ytDlpDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ytDlpDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download yt-dlp: $e')),
        );
      }
    }
  }

  @override
  void didUpdateWidget(SettingsPanel old) {
    super.didUpdateWidget(old);
    if (old.apiToken != widget.apiToken &&
        _apiTokenCtrl.text != widget.apiToken) {
      _apiTokenCtrl.text = widget.apiToken;
    }
    if (old.temperature != widget.temperature) {
      _temperature = widget.temperature;
    }
    if (old.topP != widget.topP) {
      _topP = widget.topP;
    }
    if (old.maxTokens != widget.maxTokens) {
      _maxTokens = widget.maxTokens;
    }
    if (old.streaming != widget.streaming) {
      _streaming = widget.streaming;
    }
    if (old.models != widget.models) {
      _models = List.from(widget.models);
    }
    if (old.modelId != widget.modelId) {
      _modelId = widget.modelId;
    }
    if (old.reasoningEffort != widget.reasoningEffort) {
      _reasoningEffort = widget.reasoningEffort;
    }
    if (old.reasoningSummary != widget.reasoningSummary) {
      _reasoningSummary = widget.reasoningSummary;
    }
    if (old.enabledTools != widget.enabledTools) {
      _enabledTools = List.from(widget.enabledTools);
    }
    if (old.workingDirectory != widget.workingDirectory) {
      _workingDirectory = widget.workingDirectory;
    }
    if (old.youtubeEnabled != widget.youtubeEnabled) {
      _youtubeEnabled = widget.youtubeEnabled;
    }
    if (old.youtubeCookieService != widget.youtubeCookieService) {
      _ytHasCookies = widget.youtubeCookieService?.hasCookies ?? false;
    }
  }

  // ── Сохранение токена ──
  Future<void> _saveToken() async {
    final token = _apiTokenCtrl.text.trim();
    await widget.settings.setApiToken(token);
    widget.onSettingsChanged();
  }

  // ── Авто-загрузка при вставке токена ──
  void _onTokenChanged(String value) {
    _saveToken();
    final token = value.trim();
    if (token.length > 20 && token.startsWith('sk-')) {
      _fetchAll(token);
    }
  }

  Future<void> _fetchAll(String token) async {
    await Future.wait([_fetchModels(token), _fetchBalance(token)]);
  }

  Future<void> _fetchModels(String token) async {
    setState(() {
      _modelsLoading = true;
      _modelsError = null;
    });
    try {
      final list = await _service.fetchModels(token);
      if (!mounted) return;

      // Сохраняем в кэш
      await widget.settings.setCachedModels(list);

      setState(() {
        _modelsLoading = false;
        _models = list; // Обновляем локальный список
        widget.onModelsUpdated(list);

        // Если текущая модель не в списке — выбрать первую
        if (list.isNotEmpty && !list.any((m) => m.id == _modelId)) {
          final newId = list.first.id;
          _modelId = newId;
          widget.onModelChanged(newId);
          widget.settings.setModelId(newId);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modelsLoading = false;
        _modelsError = 'Не удалось загрузить модели';
      });
    }
  }

  Future<void> _fetchBalance(String token) async {
    setState(() {
      _balanceLoading = true;
      _balanceError = null;
    });
    try {
      final bal = await _service.fetchBalance(token);
      if (!mounted) return;
      setState(() {
        _balance = bal;
        _balanceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceLoading = false;
        _balanceError = '—';
      });
    }
  }

  Future<void> _reset() async {
    await widget.settings.clear();
    setState(() {
      _apiTokenCtrl.clear();
      _hideToken = true;
      _streaming = false;
      _temperature = 0.7;
      _topP = 0.9;
      _maxTokens = 2048;
      _reasoningEffort = null;
      _reasoningSummary = null;
      _modelsLoading = false;
      _modelsError = null;
      _balance = null;
      _balanceLoading = false;
      _balanceError = null;
      _models = List.from(kDefaultModels);
      _modelId = kDefaultModels.first.id;
      _enabledTools = [];
      _workingDirectory = null;
      _youtubeEnabled = false;
      _ytHasCookies = false;
    });
    widget.onModelChanged(kDefaultModels.first.id);
    widget.onModelsUpdated(List.of(kDefaultModels));
    widget.onSettingsChanged();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сброшено')));
    }
  }

  @override
  void dispose() {
    _apiTokenCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, String type, Translations l10n) {
    final isSelected = _filterType == type;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (val) {
        setState(() => _filterType = type);
      },
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      checkmarkColor: AppColors.accentLight,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.accent : AppColors.surfaceBorder,
        width: 0.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildReasoningDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: (v) {
                if (v != null || items.any((i) => i.value == null)) {
                  onChanged(v as T);
                }
              },
              dropdownColor: AppColors.surfaceLight,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Translations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    return Container(
      decoration: BoxDecoration(
        border: widget.showSideBorder
            ? const Border(left: BorderSide(color: AppColors.surfaceBorder))
            : null,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          // Заголовок (только в боковой панели)
          if (widget.showSideBorder) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.settings,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: AppColors.textMuted,
                  tooltip: l10n.get('reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // --- Язык приложения ---
          SectionHeader(
              title: l10n.get('app_language'), icon: Icons.language_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: localeProvider.locale.languageCode,
                dropdownColor: AppColors.surfaceLight,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted),
                items: const [
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      children: [
                        Text('🇺🇸', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 12),
                        Text('English',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ru',
                    child: Row(
                      children: [
                        Text('🇷🇺', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 12),
                        Text('Русский',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) localeProvider.setLocale(Locale(v));
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── API Токен (первым для удобства) ──
          SectionHeader(title: l10n.apiToken, icon: Icons.vpn_key_rounded),
          const SizedBox(height: 8),
          TextField(
            controller: _apiTokenCtrl,
            obscureText: _hideToken,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            onChanged: _onTokenChanged,
            decoration: InputDecoration(
              hintText: 'sk-or-v1-…',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hideToken = !_hideToken),
                icon: Icon(
                  _hideToken
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Баланс
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: AppColors.accentLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.balance,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_balanceLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                else
                  Text(
                    _balance != null
                        ? '\$${_balance!.toStringAsFixed(2)}'
                        : (_balanceError ?? '\$0.00'),
                    style: TextStyle(
                      color: _balanceError != null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Модель ──
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: l10n.model,
                  icon: Icons.memory_rounded,
                ),
              ),
              SizedBox(
                height: 28,
                child: TextButton.icon(
                  onPressed: _modelsLoading
                      ? null
                      : () {
                          final token = _apiTokenCtrl.text.trim();
                          if (token.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    l10n.get('api_token_error') ==
                                            'api_token_error'
                                        ? 'Сначала введите API токен'
                                        : l10n.get('api_token_error')),
                              ),
                            );
                            return;
                          }
                          _fetchModels(token);
                        },
                  icon: _modelsLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(
                    _modelsLoading ? l10n.get('loading') : l10n.get('update'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Поле поиска моделей
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.get('search_model'),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 10),

          // Фильтры моделей
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFilterChip(l10n.get('all_models'), 'all', l10n),
              _buildFilterChip(l10n.get('free_models'), 'free', l10n),
              _buildFilterChip(l10n.get('paid_models'), 'paid', l10n),
              _buildFilterChip(l10n.get('reasoning_models'), 'reasoning', l10n),
              _buildFilterChip(
                  l10n.get('no_reasoning_models'), 'no_reasoning', l10n),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _models.any((m) => m.id == _modelId) ? _modelId : null,
              dropdownColor: AppColors.surfaceLight,
              isExpanded: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                hintText: l10n.get('select_model'),
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              items: _models.where((m) {
                // Текущая выбранная модель ВСЕГДА должна быть в списке
                if (m.id == _modelId) return true;

                // 1. Поиск по тексту
                final searchText = _searchCtrl.text.toLowerCase();
                final matchesSearch = searchText.isEmpty ||
                    m.name.toLowerCase().contains(searchText) ||
                    m.id.toLowerCase().contains(searchText);

                if (!matchesSearch) return false;

                // 2. Фильтрация по типу
                switch (_filterType) {
                  case 'free':
                    return (m.promptPrice ?? 0) == 0 &&
                        (m.completionPrice ?? 0) == 0;
                  case 'paid':
                    return (m.promptPrice ?? 0) > 0 ||
                        (m.completionPrice ?? 0) > 0;
                  case 'reasoning':
                    return m.reasoning != null ||
                        m.supportedParameters.contains('include_reasoning');
                  case 'no_reasoning':
                    return m.reasoning == null &&
                        !m.supportedParameters.contains('include_reasoning');
                  default:
                    return true;
                }
              }).fold<Map<String, AiModel>>({}, (map, m) {
                // Дедупликация по ID: если ID уже есть, не добавляем
                if (!map.containsKey(m.id)) map[m.id] = m;
                return map;
              }).values.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _modelId = v;
                    final model = _models.firstWhere((m) => m.id == v);
                    // Если модель сменилась и у нее есть свои дефолты для размышлений
                    if (model.reasoning != null) {
                      if (model.reasoning!.defaultEffort != null) {
                        _reasoningEffort = model.reasoning!.defaultEffort;
                        widget.settings.setReasoningEffort(_reasoningEffort);
                      }
                    }
                  });
                  widget.onModelChanged(v);
                  widget.settings.setModelId(v);
                  widget.onSettingsChanged();
                }
              },
            ),
          ),
          // Показать цену выбранной модели
          Builder(
            builder: (ctx) {
              final selected = _models.where((m) => m.id == _modelId).toList();
              if (selected.isEmpty) return const SizedBox.shrink();
              final model = selected.first;
              if (model.priceLabel == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 15,
                        color: AppColors.accentLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          model.priceLabel!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_modelsError != null) ...[
            const SizedBox(height: 6),
            Text(
              _modelsError!,
              style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
            ),
          ],
          const SizedBox(height: 28),

          // ── Параметры ──
          SectionHeader(title: l10n.parameters, icon: Icons.tune_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
            ),
            child: Column(
              children: [
                SliderParam(
                  label: l10n.temperature,
                  value: _temperature,
                  max: 2,
                  onChanged: (v) {
                    setState(() => _temperature = v);
                    widget.settings.setTemperature(v);
                  },
                ),
                const Divider(color: AppColors.surfaceBorder, height: 20),
                SliderParam(
                  label: l10n.topP,
                  value: _topP,
                  max: 1,
                  onChanged: (v) {
                    setState(() => _topP = v);
                    widget.settings.setTopP(v);
                  },
                ),
                const Divider(color: AppColors.surfaceBorder, height: 20),
                SliderParam(
                  label: l10n.maxTokens,
                  value: _maxTokens,
                  min: 256,
                  max: 8192,
                  divisions: 31,
                  decimal: false,
                  onChanged: (v) {
                    setState(() => _maxTokens = v);
                    widget.settings.setMaxTokens(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Streaming toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  l10n.streaming,
                  style:
                      const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                subtitle: Text(
                  l10n.streamingDesc,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                activeThumbColor: AppColors.accent,
                value: _streaming,
                onChanged: (v) async {
                  setState(() => _streaming = v);
                  await widget.settings.setStreaming(v);
                  widget.onSettingsChanged();
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Размышления (Reasoning) ──
          Builder(
            builder: (context) {
              final model = _models.cast<AiModel?>().firstWhere(
                    (m) => m?.id == _modelId,
                    orElse: () => null,
                  );
              final hasReasoning = model?.reasoning != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                      title: l10n.reasoning, icon: Icons.psychology_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.surfaceBorder, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasReasoning) ...[
                          if (model!.reasoning!.supportedEfforts.isNotEmpty)
                            _buildReasoningDropdown<String?>(
                              label: l10n.reasoningEffort,
                              value: model.reasoning!.supportedEfforts
                                      .contains(_reasoningEffort)
                                  ? _reasoningEffort
                                  : (model.reasoning!.supportedEfforts.contains(
                                          model.reasoning!.defaultEffort)
                                      ? model.reasoning!.defaultEffort
                                      : null),
                              items: [
                                DropdownMenuItem(
                                    value: null, child: Text(l10n.get('auto'))),
                                ...model.reasoning!.supportedEfforts.map(
                                  (e) => DropdownMenuItem(
                                      value: e, child: Text(l10n.get(e))),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() => _reasoningEffort = v);
                                widget.settings.setReasoningEffort(v);
                                widget.onSettingsChanged();
                              },
                            ),
                          if (model.reasoning!.supportedEfforts.isNotEmpty)
                            const SizedBox(height: 16),
                          _buildReasoningDropdown<String?>(
                            label: l10n.reasoningSummary,
                            value: _reasoningSummary,
                            items: [
                              DropdownMenuItem(
                                  value: null, child: Text(l10n.get('none'))),
                              DropdownMenuItem(
                                  value: 'auto', child: Text(l10n.get('auto'))),
                              DropdownMenuItem(
                                  value: 'concise',
                                  child: Text(l10n.get('concise'))),
                              DropdownMenuItem(
                                  value: 'detailed',
                                  child: Text(l10n.get('detailed'))),
                            ],
                            onChanged: (v) {
                              setState(() => _reasoningSummary = v);
                              widget.settings.setReasoningSummary(v);
                              widget.onSettingsChanged();
                            },
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.reasoningWarning,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Инструменты (Tools) ──
          SectionHeader(title: l10n.get('tools'), icon: Icons.handyman_rounded),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get('tools_desc'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),

                // YouTube toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Row(
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            l10n.get('youtube_enabled'),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        l10n.get('youtube_desc'),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      activeThumbColor: AppColors.accent,
                      value: _youtubeEnabled,
                      onChanged: (v) async {
                        setState(() => _youtubeEnabled = v);
                        await widget.settings.setYoutubeEnabled(v);
                        widget.onSettingsChanged();
                      },
                    ),
                  ),
                ),
                // YouTube login button (only on supported platforms)
                if (_youtubeEnabled && isYouTubeLoginSupported) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              _ytHasCookies ? Icons.verified_user_outlined : Icons.login_rounded,
                              size: 18,
                              color: _ytHasCookies ? Colors.green : AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ytHasCookies ? l10n.get('yt_logged_in') : l10n.get('yt_login'),
                                    style: TextStyle(
                                      color: _ytHasCookies ? Colors.green : AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _ytHasCookies ? l10n.get('yt_login_desc_ok') : l10n.get('yt_login_desc'),
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                if (_ytHasCookies) {
                                  // Logout
                                  await widget.youtubeCookieService?.clearCookies();
                                  setState(() => _ytHasCookies = false);
                                  widget.onSettingsChanged();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.get('yt_logged_out'))),
                                    );
                                  }
                                } else {
                                  // Login inside the app. The page provides its own
                                  // AppBar/back button, so the user can return here
                                  // without leaving a separate browser window.
                                  final result = await Navigator.push<YouTubeLoginResult>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const YouTubeLoginPage(),
                                    ),
                                  );
                                  if (result != null && result.cookies.isNotEmpty) {
                                    await widget.youtubeCookieService?.saveCookies(
                                      result.cookies,
                                      userAgent: result.userAgent,
                                    );
                                    setState(() => _ytHasCookies = true);
                                    widget.onSettingsChanged();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.get('yt_login_success'))),
                                      );
                                    }
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: _ytHasCookies ? Colors.red.withAlpha(30) : AppColors.accent.withAlpha(30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                _ytHasCookies ? l10n.get('yt_logout') : l10n.get('yt_login_btn'),
                                style: TextStyle(
                                  color: _ytHasCookies ? Colors.red : AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // yt-dlp Engine Section (Desktop only)
                  if (!Platform.isAndroid && !Platform.isIOS) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_suggest_rounded,
                              size: 20,
                              color: _ytDlpInstalled ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.get('yt_dlp_status'),
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  if (_ytDlpDownloading)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: LinearProgressIndicator(
                                        value: _ytDlpProgress,
                                        backgroundColor: AppColors.surface,
                                        color: AppColors.accent,
                                        minHeight: 2,
                                      ),
                                    )
                                  else
                                    Text(
                                      _ytDlpInstalled ? l10n.get('yt_dlp_installed') : l10n.get('yt_dlp_not_installed'),
                                      style: TextStyle(
                                        color: _ytDlpInstalled ? Colors.green.withAlpha(180) : Colors.orange.withAlpha(180),
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _ytDlpDownloading ? null : _downloadYtDlp,
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.accent.withAlpha(30),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              ),
                              child: Text(
                                _ytDlpDownloading ? l10n.get('yt_dlp_downloading') : (_ytDlpInstalled ? l10n.get('update') : l10n.get('yt_dlp_download')),
                                style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
                
                const Divider(color: AppColors.surfaceBorder, height: 24),
                
                // Working Directory
                Text(
                  l10n.get('working_dir'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    try {
                      String? selectedDirectory = await FilePicker.getDirectoryPath();
                      if (selectedDirectory != null) {
                        setState(() => _workingDirectory = selectedDirectory);
                        await widget.settings.setWorkingDirectory(selectedDirectory);
                        widget.onSettingsChanged();
                      }
                    } catch (e) {
                      debugPrint('FilePicker error: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.accentLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _workingDirectory ?? l10n.get('select_dir'),
                            style: TextStyle(
                              color: _workingDirectory != null ? AppColors.textPrimary : AppColors.textMuted,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Сброс ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.surfaceBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.resetAll, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tokenStoredLocally,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
