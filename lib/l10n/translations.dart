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
      'skip': 'Skip',
      'next': 'Next',
      'back': 'Back',
      'finish': 'Finish',
      'login': 'Login',
      'register': 'Register',
      'get_key': 'Get API Key',
      'onboarding_1_title': 'Step 1: Login or Register',
      'onboarding_1_desc': 'To start using AI Mind, you need an OpenRouter account. Register or log in to their website.',
      'onboarding_2_title': 'Step 2: Get your API Key',
      'onboarding_2_desc': 'Create a new API key in your account settings. This key is required for the application to communicate with AI models.',
      'onboarding_3_title': 'Step 3: Enter your Key',
      'onboarding_3_desc': 'Paste your API key below or enter it later in the application settings.',
      'enter_key_hint': 'Paste your sk-or-v1-... key here',
      'tools': 'Tools',
      'tools_desc': 'Enable AI capabilities to interact with external services.',
      'working_dir': 'Working Directory',
      'select_dir': 'Select Folder',
      'yt_tools': 'Tools Integration',
      'yt_tools_desc': 'Enable AI capabilities to interact with external services.',
      'tool_call': 'Tool Call',
      'tool_call_params': 'Parameters',
      'tool_call_result': 'Result',
      'tool_call_downloading': 'Downloading...',
      'tool_call_download_progress': 'Download progress',
      'tool_call_completed': 'Completed',
      'tool_call_error': 'Error',
      'tool_call_expand': 'Show details',
      'tool_call_collapse': 'Hide details',
      'tool_call_eta': 'ETA',
      'tool_call_running': 'Running',
      'youtube_enabled': 'YouTube',
      'youtube_desc': 'Allow AI to fetch video info and download videos from YouTube.',
      'yt_login': 'YouTube Login',
      'yt_login_desc': 'Sign in to avoid rate limits and bot detection.',
      'yt_login_desc_ok': 'Authenticated — fewer restrictions.',
      'yt_logged_in': 'Logged in to YouTube',
      'yt_login_btn': 'Sign In',
      'yt_logout': 'Sign Out',
      'yt_logged_out': 'YouTube account disconnected.',
      'yt_login_success': 'YouTube login successful!',
      'yt_dlp_status': 'yt-dlp Engine',
      'yt_dlp_installed': 'Installed',
      'yt_dlp_not_installed': 'Not Installed',
      'yt_dlp_download': 'Install Engine',
      'yt_dlp_downloading': 'Downloading...',
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
      'skip': 'Пропустить',
      'next': 'Далее',
      'back': 'Назад',
      'finish': 'Готово',
      'login': 'Войти',
      'register': 'Регистрация',
      'get_key': 'Получить ключ',
      'onboarding_1_title': 'Шаг 1: Вход или регистрация',
      'onboarding_1_desc': 'Для работы с AI Mind вам понадобится аккаунт OpenRouter. Зарегистрируйтесь или войдите в существующий профиль на сайте.',
      'onboarding_2_title': 'Шаг 2: Получение ключа',
      'onboarding_2_desc': 'Создайте новый API ключ в настройках вашего аккаунта. Он необходим для того, чтобы приложение могло общаться с нейросетями.',
      'onboarding_3_title': 'Шаг 3: Ввод ключа',
      'onboarding_3_desc': 'Вставьте ваш API ключ ниже или введите его позже в настройках приложения.',
      'enter_key_hint': 'Вставьте ваш ключ sk-or-v1-...',
      'tools': 'Инструменты (Tools)',
      'tools_desc': 'Возможности ИИ для работы с внешними сервисами.',
      'working_dir': 'Рабочая директория',
      'select_dir': 'Выбрать папку',
      'yt_tools': 'Интеграция инструментов',
      'yt_tools_desc': 'Возможности ИИ для работы с внешними сервисами.',
      'youtube_enabled': 'YouTube',
      'youtube_desc': 'Разрешить ИИ получать информацию и скачивать видео с YouTube.',
      'yt_login': 'Вход в YouTube',
      'yt_login_desc': 'Войдите, чтобы избежать ограничений и блокировок.',
      'yt_login_desc_ok': 'Авторизовано — меньше ограничений.',
      'yt_logged_in': 'Вы вошли в YouTube',
      'yt_login_btn': 'Войти',
      'yt_logout': 'Выйти',
      'yt_logged_out': 'Аккаунт YouTube отключён.',
      'yt_login_success': 'Вход в YouTube выполнен!',
      'yt_dlp_status': 'Движок yt-dlp',
      'yt_dlp_installed': 'Установлен',
      'yt_dlp_not_installed': 'Не установлен',
      'yt_dlp_download': 'Установить движок',
      'yt_dlp_downloading': 'Загрузка...',
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
  String get skip => get('skip');
  String get next => get('next');
  String get back => get('back');
  String get finish => get('finish');
  String get login => get('login');
  String get register => get('register');
  String get getKey => get('get_key');
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
