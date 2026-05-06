import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'database.dart';
import 'middleware/auth.dart';
import 'handlers/auth_handler.dart';
import 'handlers/worklog_handler.dart';
import 'handlers/sync_handler.dart';
import 'handlers/settings_handler.dart';

Router build(Database db, String jwtSecret) {
  final router = Router();

  // Auth routes (no JWT required)
  router.post('/api/auth/register', authHandler(db, jwtSecret));
  router.post('/api/auth/login', authHandler(db, jwtSecret));

  // Protected routes (JWT required)
  final auth = authMiddleware(jwtSecret);

  router.get('/api/worklogs', auth(worklogHandler(db, jwtSecret)));
  router.post('/api/worklogs', auth(worklogHandler(db, jwtSecret)));
  router.put('/api/worklogs/<id>', auth(worklogHandler(db, jwtSecret)));
  router.delete('/api/worklogs/<id>', auth(worklogHandler(db, jwtSecret)));

  router.post('/api/sync', auth(syncHandler(db, jwtSecret)));

  router.get('/api/settings', auth(settingsHandler(db, jwtSecret)));
  router.put('/api/settings', auth(settingsHandler(db, jwtSecret)));

  // Health check
  router.get('/api/health', (req) => Response.ok(
    '{"ok":true,"status":"running"}',
    headers: {'Content-Type': 'application/json'},
  ));

  return router;
}
