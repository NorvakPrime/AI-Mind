import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:extractor/extractor.dart' as android_extractor;

import '../utils/logger.dart';
import 'yt_dlp_service.dart';

import 'youtube/videoinfo.dart';
import 'youtube/download.dart';

class ToolService {


  void configure({
    String? workingDirectory,
    bool youtubeEnabled = false,
    String? youtubeCookies,
    String? youtubeUserAgent,
  }) {}

  Future<Map<String, dynamic>> execute(
    String name, 
    Map<String, dynamic> args, {
    String? callId,
    Function(double, String, String)? onProgress,
  }) async {
    AppLogger.log('Tool call: $name args: $args', tag: 'ToolService');
    switch (name) {
      case 'get_youtube_video_info': return getYoutubeVideoInfo(args);
      case 'download_youtube_video': return downloadYoutubeVideo(args, callId, onProgress);
      case 'check_youtube_download_status': return checkDownloadStatus(args);
      case 'upload_media_to_chat': return _uploadMediaToChat(args);
      default: return {'error': 'Unknown tool: $name'};
    }
  }

  Future<Map<String, dynamic>> _uploadMediaToChat(Map<String, dynamic> args) async {
    String path = args['path'] as String? ?? '';
    final type = args['type'] as String? ?? 'image';
    
    if (path.isEmpty) return {'error': 'Path is empty'};
    
    // Check if file exists. If not, try to be smart and find it
    File file = File(path);
    if (!file.existsSync()) {
       AppLogger.log('File not found at $path, searching directory...', tag: 'ToolService');
       final dir = file.parent;
       if (dir.existsSync()) {
          final fileName = path.split('/').last.toLowerCase();
          // Try to find any file that matches or contains the name
          try {
            final files = dir.listSync();
            final bestMatch = files.whereType<File>().firstWhere(
              (f) => f.path.toLowerCase().contains(fileName.replaceAll('.mp4', '').split('_').first),
              orElse: () => file,
            );
            if (bestMatch.existsSync()) {
              file = bestMatch;
              path = bestMatch.path;
              AppLogger.log('Found match: $path', tag: 'ToolService');
            }
          } catch (_) {}
       }
    }

    if (!file.existsSync()) return {'error': 'File not found at $path. Make sure the path is correct and absolute.'};
    
    return {
      'success': true,
      'action': 'display_media',
      'media_path': path,
      'media_type': type,
    };
  }

  void dispose() {}
}

List<Map<String, dynamic>> buildAvailableTools({bool youtubeEnabled = false}) {
  final tools = <Map<String, dynamic>>[];
  
  tools.add({
    'type': 'function',
    'function': {
      'name': 'upload_media_to_chat',
      'description': 'Show an image or video directly in the chat interface.',
      'parameters': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string', 'description': 'Absolute path to the media file.'},
          'type': {'type': 'string', 'enum': ['image', 'video']},
        },
        'required': ['path', 'type'],
      },
    },
  });

  if (youtubeEnabled) {
    tools.addAll([
      {
        'type': 'function',
        'function': {
          'name': 'get_youtube_video_info',
          'description': 'Get comprehensive metadata of a YouTube video (title, description, views, likes, comments count).',
          'parameters': {
            'type': 'object',
            'properties': {'url': {'type': 'string'}},
            'required': ['url'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'download_youtube_video',
          'description': 'Start downloading a YouTube video in the background.',
          'parameters': {
            'type': 'object',
            'properties': {'url': {'type': 'string'}},
            'required': ['url'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'check_youtube_download_status',
          'description': 'Check the progress, speed, and status of a background download.',
          'parameters': {
            'type': 'object',
            'properties': {'call_id': {'type': 'string', 'description': 'The call_id returned by download_youtube_video.'}},
            'required': ['call_id'],
          },
        },
      },
    ]);
  }
  return tools;
}
