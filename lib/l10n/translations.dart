import 'package:flutter/material.dart';

class Translations {
  final Locale locale;
  Translations(this.locale);

  static Translations of(BuildContext context) {
    return Localizations.of<Translations>(context, Translations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'AI Mind',
      'new_chat': 'New Chat',
      'history': 'History',
      'settings': 'Settings',
      'api_token': 'API Token',
      'balance': 'Balance',
      'model': 'Model',
      'parameters': 'Parameters',
      'temperature': 'Temperature',
      'top_p': 'Top P',
      'max_tokens': 'Max Tokens',
      'streaming': 'Streaming Responses',
      'streaming_desc': 'Show response as it is generated',
      'reset_all': 'Reset All',
      'token_stored_locally': 'Token is stored only on your device',
      'select_language': 'Select Language',
      'start_chat': 'Start Chat',
      'system_prompt': 'System Prompt',
      'first_message': 'First Message',
      'nsfw_mode': 'NSFW Mode',
      'cancel': 'Cancel',
      'create': 'Create',
      'delete_chat_title': 'Delete Chat?',
      'delete_chat_desc': 'Are you sure you want to delete chat "{title}"? This action cannot be undone.',
      'delete': 'Delete',
      'empty_chats': 'No chats',
      'start_dialog': 'Start a dialog',
      'ask_anything': 'Ask any question',
      'edit_response': 'Edit response',
      'save': 'Save',
      'regenerate': 'Regenerate',
      'message_hint': 'Message...',
      'language_priority': 'Priority Language',
      'auto': 'Auto',
      'edit_response_short': 'Edit',
      'reset': 'Reset',
      'update': 'Update',
      'loading': 'Loading...',
      'select_model': 'Select model',
      'first_msg_default': 'Hello! I am AI Mind. How can I help you?',
      'new_chat_dialog_title': 'New Chat',
      'system_prompt_hint': 'e.g. You are a helpful assistant...',
      'first_msg_hint': 'Leave empty for default',
      'nsfw_on': 'NSFW On',
      'safe_mode': 'Safe Mode',
      'app_language': 'App Language',
      'api_token_error': 'Add API token in settings',
      'error': 'Error',
      'thought': 'Thought',
      'search_model': 'Search model...',
      'reasoning': 'Reasoning',
      'reasoning_effort': 'Reasoning Effort',
      'reasoning_summary': 'Reasoning Summary',
      'reasoning_warning': 'Not all models support reasoning parameters. Use them with compatible models.',
      'none': 'None',
      'minimal': 'Minimal',
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'xhigh': 'Extreme High',
      'max': 'Max',
      'concise': 'Concise',
      'detailed': 'Detailed',
      'all_models': 'All',
      'free_models': 'Free',
      'paid_models': 'Paid',
      'reasoning_models': 'Reasoning',
      'no_reasoning_models': 'No Reasoning',
      'error_429_title': 'Model is Overloaded',
      'error_429_desc': 'Free models are often under high load and may return errors. Try a different model or switch to a paid one for stable access.',
      'got_it': 'Got it',
    },
    'ru': {
      'app_title': 'AI Mind',
      'new_chat': 'Новый чат',
      'history': 'История',
      'settings': 'Настройки',
      'api_token': 'API токен',
      'balance': 'Баланс',
      'model': 'Модель',
      'parameters': 'Параметры',
      'temperature': 'Температура',
      'top_p': 'Top P',
      'max_tokens': 'Макс. токенов',
      'streaming': 'Потоковые ответы',
      'streaming_desc': 'Показывать ответ по мере генерации',
      'reset_all': 'Сбросить всё',
      'token_stored_locally': 'Токен хранится только на устройстве',
      'select_language': 'Выберите язык',
      'start_chat': 'Начать чат',
      'system_prompt': 'System Prompt (инструкции)',
      'first_message': 'Первое сообщение от ИИ',
      'nsfw_mode': 'Режим 18+',
      'cancel': 'Отмена',
      'create': 'Создать',
      'delete_chat_title': 'Удалить чат?',
      'delete_chat_desc': 'Вы уверены, что хотите удалить чат "{title}"? Это действие нельзя отменить.',
      'delete': 'Удалить',
      'empty_chats': 'Нет чатов',
      'start_dialog': 'Начните диалог',
      'ask_anything': 'Задайте любой вопрос',
      'edit_response': 'Редактировать ответ',
      'save': 'Сохранить',
      'regenerate': 'Ещё раз',
      'message_hint': 'Сообщение…',
      'language_priority': 'Приоритетный язык',
      'auto': 'Авто',
      'edit_response_short': 'Изм.',
      'reset': 'Сбросить',
      'update': 'Обновить',
      'loading': 'Загрузка...',
      'select_model': 'Выберите модель',
      'first_msg_default': 'Привет! Я AI Mind. Задайте вопрос — постараюсь помочь.',
      'new_chat_dialog_title': 'Новый чат',
      'system_prompt_hint': 'Напр: Ты эксперт в Dart...',
      'first_msg_hint': 'Оставьте пустым для стандарта',
      'nsfw_on': 'NSFW включен',
      'safe_mode': 'Безопасный режим',
      'app_language': 'Язык приложения',
      'api_token_error': 'Добавьте API-токен в настройках',
      'error': 'Ошибка',
      'thought': 'Мысли',
      'search_model': 'Поиск модели...',
      'reasoning': 'Размышления',
      'reasoning_effort': 'Уровень усилий (Effort)',
      'reasoning_summary': 'Сводка (Summary)',
      'reasoning_warning': 'Не все модели поддерживают параметры размышления. Используйте их с совместимыми моделями.',
      'none': 'Нет',
      'minimal': 'Минимально',
      'low': 'Низко',
      'medium': 'Средне',
      'high': 'Высоко',
      'xhigh': 'Очень высоко',
      'max': 'Максимум',
      'concise': 'Кратко',
      'detailed': 'Детально',
      'all_models': 'Все',
      'free_models': 'Бесплатные',
      'paid_models': 'Платные',
      'reasoning_models': 'Думающие',
      'no_reasoning_models': 'Без мыслей',
      'error_429_title': 'Модель перегружена',
      'error_429_desc': 'Бесплатные модели часто перегружены и могут выдавать ошибки. Попробуйте другую модель или перейдите на платные для стабильной работы.',
      'got_it': 'Понятно',
    },
  };

