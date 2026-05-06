import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Extracts and verifies JWT from Authorization header.
/// On success, adds `userId` to request context.
Middleware authMiddleware(String secret) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Skip OPTIONS (CORS preflight)
      if (request.method == 'OPTIONS') {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          jsonEncode({'ok': false, 'error': 'Missing or invalid token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(secret));
        final userId = jwt.payload['userId'] as String;
        final requestWithUserId = request.change(context: {'userId': userId});
        return innerHandler(requestWithUserId);
      } on JWTExpiredException {
        return Response.unauthorized(
          jsonEncode({'ok': false, 'error': 'Token expired'}),
          headers: {'Content-Type': 'application/json'},
        );
      } on JWTException {
        return Response.unauthorized(
          jsonEncode({'ok': false, 'error': 'Invalid token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}

/// Helper to get userId from request context.
String? getUserId(Request request) {
  return request.context['userId'] as String?;
}
