import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../middleware/auth.dart';

Handler todoHandler(Database db, String jwtSecret) {
  final uuid = Uuid();

  return (Request request) async {
    final userId = getUserId(request);
    if (userId == null) {
      return Response.unauthorized(
        jsonEncode({'ok': false, 'error': 'Unauthorized'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // GET /api/todos?since=timestamp
    if (request.method == 'GET') {
      final sinceStr = request.url.queryParameters['since'];
      final since = sinceStr != null ? int.tryParse(sinceStr) ?? 0 : 0;
      final todos = db.getTodosSince(userId, since);
      return Response.ok(
        jsonEncode({'ok': true, 'todos': todos.map((t) {
          return {
            'id': t['id'],
            'userId': t['user_id'],
            'clientId': t['client_id'],
            'title': t['title'],
            'description': t['description'],
            'priority': t['priority'],
            'status': t['status'],
            'dueDate': t['due_date'],
            'category': t['category'],
            'linkedWorkLogClientId': t['linked_work_log_client_id'],
            'parentClientId': t['parent_client_id'],
            'recurringRule': t['recurring_rule'],
            'sortOrder': t['sort_order'],
            'createdAt': t['created_at'],
            'updatedAt': t['updated_at'],
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

    // POST /api/todos
    if (request.method == 'POST') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final todoId = uuid.v4();
      final clientId = data['clientId']?.toString() ?? todoId;

      db.insertTodo({
        'id': todoId,
        'user_id': userId,
        'client_id': clientId,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'priority': data['priority'] ?? 1,
        'status': data['status'] ?? 0,
        'due_date': data['dueDate'],
        'category': data['category'] ?? '',
        'linked_work_log_client_id': data['linkedWorkLogClientId']?.toString(),
        'parent_client_id': data['parentClientId']?.toString(),
        'recurring_rule': data['recurringRule'] ?? '',
        'sort_order': data['sortOrder'] ?? 0,
        'created_at': now,
        'updated_at': now,
      });

      return Response.ok(
        jsonEncode({'ok': true, 'id': todoId, 'clientId': clientId}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // PUT /api/todos/:id
    if (request.method == 'PUT') {
      final todoId = request.url.pathSegments.last;
      final now = DateTime.now().millisecondsSinceEpoch;

      db.updateTodo({
        'id': todoId,
        'user_id': userId,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'priority': data['priority'] ?? 1,
        'status': data['status'] ?? 0,
        'due_date': data['dueDate'],
        'category': data['category'] ?? '',
        'linked_work_log_client_id': data['linkedWorkLogClientId']?.toString(),
        'parent_client_id': data['parentClientId']?.toString(),
        'recurring_rule': data['recurringRule'] ?? '',
        'sort_order': data['sortOrder'] ?? 0,
        'updated_at': now,
      });

      return Response.ok(
        jsonEncode({'ok': true, 'id': todoId}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // DELETE /api/todos/:id
    if (request.method == 'DELETE') {
      final todoId = request.url.pathSegments.last;
      db.deleteTodo(todoId, userId);
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
