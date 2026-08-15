import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:extractor/extractor.dart' as android_extractor;
import '../../utils/logger.dart';
import '../yt_dlp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings_service.dart';

import '../database/database_helper.dart';
import '../database/download_model.dart';
import '../youtube_cookie_service.dart';
import 'videoinfo.dart';
Future<Map<String, dynamic>> downloadYoutubeVideo(
    Map<String, dynamic> args,
    String? callId,
    Function(double, String, String)? onProgress,
    ) async {
  final url = args['url'] as String? ?? '';
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);
  final ytDlp = YtDlpService();
  final service = YouTubeCookieService(prefs);
  String? youtubeCookies = service.cookieHeader;
  String? youtubeUserAgent = service.userAgent;
  String? workDir = settings.workingDirectory;
  if (workDir == null || workDir.isEmpty) {
    final temp = await getTemporaryDirectory();
    workDir = '${temp.path}/ai_mind_downloads';
  }
  await Directory(workDir).create(recursive: true);

  final task = DownloadTask(
      callId: callId!,
      url: url,
      status: 'starting',
      progress: 0.0,
      timestamp: DateTime.now().millisecondsSinceEpoch);

  await DownloadDatabase.instance.insertOrUpdate(task);

  // 1. Try yt-dlp for Desktop
  if (Platform.isWindows || Platform.isLinux) {
    if (await ytDlp.isInstalled()) {
      AppLogger.log('Using yt-dlp for download: $url', tag: 'ToolService');

      unawaited(ytDlp.downloadVideo(
        url,
        workDir,
        cookieHeader: youtubeCookies,
        userAgent: youtubeUserAgent,
        onLog: (log) => AppLogger.log(log, tag: 'yt-dlp'),
        onProgress: (p, speed, eta) {
          if (callId != null) {
            DownloadDatabase.instance.updateProgress(
                callId,
                p,
                speed: speed,
                eta: eta
            );
          }
          onProgress?.call(p, speed, eta);
        },
        onFinished: (actualPath) {
            DownloadDatabase.instance.markCompleted(callId, actualPath);
        },
      ).catchError((e) {
          DownloadDatabase.instance.markError(callId, e.toString());
      }));

      return {
        'success': true,
        'message': 'Download started in background. Files saved in: $workDir. Track status via call_id: $callId',
        'call_id': callId,
        'target_directory': workDir,
      };
    }
  }

  // 2. Try Android-specific extractor
  if (Platform.isAndroid) {
    try {
      AppLogger.log('Using Android extractor plugin for download: $url', tag: 'ToolService');
      await ensureAndroidInitialized();

      // 1. Get info first to know the title and sanitize it
      final info = await android_extractor.YoutubeDLFlutter.instance.getVideoInfo(url);
      final safeTitle = (info.title ?? 'video')
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');
      final vid = info.id;
      final finalFileName = '${safeTitle}_$vid.mp4';
      final finalPath = '$workDir/$finalFileName';

      final hasCookies = youtubeCookies != null && youtubeCookies!.isNotEmpty;

      final Map<String, String> customOptions = {
        '--extractor-args': 'youtube:player-client=mweb',
        '--format': 'bestvideo+bestaudio/best',
        '--ignore-config': '',
        '--no-check-certificate': '',
      };

      File? cookieFile;
      if (hasCookies) {
        cookieFile = await ytDlp.createTempCookieFileForAndroid(youtubeCookies!);
        customOptions['--cookies'] = cookieFile.path;
      }

      customOptions['--user-agent'] = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';

      final request = android_extractor.DownloadRequest(
        url: url,
        outputPath: workDir,
        outputTemplate: finalFileName,
        customOptions: customOptions,
      );

      // Setup listeners for progress
      final progressSub = android_extractor.YoutubeDLFlutter.instance.onProgress.listen((p) {
        DownloadDatabase.instance.updateProgress(callId, p.progress / 100.0, eta: '${p.etaInSeconds}s');

        onProgress?.call(p.progress / 100.0, 'N/A', '${p.etaInSeconds}s');
      });

      final downloadFuture = android_extractor.YoutubeDLFlutter.instance.download(request).then((result) async {
        progressSub.cancel();
        if (cookieFile != null && await cookieFile.exists()) {
          await cookieFile.delete();
        }

        if (result.status == android_extractor.OperationStatus.success) {
            DownloadDatabase.instance.markCompleted(callId, finalPath);

        } else {
            DownloadDatabase.instance.markError(callId, result.errorMessage);

        }
      });

      unawaited(downloadFuture);

      return {
        'success': true,
        'message': 'Download started on Android. Track status via call_id: $callId',
        'call_id': callId,
      };
    } catch (e) {
      return {'error': 'Android download failed: $e'};
    }
  }

  return {'error': 'Download not supported on this platform or engine not installed.'};
}

Future<Map<String, dynamic>> checkDownloadStatus(Map<String, dynamic> args) async {
  final callId = args['call_id'] as String? ?? '';
  if (callId.isEmpty) return {'error': 'call_id is required.'};

  final task = await DownloadDatabase.instance.getDownload(callId);
  if (task == null) return {'error': 'No active download found for this call_id.'};

  return {'success': true, ...task.toMap()};
}