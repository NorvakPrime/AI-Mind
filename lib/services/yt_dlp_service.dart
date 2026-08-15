import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../utils/logger.dart';
import 'youtube_cookie_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
class YtDlpService {
  static const _tag = 'YtDlpService';

  Future<String> get _executablePath async {
    final dir = await getApplicationSupportDirectory();
    final name = Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
    final localPath = p.join(dir.path, 'bin', name);
    
    if (File(localPath).existsSync()) {
      return localPath;
    }
    
    // Fallback to system yt-dlp
    return name;
  }

  Future<bool> isInstalled() async {
    try {
      final path = await _executablePath;
      final result = await Process.run(path, ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> downloadExecutable({Function(double)? onProgress}) async {
    final path = await _executablePath;
    final file = File(path);
    await file.parent.create(recursive: true);

    final url = Platform.isWindows
        ? 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
        : 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux';

    AppLogger.log('Downloading yt-dlp from $url', tag: _tag);

    final dio = Dio();
    try {
      final response = await dio.download(
          url,
          path,
          onReceiveProgress: (received, total) {
            if (total > 0 && onProgress != null) {
              onProgress(received / total);
            }
          });
    } catch (e) {
      AppLogger.log('yt-dlp no installed at $path', tag: _tag);
    }

    if (!Platform.isWindows) {
      // Make executable on Linux/macOS
      await Process.run('chmod', ['+x', path]);
    }

    AppLogger.log('yt-dlp installed at $path', tag: _tag);
  }

  Future<Map<String, dynamic>> getVideoInfo(String url) async {
    if (!await isInstalled()) {
      return {'error': 'yt-dlp is not installed. Please install it in settings.'};
    }
    final prefs = await SharedPreferences.getInstance();
    final service = YouTubeCookieService(prefs);
    String? cookieHeader = service.cookieHeader;
    String? userAgent = service.userAgent;
    final path = await _executablePath;
    final args = [
      '--dump-json',
      '--ignore-config',
      '--no-warnings',
      '--no-check-certificate',
      '--no-playlist',
      '--no-cache-dir',
      url,
    ];

    args.insertAll(args.length - 1, [
        '--extractor-args', 'youtube:player-client=ios,android',]);

    if (userAgent != null && userAgent.isNotEmpty) {
      args.addAll(['--user-agent', "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36"]);
    }

    File? cookieFile;
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      cookieFile = await createTempCookieFile(cookieHeader);
      args.addAll(['--cookies', cookieFile.path]);
    }

    try {
      final result = await Process.run(path, args);
      if (result.exitCode != 0) {
        return {'error': 'yt-dlp error: ${result.stderr}'};
      }
      return jsonDecode(result.stdout) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Execution failed: $e'};
    } finally {
      await cookieFile?.delete();
    }
  }

  Future<void> downloadVideo(
    String url, 
    String outputDir, {
    String? cookieHeader,
    String? userAgent,
    Function(String)? onLog,
    Function(double, String, String)? onProgress, // progress, speed, eta
    Function(String)? onFinished, // actual file path
  }) async {
    if (!await isInstalled()) {
      throw Exception('yt-dlp is not installed.');
    }

    final path = await _executablePath;
    final fileName = '%(title)s.%(ext)s';
    final fullPath = p.join(outputDir, fileName);

    final args = [
      '-o', fullPath,
      '--ignore-config',
      '--no-warnings',
      '--no-check-certificate',
      '--no-cache-dir',
      '--newline',
      '--progress',
      url,
    ];

    args.insertAll(args.length - 1, [
      '--extractor-args', 'youtube:player-client=mweb',]);
    if (userAgent != null && userAgent.isNotEmpty) {
      args.addAll(['--user-agent', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36']);
    }

    File? cookieFile;
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      cookieFile = await createTempCookieFile(cookieHeader);
      args.addAll(['--cookies', cookieFile.path]);
    }

    String? actualFilePath;
    try {
      final process = await Process.start(path, args);
      
      final progressRegex = RegExp(r'\[download\]\s+(\d+\.\d+)%\s+of\s+.*\s+at\s+(.*)\s+ETA\s+(.*)');
      final destRegex = RegExp(r'\[download\]\s+Destination:\s+(.*)');
      final alreadyRegex = RegExp(r'\[download\]\s+(.*)\s+has already been downloaded');

      process.stdout.transform(utf8.decoder).listen((data) {
        onLog?.call(data);
        
        // Try to capture actual file path
        final destMatch = destRegex.firstMatch(data);
        if (destMatch != null) {
          actualFilePath = destMatch.group(1)?.trim();
        }
        final alreadyMatch = alreadyRegex.firstMatch(data);
        if (alreadyMatch != null) {
          actualFilePath = alreadyMatch.group(1)?.trim();
        }

        final match = progressRegex.firstMatch(data);
        if (match != null) {
          final percent = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          final speed = match.group(2)?.trim() ?? 'unknown';
          final eta = match.group(3)?.trim() ?? 'unknown';
          onProgress?.call(percent / 100.0, speed, eta);
        }
      });
      
      process.stderr.transform(utf8.decoder).listen((data) {
        onLog?.call('Error: $data');
      });

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception('yt-dlp failed with exit code $exitCode');
      }
      
      if (actualFilePath != null) {
        onFinished?.call(actualFilePath!);
      }
    } finally {
      await cookieFile?.delete();
    }
  }

  /// Special helper for Android extractor plugin
  Future<File> createTempCookieFileForAndroid(String header) async {
    return createTempCookieFile(header);
  }
}
