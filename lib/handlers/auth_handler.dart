import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../models/models.dart';

Handler authHandler(Database db, String jwtSecret) {
  final uuid = Uuid();

  return (Request request) async {
    final path = request.url.path;
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

    if (path.endsWith('/register')) {
      return _register(db, jwtSecret, uuid, data);
    } else if (path.endsWith('/login')) {
      return _login(db, jwtSecret, data);
    }

    return Response.notFound(
      jsonEncode({'ok': false, 'error': 'Not found'}),
      headers: {'Content-Type': 'application/json'},
    );
  };
}

Response _register(Database db, String jwtSecret, Uuid uuid, Map<String, dynamic> data) {
  final phone = data['phone']?.toString().trim();
  final password = data['password']?.toString();
  final nickname = data['nickname']?.toString().trim() ?? '';

  if (phone == null || phone.isEmpty || password == null || password.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'ok': false, 'error': 'Phone and password required'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  if (password.length < 6) {
    return Response.badRequest(
      body: jsonEncode({'ok': false, 'error': 'Password must be at least 6 characters'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Check if phone already exists
  final existing = db.getUserByPhone(phone);
  if (existing != null) {
    return Response(409,
      body: jsonEncode({'ok': false, 'error': 'Phone already registered'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final userId = uuid.v4();
  final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

  final user = UserModel(
    id: userId,
    phone: phone,
    passwordHash: passwordHash,
    nickname: nickname,
    config: jsonEncode({
      'workStart': '09:00',
      'workEnd': '18:00',
      'breakDuration': 60,
      'sedentaryReminder': 0,
      'offWorkReminder': false,
    }),
    createdAt: now,
    updatedAt: now,
  );

  try {
    db.insertUser(user.toMap());
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'ok': false, 'error': 'Registration failed'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final token = JWT({'userId': userId, 'phone': phone}, issuer: 'worktime')
      .sign(SecretKey(jwtSecret), expiresIn: const Duration(days: 30));

  return Response.ok(
    jsonEncode({
      'ok': true,
      'token': token,
      'user': user.toPublicJson(),
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

Response _login(Database db, String jwtSecret, Map<String, dynamic> data) {
  final phone = data['phone']?.toString().trim();
  final password = data['password']?.toString();

  if (phone == null || password == null) {
    return Response.badRequest(
      body: jsonEncode({'ok': false, 'error': 'Phone and password required'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final userMap = db.getUserByPhone(phone);
  if (userMap == null) {
    return Response(401,
      body: jsonEncode({'ok': false, 'error': 'Invalid credentials'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final user = UserModel.fromMap(userMap);
  if (!BCrypt.checkpw(password, user.passwordHash)) {
    return Response(401,
      body: jsonEncode({'ok': false, 'error': 'Invalid credentials'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final token = JWT({'userId': user.id, 'phone': user.phone}, issuer: 'worktime')
      .sign(SecretKey(jwtSecret), expiresIn: const Duration(days: 30));

  return Response.ok(
    jsonEncode({
      'ok': true,
      'token': token,
      'user': user.toPublicJson(),
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
