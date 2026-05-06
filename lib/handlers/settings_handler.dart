import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../database.dart';
import '../middleware/auth.dart';

Handler settingsHandler(Database db, String jwtSecret) {
  return (Request request) async {
    final userId = getUserId(request);
    if (userId == null) {
      return Response.unauthorized(
        jsonEncode({'ok': false, 'error': 'Unauthorized'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // GET /api/settings
    if (request.method == 'GET') {
      final config = db.getUserSettings(userId);
      if (config == null) {
        return Response.notFound(
          jsonEncode({'ok': false, 'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return Response.ok(
        jsonEncode({'ok': true, 'config': jsonDecode(config)}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // PUT /api/settings
    if (request.method == 'PUT') {
      final body = await request.readAsString();
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final configStr = jsonEncode(data);
        db.updateUserSettings(userId, configStr);
        return Response.ok(
          jsonEncode({'ok': true, 'config': data}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (_) {
        return Response.badRequest(
          body: jsonEncode({'ok': false, 'error': 'Invalid JSON'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    }

    return Response(405,
      body: jsonEncode({'ok': false, 'error': 'Method not allowed'}),
      headers: {'Content-Type': 'application/json'},
    );
  };
}
