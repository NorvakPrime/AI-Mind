import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'download_model.dart';

class DownloadDatabase {
  static final DownloadDatabase instance = DownloadDatabase._init();
  static Database? _database;

  DownloadDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('downloads.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE downloads (
        call_id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        status TEXT NOT NULL,
        progress REAL NOT NULL,
        speed TEXT,
        eta TEXT,
        file_path TEXT,
        error TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertOrUpdate(DownloadTask task) async {
    final db = await instance.database;
    await db.insert(
      'downloads',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DownloadTask?> getDownload(String callId) async {
    final db = await instance.database;
    final maps = await db.query(
      'downloads',
      where: 'call_id = ?',
      whereArgs: [callId],
    );

    if (maps.isNotEmpty) {
      return DownloadTask.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DownloadTask>> getAllDownloads() async {
    final db = await instance.database;
    final result = await db.query('downloads', orderBy: 'timestamp DESC');
    return result.map((json) => DownloadTask.fromMap(json)).toList();
  }

  Future<int> deleteDownload(String callId) async {
    final db = await instance.database;
    return await db.delete(
      'downloads',
      where: 'call_id = ?',
      whereArgs: [callId],
    );
  }

  Future<void> updateProgress(String callId, double progress, {String? speed, String? eta}) async {
    final db = await instance.database;
    await db.update(
      'downloads',
      {
        'progress': progress,
        if (speed != null) 'speed': speed,
        if (eta != null) 'eta': eta,
        'status': 'downloading',
      },
      where: 'call_id = ?',
      whereArgs: [callId],
    );
  }

  Future<void> markCompleted(String callId, String filePath) async {
    final db = await instance.database;
    await db.update(
      'downloads',
      {
        'status': 'completed',
        'progress': 1.0,
        'file_path': filePath,
      },
      where: 'call_id = ?',
      whereArgs: [callId],
    );
  }

  Future<void> markError(String callId, String? error) async {
    final db = await instance.database;
    await db.update(
      'downloads',
      {
        'status': 'error',
        'error': error,
      },
      where: 'call_id = ?',
      whereArgs: [callId],
    );
  }

  Future close() async {
    final db = await _database;
    if (db != null) await db.close();
  }
}
