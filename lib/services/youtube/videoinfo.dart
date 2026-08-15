import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:extractor/extractor.dart' as android_extractor;
import '../yt_dlp_service.dart';

import '../../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../youtube_cookie_service.dart';

Future<void> ensureAndroidInitialized() async {
  if (!Platform.isAndroid) return;
  try {
    final isReady = await android_extractor.YoutubeDLFlutter.instance.isInitialized();
    if (!isReady) {
      AppLogger.log('Initializing Android extractor engine...', tag: 'ToolService');
      final res = await android_extractor.YoutubeDLFlutter.instance.initialize(
        enableFFmpeg: true,
        enableAria2c: false,
      );

      if (res.success) {
        AppLogger.log('Engine initialized, attempting to update yt-dlp binary...', tag: 'ToolService');
        // Update yt-dlp to the latest version to handle new YouTube restrictions
        await android_extractor.YoutubeDLFlutter.instance.updateYoutubeDL();
      } else {
        // Retry without FFmpeg if failed
        final retryRes = await android_extractor.YoutubeDLFlutter.instance.initialize(
          enableFFmpeg: false,
          enableAria2c: false,
        );
        if (!retryRes.success) {
          throw Exception('Failed to initialize engine: ${retryRes.errorMessage}');
        }
      }
      AppLogger.log('Android extractor engine ready.', tag: 'ToolService');
    }
  } catch (e) {
    AppLogger.log('Android init error: $e', tag: 'ToolService');
    rethrow;
  }
}

Future<Map<String, dynamic>> getYoutubeVideoInfo(Map<String, dynamic> args) async {
  final url = args['url'] as String? ?? '';
  final ytDlp = YtDlpService();
  final prefs = await SharedPreferences.getInstance();
  final service = YouTubeCookieService(prefs);
  String? youtubeCookies = service.cookieHeader;
  String? youtubeUserAgent = service.userAgent;

  if (Platform.isAndroid) {
    return await getvideoinfo_android(
        ytDlp,
        youtubeCookies,
        youtubeUserAgent,
        url);
  }

  if (Platform.isLinux || Platform.isWindows) {
    return await getvideoinfo_desktop(
        ytDlp,
        youtubeCookies,
        youtubeUserAgent,
        url
    );
  }

  throw UnsupportedError('unsupported ${Platform.operatingSystem} platform');
}

Future<Map<String, dynamic>> getvideoinfo_android(YtDlpService ytDlp, String? youtubeCookies, String? youtubeUserAgent, String url) async {
  try {
    await ensureAndroidInitialized();

    final hasCookies = youtubeCookies != null;

    Map<String, String> options = {
      '--no-check-certificate': '',
      '--ignore-config': '',
      '--no-check-formats': '',
      '--ignore-no-formats-error': '',
      '--no-playlist': '',
      '--all-subs': '',
      '--write-auto-subs': '',
      '--extractor-args': 'youtube:player-client=mweb',
    };

    File? cookieFile;
    if (hasCookies) {
      cookieFile = await ytDlp.createTempCookieFileForAndroid(youtubeCookies!);
      options['--cookies'] = cookieFile.path;
    }

    if (youtubeUserAgent != null) {
      options['--user-agent'] = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
    }

    final info = await android_extractor.YoutubeDLFlutter.instance.getVideoInfoWithOptions(url, options);

    if (cookieFile != null && await cookieFile.exists()) {
  await cookieFile.delete();
  }

  return {
    'success': true,
    'id': info.id,
    'title': info.title ?? 'Unknown',
    'description': info.description,
    'view_count': info.viewCount,
    'like_count': info.likeCount,
    'thumbnail_url': info.thumbnail,
    'author': info.uploader ?? 'Unknown',
    };
    } catch (e) {
    AppLogger.log('Android extractor info failed: $e', tag: 'ToolService');
    return {'error': 'Android extractor failed: $e'};
    }
  }

Future<Map<String, dynamic>> getvideoinfo_desktop(YtDlpService ytDlp, String? youtubeCookies, String? youtubeUserAgent, String url) async {
  if (!await ytDlp.isInstalled()) {return {'error': 'yt-dlp is not installed or not in PATH.', 'success': false};}
  AppLogger.log('Using yt-dlp for info: $url', tag: 'ToolService');
  final info = await ytDlp.getVideoInfo(url);
  if (info.containsKey('error')) {
    AppLogger.log('yt-dlp info failed: ${info['error']}', tag: 'ToolService');
    return {'error': info['error'], 'success': false};
  } else {
    // Return only the specific basic information requested
    return {
      'success': true,
      'id': info['id'],
      'title': info['title'],
      'description': info['description'],
      'view_count': info['view_count'],
      'like_count': info['like_count'],
      'comment_count': info['comment_count'],
      'subscriber_count': info['channel_follower_count'] ?? info['subscriber_count'],
      'tags': info['tags'],
      'thumbnail_url': info['thumbnail'] ?? '',
      'channel': info['channel'] ?? info['uploader'],
    };
  }
}