import 'dart:io';

const youtubeLoginUrl =
    'https://accounts.google.com/ServiceLogin?service=youtube&continue=https://www.youtube.com/';
const youtubeLoginIndicators = ['SID', 'SSID', 'HSID', 'LOGIN_INFO'];

const youtubeAndroidUA =
    'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';

const youtubeDesktopUA =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

class YouTubeLoginResult {
  final List<Map<String, String>> cookies;
  final String userAgent;
  YouTubeLoginResult({required this.cookies, required this.userAgent});
}

bool get isYouTubeLoginSupported =>
    Platform.isAndroid || Platform.isWindows || Platform.isLinux;