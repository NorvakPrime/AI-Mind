import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/youtube_login_helper.dart';
import '../theme/app_colors.dart';
import '../utils/logger.dart';

class YouTubeLoginPage extends StatefulWidget {
  const YouTubeLoginPage({super.key});

  @override
  State<YouTubeLoginPage> createState() => _YouTubeLoginPageState();
}

class _YouTubeLoginPageState extends State<YouTubeLoginPage> {
  InAppWebViewController? _webViewController;
  bool _isFinalizing = false;
  bool _isLoading = true;

  String get _userAgent =>
      Platform.isAndroid ? youtubeAndroidUA : youtubeDesktopUA;

  Future<void> _checkCookies(WebUri? url) async {
    if (_isFinalizing) return;

    final urlStr = url?.toString() ?? '';
    if (!urlStr.contains('youtube.com') &&
        !urlStr.contains('accounts.google.com')) {
      return;
    }

    try {
      final cookieManager = CookieManager.instance();

      // 1. Извлекаем куки для YouTube и Google
      final ytCookies = await cookieManager
          .getCookies(url: WebUri('https://www.youtube.com'))
          .timeout(const Duration(seconds: 3));

      final googleCookies = await cookieManager
          .getCookies(url: WebUri('https://accounts.google.com'))
          .timeout(const Duration(seconds: 3));

      // Объединяем куки
      final allCookies = [...ytCookies, ...googleCookies];

      final hasLogin = youtubeLoginIndicators
          .any((name) => allCookies.any((c) => c.name == name));

      if (hasLogin) {
        _isFinalizing = true;
        AppLogger.log('Login detected. Capturing data...', tag: 'YouTubeLogin');

        final List<Map<String, String>> result = [];
        final Set<String> processedKeys = {}; // Чтобы избежать дубликатов

        // Куки, которые обязательно должны быть продублированы для .google.com
        const ssoCookieNames = {
          'SID', 'HSID', 'SSID', 'APISID', 'SAPISID',
          '__Secure-1PSID', '__Secure-3PSID',
          '__Secure-1PAPISID', '__Secure-3PAPISID',
          '__Secure-1PSIDTS', '__Secure-3PSIDTS',
          'SIDCC', '__Secure-1PSIDCC', '__Secure-3PSIDCC'
        };

        for (var c in allCookies) {
          String rawDomain = c.domain ?? '.youtube.com';

          // Корректируем домен: в Netscape формате доменные куки должны начинаться с точки
          String domain = rawDomain.startsWith('.') ? rawDomain : '.$rawDomain';

          String expiration = '0';
          if (c.expiresDate != null) {
            expiration = (c.expiresDate! ~/ 1000).toString();
          }

          final key = '$domain:${c.name}';
          if (processedKeys.contains(key)) continue;
          processedKeys.add(key);

          final isSubdomain = domain.startsWith('.');
          final cookieMap = <String, String>{
            'domain': domain,
            // Если домен начинается с точки или содержит точки внутри — это TRUE
            'includeSubdomains': isSubdomain ? 'TRUE' : 'FALSE',
            'path': c.path ?? '/',
            'secure': (c.isSecure ?? false) ? 'TRUE' : 'FALSE',
            'expiration': expiration,
            'name': c.name,
            'value': c.value ?? '',
          };

          result.add(cookieMap);

          // 2. Если это ключевая кука авторизации, дублируем ее для .google.com
          if (ssoCookieNames.contains(c.name) && !domain.contains('google.com')) {
            final googleKey = '.google.com:${c.name}';
            if (!processedKeys.contains(googleKey)) {
              processedKeys.add(googleKey);
              result.add({
                ...cookieMap,
                'domain': '.google.com',
              });
            }
          }
        }

        if (mounted) {
          Navigator.pop(
            context,
            YouTubeLoginResult(cookies: result, userAgent: _userAgent),
          );
        }
      }
    } catch (e) {
      AppLogger.log('Error checking cookies: $e', tag: 'YouTubeLogin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'YouTube Login',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 22),
          color: AppColors.textSecondary,
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(youtubeLoginUrl)),
        initialSettings: InAppWebViewSettings(
          userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36",
          javaScriptEnabled: true,
          domStorageEnabled: true,
          preferredContentMode: UserPreferredContentMode.MOBILE,
          // Keep the embedded platform view opaque. Transparent native
          // surfaces may be rendered black by Linux WebKit.
          transparentBackground: false,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onReceivedError: (controller, request, error) {
          AppLogger.log(
            'YouTube WebView error: ${error.description}',
            tag: 'YouTubeLogin',
          );
        },
        onLoadStart: (controller, url) {
          setState(() => _isLoading = true);
        },
        onLoadStop: (controller, url) async {
          setState(() => _isLoading = false);
          await _checkCookies(url);
        },
        onProgressChanged: (controller, progress) {
          if (progress == 100) {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }
}
