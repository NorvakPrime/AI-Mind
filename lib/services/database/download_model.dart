class DownloadTask {
  final String callId;
  final String url;
  final String status;
  final double progress;
  final String? speed;
  final String? eta;
  final String? filePath;
  final String? error;
  final int timestamp;

  DownloadTask({
    required this.callId,
    required this.url,
    required this.status,
    required this.progress,
    this.speed,
    this.eta,
    this.filePath,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'call_id': callId,
      'url': url,
      'status': status,
      'progress': progress,
      'speed': speed,
      'eta': eta,
      'file_path': filePath,
      'error': error,
      'timestamp': timestamp,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      callId: map['call_id'] as String,
      url: map['url'] as String,
      status: map['status'] as String,
      progress: (map['progress'] as num).toDouble(),
      speed: map['speed'] as String?,
      eta: map['eta'] as String?,
      filePath: map['file_path'] as String?,
      error: map['error'] as String?,
      timestamp: map['timestamp'] as int,
    );
  }
}
