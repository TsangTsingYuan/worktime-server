import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../middleware/auth.dart';

Handler worklogHandler(Database db, String jwtSecret) {
  final uuid = Uuid();

  return (Request request) async {
    final userId = getUserId(request);
    if (userId == null) {
      return Response.unauthorized(
        jsonEncode({'ok': false, 'error': 'Unauthorized'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // GET /api/worklogs?since=timestamp
    if (request.method == 'GET') {
      final sinceStr = request.url.queryParameters['since'];
      final since = sinceStr != null ? int.tryParse(sinceStr) ?? 0 : 0;
      final logs = db.getWorkLogsSince(userId, since);
      return Response.ok(
        jsonEncode({'ok': true, 'logs': logs.map((l) {
          return {
            'id': l['id'],
            'userId': l['user_id'],
            'clientId': l['client_id'],
            'title': l['title'],
            'category': l['category'],
            'startTime': l['start_time'],
            'endTime': l['end_time'],
            'duration': l['duration'],
            'status': l['status'],
            'notes': l['notes'],
            'createdAt': l['created_at'],
            'updatedAt': l['updated_at'],
          };
        }).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final body = await request.readAsString();
    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(
        body: jsonEncode({'ok': false, 'error': 'Invalid JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // POST /api/worklogs
    if (request.method == 'POST') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final logId = uuid.v4();
      final clientId = data['clientId']?.toString() ?? logId;

      db.insertWorkLog({
        'id': logId,
        'user_id': userId,
        'client_id': clientId,
        'title': data['title'] ?? '',
        'category': data['category'] ?? '',
        'start_time': data['startTime'] ?? now,
        'end_time': data['endTime'],
        'duration': data['duration'] ?? 0,
        'status': data['status'] ?? 0,
        'notes': data['notes'] ?? '',
        'created_at': now,
        'updated_at': now,
      });

      return Response.ok(
        jsonEncode({'ok': true, 'id': logId, 'clientId': clientId}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // PUT /api/worklogs/:id
    if (request.method == 'PUT') {
      final logId = request.url.pathSegments.last;
      final now = DateTime.now().millisecondsSinceEpoch;

      db.updateWorkLog({
        'id': logId,
        'user_id': userId,
        'title': data['title'] ?? '',
        'category': data['category'] ?? '',
        'start_time': data['startTime'],
        'end_time': data['endTime'],
        'duration': data['duration'] ?? 0,
        'status': data['status'] ?? 0,
        'notes': data['notes'] ?? '',
        'updated_at': now,
      });

      return Response.ok(
        jsonEncode({'ok': true, 'id': logId}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // DELETE /api/worklogs/:id
    if (request.method == 'DELETE') {
      final logId = request.url.pathSegments.last;
      db.deleteWorkLog(logId, userId);
      return Response.ok(
        jsonEncode({'ok': true}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response(405,
      body: jsonEncode({'ok': false, 'error': 'Method not allowed'}),
      headers: {'Content-Type': 'application/json'},
    );
  };
}
