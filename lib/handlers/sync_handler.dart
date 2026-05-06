import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../middleware/auth.dart';
import '../models/models.dart';

Handler syncHandler(Database db, String jwtSecret) {
  final uuid = Uuid();

  return (Request request) async {
    final userId = getUserId(request);
    if (userId == null) {
      return Response.unauthorized(
        jsonEncode({'ok': false, 'error': 'Unauthorized'}),
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

    final changes = data['changes'] as List<dynamic>? ?? [];
    final lastSyncAt = data['lastSyncAt'] as int? ?? 0;

    // Process client-side changes (upsert)
    int serverChangesCount = 0;
    for (final change in changes) {
      final c = change as Map<String, dynamic>;
      final clientId = c['clientId']?.toString();
      if (clientId == null || clientId.isEmpty) continue;

      // Check if this client_id already exists on server
      final existing = db.getWorkLogsByClientIds(userId, [clientId]);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (existing.isNotEmpty) {
        // Update existing record
        db.updateWorkLog({
          'id': existing.first['id'],
          'user_id': userId,
          'title': c['title'] ?? '',
          'category': c['category'] ?? '',
          'start_time': c['startTime'],
          'end_time': c['endTime'],
          'duration': c['duration'] ?? 0,
          'status': c['status'] ?? 0,
          'notes': c['notes'] ?? '',
          'updated_at': now,
        });
      } else {
        // Insert new record
        db.insertWorkLog({
          'id': uuid.v4(),
          'user_id': userId,
          'client_id': clientId,
          'title': c['title'] ?? '',
          'category': c['category'] ?? '',
          'start_time': c['startTime'] ?? now,
          'end_time': c['endTime'],
          'duration': c['duration'] ?? 0,
          'status': c['status'] ?? 0,
          'notes': c['notes'] ?? '',
          'created_at': now,
          'updated_at': now,
        });
      }
      serverChangesCount++;
    }

    // Fetch remote changes since lastSyncAt
    final remoteChanges = db.getWorkLogsSince(userId, lastSyncAt);
    final syncAt = DateTime.now().millisecondsSinceEpoch;

    return Response.ok(
      jsonEncode({
        'ok': true,
        'serverChanges': remoteChanges.map((r) {
        final wl = WorkLogModel(
          id: r['id'] as String,
          userId: r['user_id'] as String,
          clientId: r['client_id'] as String,
          title: r['title'] as String? ?? '',
          category: r['category'] as String? ?? '',
          startTime: r['start_time'] as int,
          endTime: r['end_time'] as int?,
          duration: r['duration'] as int? ?? 0,
          status: r['status'] as int? ?? 0,
          notes: r['notes'] as String? ?? '',
          createdAt: r['created_at'] as int,
          updatedAt: r['updated_at'] as int,
        );
        return wl.toJson();
      }).toList(),
        'syncAt': syncAt,
        'appliedCount': serverChangesCount,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  };
}
