import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:worktime_server/database.dart';
import 'package:worktime_server/router.dart' as app_router;

/// Simple .env file loader
Map<String, String> _loadDotEnv() {
  final env = <String, String>{};
  try {
    final file = File('.env');
    if (!file.existsSync()) return env;
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx < 0) continue;
      env[trimmed.substring(0, eqIdx).trim()] = trimmed.substring(eqIdx + 1).trim();
    }
  } catch (_) {}
  return env;
}

/// CORS headers for web client access
Map<String, String> _corsHeaders(String? allowedOrigin) {
  return {
    'Access-Control-Allow-Origin': allowedOrigin ?? '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

Future<void> main(List<String> args) async {
  final dotenv = _loadDotEnv();

  String envOr(String key, String fallback) =>
      Platform.environment[key] ?? dotenv[key] ?? fallback;

  final port = int.tryParse(envOr('PORT', '8080')) ?? 8080;
  final dbPath = envOr('DB_PATH', 'data.db');
  final jwtSecret = envOr('JWT_SECRET', 'change-me-in-production');
  final allowedOrigin = envOr('ALLOWED_ORIGIN', '*');

  // Init database
  final db = Database(dbPath);
  await db.init();

  // Build router
  final router = app_router.build(db, jwtSecret);

  // CORS middleware
  final corsHeaders = _corsHeaders(allowedOrigin == '*' ? null : allowedOrigin);
  final corsMiddleware = createMiddleware(
    requestHandler: (req) {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      return null;
    },
    responseHandler: (res) {
      return res.change(headers: {...res.headers, ...corsHeaders});
    },
  );

  // Logging middleware
  final logMiddleware = createMiddleware(
    requestHandler: (req) {
      print('[${DateTime.now().toIso8601String()}] ${req.method} ${req.url}');
      return null;
    },
  );

  final pipeline = Pipeline()
      .addMiddleware(logMiddleware)
      .addMiddleware(corsMiddleware)
      .addHandler(router);

  final server = await shelf_io.serve(pipeline, '0.0.0.0', port);
  print('Server running on http://0.0.0.0:${server.port}');
}
