import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class AuthDebug {
  static void printCurrentUser(AuthService auth) {
    if (!kDebugMode) return;

    debugPrint('=================================');
    debugPrint('Firebase User');
    debugPrint('UID: ${auth.uid}');
    debugPrint('Signed In: ${auth.isSignedIn}');
    debugPrint('=================================');
  }
}
