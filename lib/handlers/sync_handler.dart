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

    final lastSyncAt = data['lastSyncAt'] as int? ?? 0;

    // ─── Process work log changes ───
    final logChanges = data['changes'] as List<dynamic>? ?? [];
    int workLogApplied = 0;
    for (final change in logChanges) {
      final c = change as Map<String, dynamic>;
      final clientId = c['clientId']?.toString();
      if (clientId == null || clientId.isEmpty) continue;

      final existing = db.getWorkLogsByClientIds(userId, [clientId]);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (existing.isNotEmpty) {
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
      workLogApplied++;
    }

    // ─── Process todo changes ───
    final todoChanges = data['todoChanges'] as List<dynamic>? ?? [];
    int todoApplied = 0;
    for (final change in todoChanges) {
      final c = change as Map<String, dynamic>;
      final clientId = c['clientId']?.toString();
      if (clientId == null || clientId.isEmpty) continue;

      final existing = db.getTodosByClientIds(userId, [clientId]);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (existing.isNotEmpty) {
        db.updateTodo({
          'id': existing.first['id'],
          'user_id': userId,
          'title': c['title'] ?? '',
          'description': c['description'] ?? '',
          'priority': c['priority'] ?? 1,
          'status': c['status'] ?? 0,
          'due_date': c['dueDate'],
          'category': c['category'] ?? '',
          'linked_work_log_client_id': c['linkedWorkLogClientId']?.toString(),
          'parent_client_id': c['parentClientId']?.toString(),
          'recurring_rule': c['recurringRule'] ?? '',
          'sort_order': c['sortOrder'] ?? 0,
          'updated_at': now,
        });
      } else {
        db.insertTodo({
          'id': uuid.v4(),
          'user_id': userId,
          'client_id': clientId,
          'title': c['title'] ?? '',
          'description': c['description'] ?? '',
          'priority': c['priority'] ?? 1,
          'status': c['status'] ?? 0,
          'due_date': c['dueDate'],
          'category': c['category'] ?? '',
          'linked_work_log_client_id': c['linkedWorkLogClientId']?.toString(),
          'parent_client_id': c['parentClientId']?.toString(),
          'recurring_rule': c['recurringRule'] ?? '',
          'sort_order': c['sortOrder'] ?? 0,
          'created_at': now,
          'updated_at': now,
        });
      }
      todoApplied++;
    }

    // ─── Fetch remote changes ───
    final remoteWorkLogs = db.getWorkLogsSince(userId, lastSyncAt);
    final remoteTodos = db.getTodosSince(userId, lastSyncAt);
    final syncAt = DateTime.now().millisecondsSinceEpoch;

    return Response.ok(
      jsonEncode({
        'ok': true,
        'serverChanges': remoteWorkLogs.map((r) {
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
        'todoServerChanges': remoteTodos.map((t) {
          final todo = TodoModel(
            id: t['id'] as String,
            userId: t['user_id'] as String,
            clientId: t['client_id'] as String?,
            title: t['title'] as String? ?? '',
            description: t['description'] as String? ?? '',
            priority: t['priority'] as int? ?? 1,
            status: t['status'] as int? ?? 0,
            dueDate: t['due_date'] as int?,
            category: t['category'] as String? ?? '',
            linkedWorkLogClientId: t['linked_work_log_client_id'] as String?,
            parentClientId: t['parent_client_id'] as String?,
            recurringRule: t['recurring_rule'] as String? ?? '',
            sortOrder: t['sort_order'] as int? ?? 0,
            createdAt: t['created_at'] as int,
            updatedAt: t['updated_at'] as int,
          );
          return todo.toJson();
        }).toList(),
        'syncAt': syncAt,
        'appliedCount': workLogApplied,
        'todoAppliedCount': todoApplied,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  };
}
