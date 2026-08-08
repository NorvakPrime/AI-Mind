import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('🚀 $tagStr$message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $message');
      if (error != null) debugPrint('   Details: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static void request(String url, Map<String, dynamic> body) {
    if (kDebugMode) {
      debugPrint('📡 [API REQUEST] $url');
      debugPrint('   Body: $body');
    }
  }

  static void response(String url, String data) {
    if (kDebugMode) {
      debugPrint('📥 [API RESPONSE] $url');
      debugPrint('   Data: $data');
    }
  }
}
