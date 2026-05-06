import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'dart:io';

class Database {
  final String path;
  late final sqlite.Database _db;

  Database(this.path);

  Future<void> init() async {
    // Ensure parent directory exists
    final file = File(path);
    await file.parent.create(recursive: true);

    _db = sqlite.sqlite3.open(path);

    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        phone TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        nickname TEXT NOT NULL DEFAULT '',
        config TEXT NOT NULL DEFAULT '{}',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS work_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT DEFAULT '',
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        notes TEXT DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    _db.execute('CREATE INDEX IF NOT EXISTS idx_work_logs_user ON work_logs(user_id)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_work_logs_updated ON work_logs(updated_at)');
    _db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_work_logs_client ON work_logs(user_id, client_id)');
  }

  // ─── User CRUD ───

  Map<String, dynamic>? getUserByPhone(String phone) {
    final result = _db.select('SELECT * FROM users WHERE phone = ?', [phone]);
    if (result.isEmpty) return null;
    return Map<String, dynamic>.from(result.first);
  }

  Map<String, dynamic>? getUserById(String id) {
    final result = _db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return Map<String, dynamic>.from(result.first);
  }

  void insertUser(Map<String, dynamic> user) {
    _db.execute(
      'INSERT INTO users (id, phone, password_hash, nickname, config, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [user['id'], user['phone'], user['password_hash'], user['nickname'], user['config'], user['created_at'], user['updated_at']],
    );
  }

  void updateUser(Map<String, dynamic> user) {
    _db.execute(
      'UPDATE users SET nickname = ?, config = ?, updated_at = ? WHERE id = ?',
      [user['nickname'], user['config'], user['updated_at'], user['id']],
    );
  }

  String? getUserSettings(String userId) {
    final result = _db.select('SELECT config FROM users WHERE id = ?', [userId]);
    if (result.isEmpty) return null;
    return result.first['config'] as String?;
  }

  void updateUserSettings(String userId, String config) {
    _db.execute(
      'UPDATE users SET config = ?, updated_at = ? WHERE id = ?',
      [config, DateTime.now().millisecondsSinceEpoch, userId],
    );
  }

  // ─── Work Log CRUD ───

  void insertWorkLog(Map<String, dynamic> log) {
    _db.execute(
      'INSERT INTO work_logs (id, user_id, client_id, title, category, start_time, end_time, duration, status, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [log['id'], log['user_id'], log['client_id'], log['title'], log['category'], log['start_time'], log['end_time'], log['duration'], log['status'], log['notes'], log['created_at'], log['updated_at']],
    );
  }

  void updateWorkLog(Map<String, dynamic> log) {
    _db.execute(
      'UPDATE work_logs SET title = ?, category = ?, start_time = ?, end_time = ?, duration = ?, status = ?, notes = ?, updated_at = ? WHERE id = ? AND user_id = ?',
      [log['title'], log['category'], log['start_time'], log['end_time'], log['duration'], log['status'], log['notes'], log['updated_at'], log['id'], log['user_id']],
    );
  }

  void deleteWorkLog(String id, String userId) {
    _db.execute('DELETE FROM work_logs WHERE id = ? AND user_id = ?', [id, userId]);
  }

  List<Map<String, dynamic>> getWorkLogsSince(String userId, int sinceMs) {
    final result = _db.select(
      'SELECT * FROM work_logs WHERE user_id = ? AND updated_at > ? ORDER BY updated_at ASC',
      [userId, sinceMs],
    );
    return result.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  List<Map<String, dynamic>> getWorkLogsByClientIds(String userId, List<String> clientIds) {
    if (clientIds.isEmpty) return [];
    final placeholders = clientIds.map((_) => '?').join(',');
    final params = [userId, ...clientIds];
    final result = _db.select(
      'SELECT client_id FROM work_logs WHERE user_id = ? AND client_id IN ($placeholders)',
      params,
    );
    return result.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  void dispose() {
    _db.dispose();
  }
}
