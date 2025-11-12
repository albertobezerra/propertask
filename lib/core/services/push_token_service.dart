// lib/core/services/push_token_service.dart
import 'package:propertask/core/services/notifications_service.dart';

class PushTokenService {
  static Future<void> saveForUser(String uid) async {
    await NotificationsService.instance.saveCurrentToken(uid);
  }
}