  String get(String key) => _localizedValues[locale.languageCode]?[key] ?? key;

  String get appTitle => get('app_title');
  String get newChat => get('new_chat');
  String get history => get('history');
  String get settings => get('settings');
  String get apiToken => get('api_token');
  String get balance => get('balance');
  String get model => get('model');
  String get parameters => get('parameters');
  String get temperature => get('temperature');
  String get topP => get('top_p');
  String get maxTokens => get('max_tokens');
  String get streaming => get('streaming');
  String get streamingDesc => get('streaming_desc');
  String get resetAll => get('reset_all');
  String get tokenStoredLocally => get('token_stored_locally');
  String get selectLanguage => get('select_language');
  String get startChat => get('start_chat');
  String get systemPrompt => get('system_prompt');
  String get firstMessage => get('first_message');
  String get nsfwMode => get('nsfw_mode');
  String get cancel => get('cancel');
  String get create => get('create');
  String get deleteChatTitle => get('delete_chat_title');
  String deleteChatDesc(String title) => get('delete_chat_desc').replaceAll('{title}', title);
  String get delete => get('delete');
  String get emptyChats => get('empty_chats');
  String get startDialog => get('start_dialog');
  String get askAnything => get('ask_anything');
  String get editResponse => get('edit_response');
  String get save => get('save');
  String get regenerate => get('regenerate');
  String get messageHint => get('message_hint');
  String get languagePriority => get('language_priority');
  String get auto => get('auto');
  String get editResponseShort => get('edit_response_short');
  String get thought => get('thought');
  String get reasoning => get('reasoning');
  String get reasoningEffort => get('reasoning_effort');
  String get reasoningSummary => get('reasoning_summary');
  String get reasoningWarning => get('reasoning_warning');
}

class TranslationsDelegate extends LocalizationsDelegate<Translations> {
  const TranslationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<Translations> load(Locale locale) async => Translations(locale);

  @override
  bool shouldReload(TranslationsDelegate old) => false;
}
