import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_android/flutter_inappwebview_android.dart';
import 'package:flutter_inappwebview_linux/flutter_inappwebview_linux.dart';
import 'package:flutter_inappwebview_windows/flutter_inappwebview_windows.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'l10n/translations.dart';
import 'pages/chat_page.dart';
import 'pages/language_selection_page.dart';
import 'pages/onboarding_page.dart';
import 'services/locale_service.dart';
import 'theme/app_colors.dart';

// Функция для установки переменных окружения на уровне системы (C level)
void _setEnv(String name, String value) {
  try {
    final libc = DynamicLibrary.open('libc.so.6');
    final setenv = libc.lookupFunction<
        Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        int Function(Pointer<Utf8>, Pointer<Utf8>, int)>('setenv');
    
    final namePtr = name.toNativeUtf8();
    final valuePtr = value.toNativeUtf8();
    setenv(namePtr, valuePtr, 1);
    malloc.free(namePtr);
    malloc.free(valuePtr);
  } catch (e) {
    print('Could not set env $name: $e');
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  MediaKit.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isAndroid) {
    AndroidInAppWebViewPlatform.registerWith();
  } else if (Platform.isWindows) {
    WindowsInAppWebViewPlatform.registerWith();
  } else if (Platform.isLinux) {
    // Эти переменные часто исправляют черный экран в WPE WebKit на Arch Linux + AMD
    _setEnv('WEBKIT_DISABLE_COMPOSITING_MODE', '1');
    _setEnv('WPE_FDO_VIDEODEC_NODMABUF', '1');
    _setEnv('WPE_BCM_DECLARE_RESOURCES', '0');

    LinuxInAppWebViewPlatform.registerWith();
  }

  final prefs = await SharedPreferences.getInstance();

  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0C0B10),
      ),
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(prefs),
      child: const AiMindApp(),
    ),
  );
}

class AiMindApp extends StatelessWidget {
  const AiMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Mind',
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: const [
        TranslationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        useMaterial3: true,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.5,
          ),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          labelLarge: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIconColor: AppColors.textMuted,
          suffixIconColor: AppColors.textMuted,
        ),
        dividerColor: AppColors.surfaceBorder,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          contentTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: localeProvider.isFirstRun
          ? const LanguageSelectionPage()
          : Stack(
              children: [
                const ChatPage(),
                if (!localeProvider.isTutorialComplete) const OnboardingPage(),
              ],
            ),
    );
  }
}
